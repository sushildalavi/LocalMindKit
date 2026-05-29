import XCTest
@testable import LocalMindKitCore

final class ChunkerTests: XCTestCase {
    func testChunkerCreatesMultipleChunksWithMonotonicOffsets() {
        let text = Array(repeating: "Alpha beta gamma delta epsilon zeta eta theta iota kappa.", count: 20).joined(separator: " ")
        let chunker = Chunker(targetChars: 140, overlapChars: 30)
        let chunks = chunker.chunk(text, fileID: 1, source: .plaintext)

        XCTAssertGreaterThan(chunks.count, 1)
        XCTAssertEqual(chunks.first?.charStart, 0)
        for i in 1..<chunks.count {
            XCTAssertGreaterThanOrEqual(chunks[i].charStart, chunks[i - 1].charStart)
            XCTAssertGreaterThan(chunks[i].charEnd, chunks[i].charStart)
        }
    }
}
