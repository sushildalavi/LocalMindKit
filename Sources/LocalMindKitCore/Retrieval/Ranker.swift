import Foundation

/// Pure, deterministic ranking math. Kept separate from I/O so it is trivial
/// to unit-test and reason about in interviews.
public enum Ranker {
    /// FTS5 bm25() returns a cost where lower is better and 0 is a perfect-ish
    /// match. Map it into a 0..1 "higher is better" score with a smooth decay.
    public static func normalizedKeyword(bm25: Double) -> Double {
        // bm25 is negative-leaning in SQLite (more relevant => more negative).
        // Normalize the magnitude through a logistic-ish curve.
        let magnitude = -bm25
        return 1.0 / (1.0 + exp(-magnitude))
    }

    /// Exponential recency decay. Files modified today score ~1; older files
    /// decay with a configurable half-life (default 90 days).
    public static func recency(modifiedAt: Date?, now: Date, halfLifeDays: Double = 90) -> Double {
        guard let modifiedAt else { return 0.0 }
        let ageDays = max(0, now.timeIntervalSince(modifiedAt) / 86_400)
        return pow(0.5, ageDays / halfLifeDays)
    }

    /// Weighted linear combination of normalized components.
    public static func combine(_ c: ScoreComponents, weights w: RankWeights) -> Double {
        w.keyword * c.keyword
            + w.semantic * c.semantic
            + w.recency * c.recency
            + w.typeBoost * (c.typeBoost - 1.0)   // typeBoost is multiplicative-ish around 1
    }
}
