import XCTest
@testable import LocalMindKitCore

final class DedupTests: XCTestCase {
    func testReUpsertSameExternalIDReplacesChunksWithoutOrphans() async throws {
        let db = try Database(path: ":memory:")

        var file = IndexedFile(
            externalID: "doc-1",
            displayName: "Doc",
            fileType: .text,
            sizeBytes: 10,
            contentHash: "h1"
        )
        let fileID1 = try await db.upsertFile(file)
        try await db.insertChunks([
            Chunk(fileID: fileID1, ordinal: 0, text: "old chunk one", charStart: 0, charEnd: 12, source: .plaintext),
            Chunk(fileID: fileID1, ordinal: 1, text: "old chunk two", charStart: 13, charEnd: 25, source: .plaintext),
        ])
        let initialChunkCount = try await db.chunkCount()
        XCTAssertEqual(initialChunkCount, 2)

        file.contentHash = "h2"
        let fileID2 = try await db.upsertFile(file)
        try await db.insertChunks([
            Chunk(fileID: fileID2, ordinal: 0, text: "new content", charStart: 0, charEnd: 10, source: .plaintext),
        ])

        let finalFileCount = try await db.fileCount()
        let finalChunkCount = try await db.chunkCount()
        XCTAssertEqual(finalFileCount, 1)
        XCTAssertEqual(finalChunkCount, 1)

        let service = QueryService(db: db)
        let oldHits = try await service.search("old")
        let newHits = try await service.search("new")
        XCTAssertTrue(oldHits.isEmpty)
        XCTAssertEqual(newHits.count, 1)
    }
}
