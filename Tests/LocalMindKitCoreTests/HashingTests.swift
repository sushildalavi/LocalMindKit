import Foundation
import XCTest
@testable import LocalMindKitCore

final class HashingTests: XCTestCase {
    func testSha256IsDeterministic() {
        let data = Data("localmindkit".utf8)
        let a = Hashing.sha256(data)
        let b = Hashing.sha256(data)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 64)
    }
}
