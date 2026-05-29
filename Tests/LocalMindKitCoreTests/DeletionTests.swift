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

        XCTAssertEqual(try await db.fileCount(), 1)
        XCTAssertEqual(try await db.chunkCount(), 1)

        try await db.deleteAll()

        XCTAssertEqual(try await db.fileCount(), 0)
        XCTAssertEqual(try await db.chunkCount(), 0)
        let service = QueryService(db: db)
        XCTAssertTrue(try await service.search("privacy").isEmpty)
    }
}
