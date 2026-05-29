import Foundation
import LocalMindKitCore
import Observation

@Observable
@MainActor
final class SearchViewModel {
  enum SortMode: String, CaseIterable, Identifiable {
    case relevance, recency
    var id: String { rawValue }
    var label: String { self == .relevance ? "Relevance" : "Recent" }
    var symbol: String { self == .relevance ? "sparkles" : "clock" }
  }

  var query: String = ""
  var results: [SearchResult] = []
  var selectedTypes: Set<FileType> = []
  var sortMode: SortMode = .relevance
  var isSearching = false
  var errorMessage: String?
  var recentSearches: [String] = []

  private var service: QueryService?
  private var searchTask: Task<Void, Never>?
  private var cache: [String: [SearchResult]] = [:]
  private let recentsKey = "recentSearches"
  private let maxRecents = 8

  init() {
    recentSearches = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
  }

  func configure(service: QueryService) {
    self.service = service
  }

  /// Fetch the full chunk text behind a result for the detail view.
  func fullChunk(for result: SearchResult) async -> Chunk? {
    guard let service else { return nil }
    return try? await service.fullChunk(result.chunkID)
  }

  func runSearchDebounced() {
    searchTask?.cancel()
    let currentQuery = query
    searchTask = Task {
      try? await Task.sleep(nanoseconds: 150_000_000)
      guard !Task.isCancelled else { return }
      await search(currentQuery)
    }
  }

  func search(_ input: String? = nil) async {
    guard let service else { return }
    isSearching = true
    defer { isSearching = false }
    do {
      let q = (input ?? query).trimmingCharacters(in: .whitespacesAndNewlines)
      if q.isEmpty {
        results = []
        return
      }
      let typeKey = selectedTypes.map(\.rawValue).sorted().joined(separator: ",")
      let cacheKey = "\(q.lowercased())|\(typeKey)|\(sortMode.rawValue)"
      if let cached = cache[cacheKey] {
        results = cached
        errorMessage = nil
        recordRecent(q)
        return
      }
      let fileTypes = selectedTypes.isEmpty ? nil : selectedTypes
      // Recency sort leans the ranker toward recency; relevance keeps defaults.
      let weights: RankWeights =
        sortMode == .recency
        ? RankWeights(keyword: 0.2, semantic: 0, recency: 0.8, typeBoost: 0.1)
        : RankWeights()
      let fetched = try await service.search(
        q, options: .init(limit: 40, fileTypes: fileTypes, weights: weights))
      cache[cacheKey] = fetched
      results = fetched
      errorMessage = nil
      recordRecent(q)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func clearRecents() {
    recentSearches = []
    UserDefaults.standard.removeObject(forKey: recentsKey)
  }

  private func recordRecent(_ q: String) {
    recentSearches.removeAll { $0.caseInsensitiveCompare(q) == .orderedSame }
    recentSearches.insert(q, at: 0)
    if recentSearches.count > maxRecents {
      recentSearches = Array(recentSearches.prefix(maxRecents))
    }
    UserDefaults.standard.set(recentSearches, forKey: recentsKey)
  }
}
