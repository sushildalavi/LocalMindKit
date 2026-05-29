import Foundation
import Observation
import LocalMindKitCore

@Observable
@MainActor
final class PrivacyViewModel {
    var totalFiles = 0
    var totalChunks = 0
    var lastRefresh: Date?
    var indexSizeBytes: Int64 = 0
    var isDeleting = false
    var message: String?

    private var database: Database?

    func configure(database: Database) {
        self.database = database
        Task { await refresh() }
    }

    func refresh() async {
        guard let database else { return }
        totalFiles = (try? await database.fileCount()) ?? 0
        totalChunks = (try? await database.chunkCount()) ?? 0
        lastRefresh = Date()
    }

    func deleteAll() async {
        guard let database else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await database.deleteAll()
            await refresh()
            message = "Index deleted from this device."
        } catch {
            message = "Delete failed: \(error.localizedDescription)"
        }
    }
}
