import Foundation
import XCTest
@testable import LocalMindKitCore

final class RankerTests: XCTestCase {
    func testNormalizedKeywordIsHigherForMoreRelevantNegativeBm25() {
        let strong = Ranker.normalizedKeyword(bm25: -8.0)
        let weak = Ranker.normalizedKeyword(bm25: -0.5)
        XCTAssertGreaterThan(strong, weak)
    }

    func testRecencyDecayPrefersRecentDates() {
        let now = Date()
        let recent = Ranker.recency(modifiedAt: now.addingTimeInterval(-86_400), now: now, halfLifeDays: 90)
        let old = Ranker.recency(modifiedAt: now.addingTimeInterval(-200 * 86_400), now: now, halfLifeDays: 90)
        XCTAssertGreaterThan(recent, old)
    }

    func testCombineIsDeterministic() {
        let weights = RankWeights(keyword: 0.6, semantic: 0, recency: 0.3, typeBoost: 0.1)
        let components = ScoreComponents(keyword: 0.9, semantic: 0, recency: 0.5, typeBoost: 1.2)
        let score = Ranker.combine(components, weights: weights)
        XCTAssertEqual(score, 0.71, accuracy: 0.0001)
    }
}
