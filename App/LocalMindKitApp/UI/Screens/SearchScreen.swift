import SwiftUI
import LocalMindKitCore

struct SearchScreen: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    SearchInput(text: $viewModel.query) {
                        viewModel.runSearchDebounced()
                    }

                    if viewModel.isSearching {
                        ProgressView("Searching on device…")
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if viewModel.results.isEmpty, !viewModel.query.isEmpty, !viewModel.isSearching {
                        ContentUnavailableView("No results", systemImage: "doc.text.magnifyingglass", description: Text("Try shorter keywords or remove filters."))
                    } else if viewModel.query.isEmpty {
                        ContentUnavailableView("Search Your Local Index", systemImage: "magnifyingglass.circle", description: Text("Type a phrase from a screenshot or imported PDF."))
                    } else {
                        List(viewModel.results) { hit in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(hit.displayName)
                                    .font(.headline)
                                Text(hit.snippet)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                Text(hit.fileType.rawValue.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.sand)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.white.opacity(0.85))
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("LocalMindKit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
