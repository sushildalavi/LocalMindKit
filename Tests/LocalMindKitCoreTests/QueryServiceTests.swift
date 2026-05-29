import XCTest

@testable import LocalMindKitCore

final class QueryServiceTests: XCTestCase {
  func testBuildMatchQueryUsesExplicitAND() {
    let built = QueryService.buildMatchQuery(from: "apple  \"job\"   link")
    XCTAssertEqual(built, "\"apple\" AND \"job\" AND \"link\"")
  }

  func testBuildMatchQueryDropsEmptyTerms() {
    let built = QueryService.buildMatchQuery(from: "   \"\"   ")
    XCTAssertEqual(built, "")
  }
}
