import XCTest

@testable import LocalMindKitCore

final class DatabaseStatsTests: XCTestCase {
  private func makeDB() throws -> Database {
    try Database(path: ":memory:")
  }

  private func insert(_ db: Database, externalID: String, type: FileType) async throws {
    let fileID = try await db.upsertFile(
      IndexedFile(
        externalID: externalID,
        displayName: externalID,
        fileType: type,
        sizeBytes: 10,
        contentHash: "h-\(externalID)"
      ))
    try await db.insertChunks([
      Chunk(
        fileID: fileID, ordinal: 0, text: "alpha beta gamma", charStart: 0, charEnd: 16,
        source: .plaintext)
    ])
  }

  func testFileCountsGroupByType() async throws {
    let db = try makeDB()
    try await insert(db, externalID: "t1", type: .text)
    try await insert(db, externalID: "t2", type: .text)
    try await insert(db, externalID: "i1", type: .image)

    let counts = try await db.fileCounts()
    XCTAssertEqual(counts[.text], 2)
    XCTAssertEqual(counts[.image], 1)
    XCTAssertNil(counts[.pdf])
  }

  func testIndexSizeIsPositiveAfterInsert() async throws {
    let db = try makeDB()
    try await insert(db, externalID: "t1", type: .text)
    let size = try await db.indexSizeBytes()
    XCTAssertGreaterThan(size, 0)
  }

  func testMaintenanceOpsDoNotThrow() async throws {
    let db = try makeDB()
    try await insert(db, externalID: "t1", type: .text)
    try await db.optimize()
    // VACUUM is a no-op-safe rebuild; it must not throw on a live index.
    try await db.vacuum()
  }
}
