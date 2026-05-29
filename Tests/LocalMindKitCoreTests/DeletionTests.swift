import XCTest
@testable import LocalMindKitCore

final class DeletionTests: XCTestCase {
    func testDeleteAllClearsFilesChunksAndFTS() async throws {
        let db = try Database(path: ":memory:")

        let fileID = try await db.upsertFile(IndexedFile(
            externalID: "pdf-1",
            displayName: "Doc",
            fileType: .pdf,
            sizeBytes: 20,
            contentHash: "x"
        ))
        try await db.insertChunks([
            Chunk(fileID: fileID, ordinal: 0, text: "privacy first local indexing", charStart: 0, charEnd: 27, source: .pdf),
        ])

        let fileCountBeforeDelete = try await db.fileCount()
        let chunkCountBeforeDelete = try await db.chunkCount()
        XCTAssertEqual(fileCountBeforeDelete, 1)
        XCTAssertEqual(chunkCountBeforeDelete, 1)

        try await db.deleteAll()

        let fileCountAfterDelete = try await db.fileCount()
        let chunkCountAfterDelete = try await db.chunkCount()
        XCTAssertEqual(fileCountAfterDelete, 0)
        XCTAssertEqual(chunkCountAfterDelete, 0)
        let service = QueryService(db: db)
        let results = try await service.search("privacy")
        XCTAssertTrue(results.isEmpty)
    }
}
