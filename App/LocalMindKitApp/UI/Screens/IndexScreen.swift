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
                    VStack(spacing: 16) {
                        // Stats in a compact 2-column grid rather than a tall stack.
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12)],
                                  spacing: 12) {
                            StatTile(label: "State", value: viewModel.state.rawValue.capitalized, symbol: "gauge.with.dots.needle.50percent")
                            StatTile(label: "Files", value: "\(stats.files)", symbol: "doc.text")
                            StatTile(label: "Chunks", value: "\(stats.chunks)", symbol: "text.quote")
                            StatTile(label: "Photos", value: permissionLabel(viewModel.photoAuthorization), symbol: "photo.on.rectangle")
                        }

                        // Progress card.
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Progress")
                                .font(.headline)
                            ProgressView(value: viewModel.total == 0 ? 0 : Double(viewModel.done), total: Double(max(viewModel.total, 1)))
                                .tint(AppTheme.accent)
                            HStack {
                                Text("\(viewModel.done) / \(viewModel.total)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let current = viewModel.currentItemID {
                                    Text(current)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            Text(viewModel.summaryText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmkCard()

                        // Primary actions, clear hierarchy: one prominent action,
                        // the rest bordered. Permission prompt only when needed.
                        VStack(spacing: 10) {
                            Button {
                                viewModel.ingestScreenshots()
                            } label: {
                                Label("Index Screenshots", systemImage: "photo.stack")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            Button {
                                importing = true
                            } label: {
                                Label("Import Document", systemImage: "doc.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)

                            if viewModel.photoAuthorization == .notDetermined || viewModel.photoAuthorization == .denied {
                                Button {
                                    viewModel.requestPhotoAccess()
                                } label: {
                                    Label("Allow Photos Access", systemImage: "lock.open")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }

                        // Demo/dev affordance, de-emphasized at the bottom.
                        HStack(spacing: 12) {
                            Button("Run Demo") { viewModel.startMockRun() }
                                .accessibilityLabel("Run index demo")
                            Spacer()
                            Button("Stop", role: .cancel) { viewModel.cancel() }
                                .accessibilityLabel("Stop indexing")
                        }
                        .font(.subheadline)
                        .tint(AppTheme.accent)
                        .padding(.top, 4)
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
