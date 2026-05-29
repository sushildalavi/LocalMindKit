import Foundation
import Observation
import LocalMindKitCore

@Observable
@MainActor
final class SearchViewModel {
    var query: String = ""
    var results: [SearchResult] = []
    var selectedTypes: Set<FileType> = []
    var isSearching = false
    var errorMessage: String?

    private var service: QueryService?
    private var searchTask: Task<Void, Never>?

    func configure(service: QueryService) {
        self.service = service
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
            let fileTypes = selectedTypes.isEmpty ? nil : selectedTypes
            results = try await service.search(q, options: .init(limit: 40, fileTypes: fileTypes))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
