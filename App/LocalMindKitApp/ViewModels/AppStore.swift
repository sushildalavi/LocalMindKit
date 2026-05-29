import Foundation
import Observation
import LocalMindKitCore

@Observable
@MainActor
final class AppStore {
    var search = SearchViewModel()
    var indexing = IndexingViewModel()
    var privacy = PrivacyViewModel()
    var settings = SettingsViewModel()

    init() {
        let dbURL = Self.defaultDatabaseURL()
        Task {
            do {
                let db = try Database(path: dbURL.path)
                let coordinator = IndexCoordinator(db: db)
                let queryService = QueryService(db: db)

                search.configure(service: queryService)
                indexing.configure(database: db, coordinator: coordinator)
                privacy.configure(database: db, dbPath: dbURL.path)
            } catch {
                settings.lastError = "Failed to open index: \(error.localizedDescription)"
            }
        }
    }

    private static func defaultDatabaseURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = base.appendingPathComponent("LocalMindKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("index.sqlite3")
    }
}
