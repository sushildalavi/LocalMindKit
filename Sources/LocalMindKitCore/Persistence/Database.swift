import Foundation

/// The single source of truth for the index: file metadata, text chunks,
/// and the FTS5 keyword index. Embeddings live alongside (V1) but are
/// stubbed here for the MVP keyword path.
///
/// An actor so all SQLite access is serialized without manual locking —
/// the indexing pipeline writes from many tasks concurrently.
public actor Database {
    private let conn: SQLiteConnection

    /// - Parameter path: file path, or ":memory:" for tests.
    public init(path: String) throws {
        self.conn = try SQLiteConnection(path: path)
        try Self.migrate(conn: conn)
    }

    // MARK: - Schema

    private static func migrate(conn: SQLiteConnection) throws {
        try conn.exec("""
        CREATE TABLE IF NOT EXISTS files (
            id           INTEGER PRIMARY KEY,
            external_id  TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            file_type    TEXT NOT NULL,
            size_bytes   INTEGER NOT NULL,
            content_hash TEXT NOT NULL,
            created_at   REAL,
            modified_at  REAL,
            indexed_at   REAL,
            status       TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_files_hash ON files(content_hash);

        CREATE TABLE IF NOT EXISTS chunks (
            id         INTEGER PRIMARY KEY,
            file_id    INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
            ordinal    INTEGER NOT NULL,
            text       TEXT NOT NULL,
            char_start INTEGER NOT NULL,
            char_end   INTEGER NOT NULL,
            source     TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_chunks_file ON chunks(file_id);

        -- FTS5 keyword index over chunk text. External-content table so we
        -- don't duplicate the text; porter stemming + unicode tokenizer.
        CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
            text,
            content='chunks',
            content_rowid='id',
            tokenize='porter unicode61'
        );

        -- Keep the FTS index in sync with the chunks table.
        CREATE TRIGGER IF NOT EXISTS chunks_ai AFTER INSERT ON chunks BEGIN
            INSERT INTO chunks_fts(rowid, text) VALUES (new.id, new.text);
        END;
        CREATE TRIGGER IF NOT EXISTS chunks_ad AFTER DELETE ON chunks BEGIN
            INSERT INTO chunks_fts(chunks_fts, rowid, text) VALUES ('delete', old.id, old.text);
        END;
        CREATE TRIGGER IF NOT EXISTS chunks_au AFTER UPDATE ON chunks BEGIN
            INSERT INTO chunks_fts(chunks_fts, rowid, text) VALUES ('delete', old.id, old.text);
            INSERT INTO chunks_fts(rowid, text) VALUES (new.id, new.text);
        END;
        """)
    }

    // MARK: - Incremental indexing support

    /// Returns the stored content hash for an externalID, if present.
    /// Lets the coordinator skip unchanged files cheaply.
    public func existingHash(externalID: String) throws -> String? {
        var result: String?
        try conn.query(
            "SELECT content_hash FROM files WHERE external_id = ?;",
            params: [.text(externalID)]
        ) { row in result = row.string(0) }
        return result
    }

    /// Insert or replace a file's metadata, removing any stale chunks first
    /// so a re-index of changed content doesn't leave orphans.
    @discardableResult
    public func upsertFile(_ file: IndexedFile) throws -> Int64 {
        // Remove prior version (cascades to chunks + FTS via triggers).
        try conn.run("DELETE FROM files WHERE external_id = ?;", params: [.text(file.externalID)])
        let id = try conn.run("""
            INSERT INTO files
              (external_id, display_name, file_type, size_bytes, content_hash,
               created_at, modified_at, indexed_at, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            params: [
                .text(file.externalID),
                .text(file.displayName),
                .text(file.fileType.rawValue),
                .int(file.sizeBytes),
                .text(file.contentHash),
                file.createdAt.map { .double($0.timeIntervalSince1970) } ?? .null,
                file.modifiedAt.map { .double($0.timeIntervalSince1970) } ?? .null,
                .double((file.indexedAt ?? Date()).timeIntervalSince1970),
                .text(file.status.rawValue),
            ]
        )
        return id
    }

    public func insertChunks(_ chunks: [Chunk]) throws {
        try conn.exec("BEGIN;")
        do {
            for c in chunks {
                try conn.run("""
                    INSERT INTO chunks (file_id, ordinal, text, char_start, char_end, source)
                    VALUES (?, ?, ?, ?, ?, ?);
                    """,
                    params: [
                        .int(c.fileID),
                        .int(Int64(c.ordinal)),
                        .text(c.text),
                        .int(Int64(c.charStart)),
                        .int(Int64(c.charEnd)),
                        .text(c.source.rawValue),
                    ]
                )
            }
            try conn.exec("COMMIT;")
        } catch {
            try? conn.exec("ROLLBACK;")
            throw error
        }
    }

    // MARK: - Privacy operations

    /// Remove a single file and its chunks from the index.
    public func deleteFile(externalID: String) throws {
        try conn.run("DELETE FROM files WHERE external_id = ?;", params: [.text(externalID)])
    }

    /// Nuke the entire index. Backs the "Delete index" privacy control.
    public func deleteAll() throws {
        try conn.exec("DELETE FROM chunks;")
        try conn.exec("DELETE FROM files;")
        try conn.exec("INSERT INTO chunks_fts(chunks_fts) VALUES('delete-all');")
    }

    public func fileCount() throws -> Int {
        var n = 0
        try conn.query("SELECT COUNT(*) FROM files;") { row in n = Int(row.int(0)) }
        return n
    }

    public func chunkCount() throws -> Int {
        var n = 0
        try conn.query("SELECT COUNT(*) FROM chunks;") { row in n = Int(row.int(0)) }
        return n
    }

    // MARK: - Keyword search (FTS5)

    /// Run an FTS5 MATCH query, returning ranked hits with highlighted snippets.
    /// `bm25()` returns a cost (lower is better); we negate so higher = better.
    func keywordSearch(matchQuery: String, limit: Int) throws -> [KeywordHit] {
        var hits: [KeywordHit] = []
        try conn.query("""
            SELECT
                c.id, c.file_id,
                f.external_id, f.display_name, f.file_type, f.modified_at,
                bm25(chunks_fts) AS rank,
                snippet(chunks_fts, 0, '[', ']', '…', 12) AS snip
            FROM chunks_fts
            JOIN chunks c ON c.id = chunks_fts.rowid
            JOIN files  f ON f.id = c.file_id
            WHERE chunks_fts MATCH ?
            ORDER BY rank
            LIMIT ?;
            """,
            params: [.text(matchQuery), .int(Int64(limit))]
        ) { row in
            hits.append(KeywordHit(
                chunkID: row.int(0),
                fileID: row.int(1),
                externalID: row.string(2),
                displayName: row.string(3),
                fileType: FileType(rawValue: row.string(4)) ?? .unknown,
                modifiedAt: row.isNull(5) ? nil : Date(timeIntervalSince1970: row.double(5)),
                bm25: row.double(6),
                snippet: row.string(7)
            ))
        }
        return hits
    }
}

/// Raw keyword hit before hybrid ranking is applied.
struct KeywordHit: Sendable {
    let chunkID: Int64
    let fileID: Int64
    let externalID: String
    let displayName: String
    let fileType: FileType
    let modifiedAt: Date?
    let bm25: Double
    let snippet: String
}
