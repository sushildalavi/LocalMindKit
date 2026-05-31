import XCTest

@testable import LocalMindKitCore

final class ChunkerHardSplitTests: XCTestCase {
  func testSingleOversizeSentenceIsSplit() {
    let chunker = Chunker(targetChars: 200, overlapChars: 40)
    // One "sentence" with no breaks (e.g. minified code / a long token run).
    let text = String(repeating: "word", count: 300)  // 1,200 chars, no whitespace
    let chunks = chunker.chunk(text, fileID: 1, source: .plaintext)

    XCTAssertGreaterThan(chunks.count, 1, "an oversize sentence should be hard-split")
    for chunk in chunks {
      XCTAssertLessThanOrEqual(
        chunk.text.count, 200 + 40, "no chunk should exceed target + overlap")
    }
    XCTAssertEqual(chunks.map { $0.ordinal }, Array(0..<chunks.count))
  }

  func testSplitOversizedKeepsNormalRangeIntact() {
    let text = "short range"
    let range = text.startIndex..<text.endIndex
    let pieces = Chunker.splitOversized(range, in: text, max: 100)
    XCTAssertEqual(pieces.count, 1)
    XCTAssertEqual(pieces.first, range)
  }
}
