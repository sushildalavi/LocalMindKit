import XCTest

@testable import LocalMindKitCore

final class TypeFilterTests: XCTestCase {
  private func makeDB() throws -> Database {
    try Database(path: ":memory:")
  }

  private func seed(_ db: Database) async throws {
    for (id, type) in [("t1", FileType.text), ("i1", .image), ("p1", .pdf)] {
      let fileID = try await db.upsertFile(
        IndexedFile(
          externalID: id, displayName: id, fileType: type, sizeBytes: 10, contentHash: "h-\(id)"))
      try await db.insertChunks([
        Chunk(
          fileID: fileID, ordinal: 0, text: "shared keyword here", charStart: 0, charEnd: 19,
          source: .plaintext)
      ])
    }
  }

  func testKeywordSearchFiltersByTypeInSQL() async throws {
    let db = try makeDB()
    try await seed(db)
    let onlyImages = try await db.keywordSearch(
      matchQuery: "\"keyword\"", limit: 10, fileTypes: [.image])
    XCTAssertEqual(onlyImages.count, 1)
    XCTAssertEqual(onlyImages.first?.fileType, .image)
  }

  func testQueryServiceRespectsTypeFilter() async throws {
    let db = try makeDB()
    try await seed(db)
    let svc = QueryService(db: db)
    let results = try await svc.search("keyword", options: .init(fileTypes: [.text, .pdf]))
    XCTAssertEqual(results.count, 2)
    XCTAssertFalse(results.contains { $0.fileType == .image })
  }

  func testNoFilterReturnsAllTypes() async throws {
    let db = try makeDB()
    try await seed(db)
    let svc = QueryService(db: db)
    let results = try await svc.search("keyword")
    XCTAssertEqual(results.count, 3)
  }
}
