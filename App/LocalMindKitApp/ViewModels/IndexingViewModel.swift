import Foundation
import Observation
import LocalMindKitCore
import Photos

@Observable
@MainActor
final class IndexingViewModel {
    enum State: String {
        case idle
        case indexing
        case complete
        case cancelled
        case failed
    }

    var state: State = .idle
    var done = 0
    var total = 0
    var currentItemID: String?
    var summaryText = "No indexing run yet."
    var errorMessage: String?
    var photoAuthorization: PHAuthorizationStatus = .notDetermined

    private var database: Database?
    private var coordinator: IndexCoordinator?
    private var activeTask: Task<Void, Never>?
    private let photoSource = PhotoLibrarySource()
    private let documentSource = DocumentImportSource()

    func configure(database: Database, coordinator: IndexCoordinator) {
        self.database = database
        self.coordinator = coordinator
    }

    func startMockRun() {
        guard let coordinator else { return }
        activeTask?.cancel()

        let fixtureItems = [
            IngestItem(externalID: "fixture-1", displayName: "Notes.txt", fileType: .text, sizeBytes: 58, data: Data("apple application tracker notes and deadlines".utf8)),
            IngestItem(externalID: "fixture-2", displayName: "Roadmap.md", fileType: .text, sizeBytes: 64, data: Data("local indexing, sqlite fts, vision ocr progress".utf8)),
        ]

        state = .indexing
        done = 0
        total = fixtureItems.count
        errorMessage = nil

        activeTask = Task {
            do {
                let summary = try await coordinator.index(items: fixtureItems) { [weak self] progress in
                    guard let self else { return }
                    await self.applyProgress(progress)
                }
                guard !Task.isCancelled else {
                    state = .cancelled
                    return
                }
                state = .complete
                summaryText = "Indexed: \(summary.indexed), Skipped: \(summary.skipped), Failed: \(summary.failed)"
            } catch is CancellationError {
                state = .cancelled
                summaryText = "Indexing was cancelled."
            } catch {
                state = .failed
                errorMessage = error.localizedDescription
                summaryText = "Indexing failed."
            }
        }
    }

    func cancel() {
        activeTask?.cancel()
    }

    func requestPhotoAccess() {
        Task {
            photoAuthorization = await photoSource.requestAuthorization()
        }
    }

    func ingestScreenshots(limit: Int = 150) {
        guard let coordinator else { return }
        activeTask?.cancel()
        activeTask = Task {
            state = .indexing
            done = 0
            total = 0
            currentItemID = nil
            errorMessage = nil

            let auth = await photoSource.requestAuthorization()
            photoAuthorization = auth
            guard auth == .authorized || auth == .limited else {
                state = .failed
                summaryText = "Photos permission denied."
                return
            }

            let assets = photoSource.fetchScreenshotAssets(limit: limit)
            total = assets.count
            guard !assets.isEmpty else {
                state = .complete
                summaryText = "No screenshots found to index."
                return
            }

            var items: [IngestItem] = []
            items.reserveCapacity(assets.count)
            for (idx, asset) in assets.enumerated() {
                if Task.isCancelled {
                    state = .cancelled
                    summaryText = "Screenshot indexing cancelled."
                    return
                }
                currentItemID = asset.localIdentifier
                done = idx
                if let item = await photoSource.makeIngestItem(asset: asset) {
                    items.append(item)
                }
            }

            do {
                let summary = try await coordinator.index(items: items) { [weak self] progress in
                    guard let self else { return }
                    await self.applyProgress(progress)
                }
                guard !Task.isCancelled else {
                    state = .cancelled
                    summaryText = "Screenshot indexing cancelled."
                    return
                }
                state = .complete
                summaryText = "Screenshots indexed: \(summary.indexed), skipped: \(summary.skipped), failed: \(summary.failed)."
            } catch is CancellationError {
                state = .cancelled
                summaryText = "Screenshot indexing cancelled."
            } catch {
                state = .failed
                errorMessage = error.localizedDescription
                summaryText = "Screenshot indexing failed."
            }
        }
    }

    func ingestDocument(at url: URL) {
        guard let coordinator else { return }
        Task {
            do {
                let persisted = try documentSource.persistImportedFile(url)
                let item = try documentSource.makeIngestItem(for: persisted)
                _ = try await coordinator.index(items: [item])
                summaryText = "Imported and indexed \(persisted.lastPathComponent)."
                state = .complete
            } catch {
                errorMessage = error.localizedDescription
                state = .failed
            }
        }
    }

    func refreshStats() async -> (files: Int, chunks: Int) {
        guard let database else { return (0, 0) }
        let files = (try? await database.fileCount()) ?? 0
        let chunks = (try? await database.chunkCount()) ?? 0
        return (files, chunks)
    }

    private func applyProgress(_ progress: IndexProgress) {
        done = progress.done
        total = progress.total
        currentItemID = progress.currentExternalID
    }
}
