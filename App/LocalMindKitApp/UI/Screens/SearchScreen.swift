import SwiftUI
import LocalMindKitCore

struct SearchScreen: View {
    @Bindable var viewModel: SearchViewModel

    private let examples = [
        "apple job link",
        "gpa transcript",
        "kafka redis swift",
        "distributed systems",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    // Pinned search controls.
                    VStack(spacing: Spacing.md) {
                        SearchInput(text: $viewModel.query) {
                            viewModel.runSearchDebounced()
                        }
                        .accessibilityLabel("Search input")

                        TypeFilterChips(selection: $viewModel.selectedTypes)
                            .accessibilityLabel("File type filters")
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                    content
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: viewModel.selectedTypes) { _, _ in
                viewModel.runSearchDebounced()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.errorMessage, !viewModel.isSearching {
            Spacer()
            EmptyStateView(symbol: "exclamationmark.triangle",
                           title: "Search Error",
                           message: error)
            Spacer()
        } else if viewModel.query.isEmpty {
            ScrollView {
                EmptyStateView(
                    symbol: "sparkle.magnifyingglass",
                    title: "Search Your Local Index",
                    message: "Find text inside your screenshots and imported PDFs — instantly, and entirely on-device.",
                    examples: examples,
                    onExampleTap: { example in
                        viewModel.query = example
                        viewModel.runSearchDebounced()
                    }
                )
            }
        } else if viewModel.results.isEmpty, !viewModel.isSearching {
            Spacer()
            EmptyStateView(symbol: "doc.text.magnifyingglass",
                           title: "No Results",
                           message: "Try shorter keywords or remove a filter.")
            Spacer()
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                HStack {
                    Text("^[\(viewModel.results.count) result](inflect: true)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    if viewModel.isSearching {
                        ProgressView().controlSize(.small)
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)

                ForEach(viewModel.results) { hit in
                    ResultCard(hit: hit)
                        .padding(.horizontal, Spacing.lg)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(hit.displayName), \(hit.fileType.rawValue)")
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
