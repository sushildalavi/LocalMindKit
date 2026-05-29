import Foundation
import XCTest

@testable import LocalMindKitCore

final class TextExtractorTests: XCTestCase {
  func testExtractTextFromData() {
    let extractor = TextExtractor()
    let result = extractor.extractText(from: Data("hello world".utf8))
    XCTAssertEqual(result, "hello world")
  }
}
