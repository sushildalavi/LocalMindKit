import SwiftUI

struct PrivacyScreen: View {
    @Bindable var viewModel: PrivacyViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        StatTile(label: "Indexed Items", value: "\(viewModel.totalFiles)", symbol: "archivebox")
                        StatTile(label: "Stored Chunks", value: "\(viewModel.totalChunks)", symbol: "text.alignleft")
                        StatTile(
                            label: "Last Refresh",
                            value: viewModel.lastRefresh.map { Formatters.shortDateTime.string(from: $0) } ?? "Never",
                            symbol: "clock"
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Privacy Model")
                                .font(.headline)
                            Text("LocalMindKit stores extracted text chunks and SHA-256 hashes for indexing. Raw screenshots and raw PDF bytes are not stored in the index.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("What leaves the device: nothing, by default.")
                                .font(.subheadline.weight(.semibold))
                        }
                        .lmkCard()

                        Button(role: .destructive) {
                            Task { await viewModel.deleteAll() }
                        } label: {
                            if viewModel.isDeleting {
                                ProgressView()
                            } else {
                                Label("Delete Entire Index", systemImage: "trash")
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        if let message = viewModel.message {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Privacy")
            .task { await viewModel.refresh() }
        }
    }
}
