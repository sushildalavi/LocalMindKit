import XCTest
@testable import LocalMindKitCore

final class FTS5SearchTests: XCTestCase {
    func testMatchQueryReturnsExpectedHitWithSnippetHighlight() async throws {
        let db = try Database(path: ":memory:")

        let fileID = try await db.upsertFile(IndexedFile(
            externalID: "asset-1",
            displayName: "Screenshot 1",
            fileType: .image,
            sizeBytes: 1024,
            contentHash: "hash-a"
        ))

        try await db.insertChunks([
            Chunk(fileID: fileID, ordinal: 0, text: "Saved the Apple job link from careers page.", charStart: 0, charEnd: 44, source: .ocr),
            Chunk(fileID: fileID, ordinal: 1, text: "Nothing relevant here.", charStart: 45, charEnd: 67, source: .ocr),
        ])

        let service = QueryService(db: db)
        let results = try await service.search("Apple link")

        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.displayName, "Screenshot 1")
        XCTAssertTrue(results.first?.snippet.contains("[") == true)
        XCTAssertTrue(results.first?.snippet.contains("]") == true)
    }
}
