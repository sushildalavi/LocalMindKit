import LocalMindKitCore
import SwiftUI
import UIKit

struct SearchScreen: View {
  @Bindable var viewModel: SearchViewModel
  @State private var selectedResult: SearchResult?

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
            .animation(Animations.smoothInOut, value: viewModel.results.count)
            .animation(Animations.smoothInOut, value: viewModel.query.isEmpty)
        }
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
      .onChange(of: viewModel.selectedTypes) { _, _ in viewModel.runSearchDebounced() }
      .onChange(of: viewModel.sortMode) { _, _ in viewModel.runSearchDebounced() }
      .sheet(item: $selectedResult) { result in
        ResultDetailView(result: result) {
          await viewModel.fullChunk(for: result)
        }
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let error = viewModel.errorMessage, !viewModel.isSearching {
      spacedEmpty(symbol: "exclamationmark.triangle", title: "Search Error", message: error)
    } else if viewModel.query.isEmpty {
      emptyQueryState
    } else if viewModel.results.isEmpty, !viewModel.isSearching {
      spacedEmpty(
        symbol: "doc.text.magnifyingglass", title: "No Results",
        message: "Try shorter keywords or remove a filter.")
    } else {
      resultsList
    }
  }

  private func spacedEmpty(symbol: String, title: String, message: String) -> some View {
    VStack {
      Spacer()
      EmptyStateView(symbol: symbol, title: title, message: message)
      Spacer()
    }
  }

  // MARK: - Empty query (recents or examples)

  @ViewBuilder
  private var emptyQueryState: some View {
    ScrollView {
      if viewModel.recentSearches.isEmpty {
        EmptyStateView(
          symbol: "sparkle.magnifyingglass",
          title: "Search Your Local Index",
          message:
            "Find text inside your screenshots and imported PDFs — instantly, and entirely on-device.",
          examples: examples,
          onExampleTap: run
        )
      } else {
        VStack(alignment: .leading, spacing: Spacing.md) {
          HStack {
            SectionHeader("Recent")
            Button("Clear") { viewModel.clearRecents() }
              .font(.subheadline)
          }
          ForEach(viewModel.recentSearches, id: \.self) { term in
            Button {
              run(term)
            } label: {
              HStack(spacing: Spacing.md) {
                Image(systemName: "clock.arrow.circlepath")
                  .foregroundStyle(.secondary)
                Text(term).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.left").font(.caption).foregroundStyle(.secondary)
              }
              .padding(.vertical, Spacing.md)
              .padding(.horizontal, Spacing.lg)
              .frame(minHeight: 44)
              .background(
                AppTheme.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
      }
    }
  }

  private func run(_ term: String) {
    viewModel.query = term
    viewModel.runSearchDebounced()
  }

  // MARK: - Results

  private var resultsList: some View {
    ScrollView {
      LazyVStack(spacing: Spacing.md) {
        HStack {
          Text("^[\(viewModel.results.count) result](inflect: true)")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
          if viewModel.isSearching { ProgressView().controlSize(.small) }
          Spacer()
          sortMenu
        }
        .padding(.horizontal, Spacing.lg)

        ForEach(viewModel.results) { hit in
          Button {
            selectedResult = hit
            Haptics.tap()
          } label: {
            ResultCard(hit: hit)
          }
          .buttonStyle(.plain)
          .contextMenu {
            Button {
              UIPasteboard.general.string = hit.snippet
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
            } label: {
              Label("Copy Snippet", systemImage: "doc.on.doc")
            }
            Button {
              UIPasteboard.general.string = hit.displayName
            } label: {
              Label("Copy File Name", systemImage: "textformat")
            }
          }
          .padding(.horizontal, Spacing.lg)
          .accessibilityElement(children: .combine)
          .accessibilityLabel("\(hit.displayName), \(hit.fileType.rawValue)")
          .accessibilityHint("Opens result details")
        }
      }
      .padding(.vertical, Spacing.sm)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  private var sortMenu: some View {
    Menu {
      Picker("Sort", selection: $viewModel.sortMode) {
        ForEach(SearchViewModel.SortMode.allCases) { mode in
          Label(mode.label, systemImage: mode.symbol).tag(mode)
        }
      }
    } label: {
      Label(viewModel.sortMode.label, systemImage: "arrow.up.arrow.down")
        .font(.footnote.weight(.medium))
    }
    .accessibilityLabel("Sort results")
  }
}
