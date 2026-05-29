import XCTest

@testable import LocalMindKitCore

final class ChunkByIDTests: XCTestCase {
  func testFetchFullChunkByID() async throws {
    let db = try Database(path: ":memory:")
    let fileID = try await db.upsertFile(
      IndexedFile(
        externalID: "f1", displayName: "doc.txt", fileType: .text,
        sizeBytes: 10, contentHash: "h1"))
    let text = "the full untruncated chunk text for the detail view"
    try await db.insertChunks([
      Chunk(
        fileID: fileID, ordinal: 0, text: text, charStart: 0, charEnd: text.count,
        source: .plaintext)
    ])

    // Find the inserted chunk id via a search, then fetch the full chunk.
    let results = try await QueryService(db: db).search("untruncated")
    let hit = try XCTUnwrap(results.first)
    let chunk = try await QueryService(db: db).fullChunk(hit.chunkID)

    XCTAssertEqual(chunk?.text, text)
    XCTAssertEqual(chunk?.source, .plaintext)
  }

  func testFetchMissingChunkReturnsNil() async throws {
    let db = try Database(path: ":memory:")
    let chunk = try await db.chunk(byID: 999)
    XCTAssertNil(chunk)
  }
}
