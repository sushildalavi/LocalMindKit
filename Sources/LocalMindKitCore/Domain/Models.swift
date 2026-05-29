import Foundation

/// The kind of content a file holds. Drives which extractor runs and
/// powers file-type filters / boosts at query time.
public enum FileType: String, Sendable, Codable, CaseIterable {
    case image      // screenshots, photos -> Vision OCR
    case pdf        // PDFKit text extraction
    case text       // plain text / markdown
    case code       // source files
    case audio      // stretch: transcripts
    case unknown
}

/// Where a chunk's text originated. Useful for snippets and debugging.
public enum ChunkSource: String, Sendable, Codable {
    case ocr
    case pdf
    case plaintext
    case transcript
}

/// Processing status for a file, surfaced in the privacy/inspect dashboard.
public enum IndexStatus: String, Sendable, Codable {
    case indexed
    case failed
    case skipped
    case unsupported
}

/// File-level metadata. `externalID` is a stable identifier from the source
/// (e.g. a PHAsset.localIdentifier on iOS, or a path on macOS) so we can
/// dedup, detect moves, and re-index incrementally.
public struct IndexedFile: Sendable, Equatable, Identifiable {
    public var id: Int64?
    public var externalID: String
    public var displayName: String
    public var fileType: FileType
    public var sizeBytes: Int64
    public var contentHash: String       // SHA-256 of the source bytes
    public var createdAt: Date?
    public var modifiedAt: Date?
    public var indexedAt: Date?
    public var status: IndexStatus

    public init(
        id: Int64? = nil,
        externalID: String,
        displayName: String,
        fileType: FileType,
        sizeBytes: Int64,
        contentHash: String,
        createdAt: Date? = nil,
        modifiedAt: Date? = nil,
        indexedAt: Date? = nil,
        status: IndexStatus = .indexed
    ) {
        self.id = id
        self.externalID = externalID
        self.displayName = displayName
        self.fileType = fileType
        self.sizeBytes = sizeBytes
        self.contentHash = contentHash
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.indexedAt = indexedAt
        self.status = status
    }
}

/// A searchable unit of text within a file. We store chunks (with offsets),
/// never the raw source bytes — keeps the index privacy-honest and lets us
/// generate snippets and re-embed without re-extracting.
public struct Chunk: Sendable, Equatable, Identifiable {
    public var id: Int64?
    public var fileID: Int64
    public var ordinal: Int
    public var text: String
    public var charStart: Int
    public var charEnd: Int
    public var source: ChunkSource

    public init(
        id: Int64? = nil,
        fileID: Int64,
        ordinal: Int,
        text: String,
        charStart: Int,
        charEnd: Int,
        source: ChunkSource
    ) {
        self.id = id
        self.fileID = fileID
        self.ordinal = ordinal
        self.text = text
        self.charStart = charStart
        self.charEnd = charEnd
        self.source = source
    }
}

/// A ranked search hit returned to the UI.
public struct SearchResult: Sendable, Equatable, Identifiable {
    public var id: Int64 { chunkID }
    public var chunkID: Int64
    public var fileID: Int64
    public var externalID: String
    public var displayName: String
    public var fileType: FileType
    public var snippet: String          // contains highlight markers
    public var score: Double            // final combined score
    public var components: ScoreComponents

    public init(
        chunkID: Int64,
        fileID: Int64,
        externalID: String,
        displayName: String,
        fileType: FileType,
        snippet: String,
        score: Double,
        components: ScoreComponents
    ) {
        self.chunkID = chunkID
        self.fileID = fileID
        self.externalID = externalID
        self.displayName = displayName
        self.fileType = fileType
        self.snippet = snippet
        self.score = score
        self.components = components
    }
}

/// Per-result score breakdown, surfaced in the "why this matched" panel.
public struct ScoreComponents: Sendable, Equatable {
    public var keyword: Double
    public var semantic: Double
    public var recency: Double
    public var typeBoost: Double

    public init(keyword: Double = 0, semantic: Double = 0, recency: Double = 0, typeBoost: Double = 0) {
        self.keyword = keyword
        self.semantic = semantic
        self.recency = recency
        self.typeBoost = typeBoost
    }
}

/// A unit of source content to ingest into the local index.
public struct IngestItem: Sendable, Equatable {
    public var externalID: String
    public var displayName: String
    public var fileType: FileType
    public var sizeBytes: Int64
    public var data: Data?
    public var url: URL?
    public var createdAt: Date?
    public var modifiedAt: Date?

    public init(
        externalID: String,
        displayName: String,
        fileType: FileType,
        sizeBytes: Int64,
        data: Data,
        createdAt: Date? = nil,
        modifiedAt: Date? = nil
    ) {
        self.externalID = externalID
        self.displayName = displayName
        self.fileType = fileType
        self.sizeBytes = sizeBytes
        self.data = data
        self.url = nil
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    public init(
        externalID: String,
        displayName: String,
        fileType: FileType,
        sizeBytes: Int64,
        url: URL,
        createdAt: Date? = nil,
        modifiedAt: Date? = nil
    ) {
        self.externalID = externalID
        self.displayName = displayName
        self.fileType = fileType
        self.sizeBytes = sizeBytes
        self.data = nil
        self.url = url
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
