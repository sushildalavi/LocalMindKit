import SwiftUI
import Photos

struct IndexScreen: View {
    @Bindable var viewModel: IndexingViewModel
    @State private var stats: (files: Int, chunks: Int) = (0, 0)
    @State private var importing = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        StatTile(label: "State", value: viewModel.state.rawValue.capitalized, symbol: "gauge.with.dots.needle.50percent")
                        StatTile(label: "Files Indexed", value: "\(stats.files)", symbol: "doc.text")
                        StatTile(label: "Chunks", value: "\(stats.chunks)", symbol: "text.quote")
                        StatTile(label: "Photos Permission", value: permissionLabel(viewModel.photoAuthorization), symbol: "photo.on.rectangle")

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Progress")
                                .font(.headline)
                            ProgressView(value: viewModel.total == 0 ? 0 : Double(viewModel.done), total: Double(max(viewModel.total, 1)))
                            Text("\(viewModel.done) / \(viewModel.total)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let current = viewModel.currentItemID {
                                Text("Current: \(current)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(viewModel.summaryText)
                                .font(.subheadline)
                        }
                        .lmkCard()

                        HStack(spacing: 12) {
                            Button("Run Index Demo") { viewModel.startMockRun() }
                                .buttonStyle(.borderedProminent)
                                .accessibilityLabel("Run index demo")
                            Button("Stop") { viewModel.cancel() }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Stop indexing")
                        }
                        Button("Index Screenshots") {
                            viewModel.ingestScreenshots()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Request Photos Access") {
                            viewModel.requestPhotoAccess()
                        }
                        .buttonStyle(.bordered)
                        Button("Import Document") {
                            importing = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .animation(Animations.smoothInOut, value: viewModel.done)
                    .animation(Animations.smoothInOut, value: viewModel.state)
                }
            }
            .navigationTitle("Index")
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: DocumentImportSource.supportedTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    viewModel.ingestDocument(at: url)
                }
            }
            .task {
                stats = await viewModel.refreshStats()
            }
            .onChange(of: viewModel.state) { _, _ in
                Task { stats = await viewModel.refreshStats() }
            }
        }
    }

    private func permissionLabel(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .limited: return "Limited"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
}
