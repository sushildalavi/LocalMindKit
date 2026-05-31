import XCTest

@testable import LocalMindKitCore

final class PrefixSearchTests: XCTestCase {
  private func makeDB() throws -> Database {
    try Database(path: ":memory:")
  }

  func testBuildMatchQueryPrefixesOnlyLastTerm() {
    let q = QueryService.buildMatchQuery(from: "annual inv", prefix: true)
    XCTAssertEqual(q, "\"annual\" AND \"inv\"*")
  }

  func testBuildMatchQuerySingleTermPrefix() {
    let q = QueryService.buildMatchQuery(from: "inv", prefix: true)
    XCTAssertEqual(q, "\"inv\"*")
  }

  func testBuildMatchQueryNoPrefixByDefault() {
    let q = QueryService.buildMatchQuery(from: "inv")
    XCTAssertEqual(q, "\"inv\"")
  }

  func testPrefixSearchMatchesPartialWord() async throws {
    let db = try makeDB()
    let fileID = try await db.upsertFile(
      IndexedFile(
        externalID: "doc-1",
        displayName: "Doc 1",
        fileType: .text,
        sizeBytes: 10,
        contentHash: "h"
      ))
    try await db.insertChunks([
      Chunk(
        fileID: fileID, ordinal: 0, text: "quarterly invoice total", charStart: 0, charEnd: 23,
        source: .plaintext)
    ])

    let svc = QueryService(db: db)
    let exact = try await svc.search("inv")
    XCTAssertEqual(exact.count, 0, "exact search should not match a partial word")

    let prefixed = try await svc.search("inv", options: .init(prefixMatch: true))
    XCTAssertEqual(prefixed.count, 1, "prefix search should match 'invoice'")
  }
}
