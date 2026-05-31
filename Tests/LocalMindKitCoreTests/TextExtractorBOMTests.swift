import XCTest

@testable import LocalMindKitCore

final class TextExtractorBOMTests: XCTestCase {
  func testStripsUTF8BOM() {
    var data = Data([0xEF, 0xBB, 0xBF])  // UTF-8 BOM
    data.append(Data("hello".utf8))
    let extractor = TextExtractor()
    XCTAssertEqual(extractor.extractText(from: data), "hello")
  }

  func testNoBOMUnchanged() {
    let extractor = TextExtractor()
    XCTAssertEqual(extractor.extractText(from: Data("plain".utf8)), "plain")
  }

  func testWindows1252FallbackDecodes() {
    // 0x93/0x94 are smart quotes in CP1252 but invalid UTF-8 lead bytes.
    let data = Data([0x93, 0x68, 0x69, 0x94])
    let extractor = TextExtractor()
    let text = extractor.extractText(from: data)
    XCTAssertFalse(text.isEmpty, "CP1252 bytes should not be dropped")
    XCTAssertTrue(text.contains("hi"))
  }
}
