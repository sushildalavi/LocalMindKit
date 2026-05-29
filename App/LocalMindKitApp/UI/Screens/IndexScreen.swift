import SwiftUI

struct IndexScreen: View {
    @Bindable var viewModel: IndexingViewModel
    @State private var stats: (files: Int, chunks: Int) = (0, 0)

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        StatTile(label: "State", value: viewModel.state.rawValue.capitalized, symbol: "gauge.with.dots.needle.50percent")
                        StatTile(label: "Files Indexed", value: "\(stats.files)", symbol: "doc.text")
                        StatTile(label: "Chunks", value: "\(stats.chunks)", symbol: "text.quote")

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
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Index")
            .task {
                stats = await viewModel.refreshStats()
            }
        }
    }
}
