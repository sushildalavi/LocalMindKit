import Foundation

/// Options that shape a search: filters and the hybrid weighting.
public struct SearchOptions: Sendable {
  public var limit: Int
  public var fileTypes: Set<FileType>?  // nil == all types
  public var weights: RankWeights

  public init(limit: Int = 30, fileTypes: Set<FileType>? = nil, weights: RankWeights = .init()) {
    self.limit = limit
    self.fileTypes = fileTypes
    self.weights = weights
  }
}

/// Tunable hybrid-ranking weights. Defaults favor keyword for the MVP; the
/// semantic weight comes into play once embeddings ship (V1).
public struct RankWeights: Sendable {
  public var keyword: Double
  public var semantic: Double
  public var recency: Double
  public var typeBoost: Double

  public init(
    keyword: Double = 0.6, semantic: Double = 0.0, recency: Double = 0.3, typeBoost: Double = 0.1
  ) {
    self.keyword = keyword
    self.semantic = semantic
    self.recency = recency
    self.typeBoost = typeBoost
  }
}

/// Turns a user query into ranked results.
///
/// MVP path: FTS5 keyword search + recency/type boosts. The semantic
/// component is wired through `ScoreComponents` so V1 can add a vector
/// candidate set and blend it without changing the result type.
public struct QueryService: Sendable {
  let db: Database

  public init(db: Database) {
    self.db = db
  }

  /// Fetch the full chunk behind a result (the search snippet is truncated).
  public func fullChunk(_ id: Int64) async throws -> Chunk? {
    try await db.chunk(byID: id)
  }

  public func search(_ query: String, options: SearchOptions = .init()) async throws
    -> [SearchResult]
  {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    let matchQuery = Self.buildMatchQuery(from: trimmed)
    // Over-fetch so post-filtering/boosting still leaves a full page.
    let raw = try await db.keywordSearch(matchQuery: matchQuery, limit: options.limit * 3)

    let now = Date()
    var results: [SearchResult] = []
    for hit in raw {
      if let types = options.fileTypes, !types.contains(hit.fileType) { continue }

      let kw = Ranker.normalizedKeyword(bm25: hit.bm25)
      let rec = Ranker.recency(modifiedAt: hit.modifiedAt, now: now)
      let typeBoost = 1.0  // placeholder until intent detection sets per-type boosts
      let comps = ScoreComponents(keyword: kw, semantic: 0, recency: rec, typeBoost: typeBoost)
      let score = Ranker.combine(comps, weights: options.weights)

      results.append(
        SearchResult(
          chunkID: hit.chunkID,
          fileID: hit.fileID,
          externalID: hit.externalID,
          displayName: hit.displayName,
          fileType: hit.fileType,
          snippet: hit.snippet,
          score: score,
          components: comps
        ))
    }

    results.sort { $0.score > $1.score }
    return Array(results.prefix(options.limit))
  }

  /// Build a safe FTS5 MATCH expression. We quote each term to avoid the
  /// user accidentally triggering FTS operators, and AND them together.
  static func buildMatchQuery(from input: String) -> String {
    let terms =
      input
      .split(whereSeparator: { $0.isWhitespace })
      .map { $0.replacingOccurrences(of: "\"", with: "") }
      .filter { !$0.isEmpty }
      .map { "\"\($0)\"" }
    return terms.joined(separator: " AND ")
  }
}
