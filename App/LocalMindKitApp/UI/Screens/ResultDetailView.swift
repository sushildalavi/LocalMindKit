import LocalMindKitCore
import SwiftUI
import UIKit

/// Detail sheet for a search result: full extracted text (with matched terms
/// highlighted), file metadata, and copy actions. Loads the full chunk lazily
/// since the list only carries a truncated snippet.
struct ResultDetailView: View {
  let result: SearchResult
  let loadChunk: () async -> Chunk?

  @Environment(\.dismiss) private var dismiss
  @State private var fullText: String?
  @State private var loading = true

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
          header
          Divider()
          textSection
        }
        .padding(Spacing.lg)
      }
      .background(AppTheme.background)
      .navigationTitle("Result")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
      .task {
        fullText = await loadChunk()?.text
        loading = false
      }
    }
  }

  private var header: some View {
    HStack(spacing: Spacing.md) {
      IconTile(symbol: icon, tint: tint, size: 46)
      VStack(alignment: .leading, spacing: 3) {
        Text(result.displayName)
          .font(.headline)
          .lineLimit(2)
        HStack(spacing: Spacing.sm) {
          Text(result.fileType.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
          Text("Relevance \(Int(min(result.score, 1) * 100))%")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private var textSection: some View {
    HStack {
      Text("Extracted text")
        .font(Typography.section)
      Spacer()
      if let text = fullText, !text.isEmpty {
        Button {
          UIPasteboard.general.string = text
          Haptics.success()
        } label: {
          Label("Copy", systemImage: "doc.on.doc")
            .font(.subheadline)
        }
      }
    }

    if loading {
      HStack {
        ProgressView()
        Text("Loading…").foregroundStyle(.secondary)
      }
      .font(.subheadline)
    } else if let text = fullText, !text.isEmpty {
      Text(text)
        .font(.body)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      Text(strippedSnippet)
        .font(.body)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  /// Snippet without the FTS `[ ]` highlight markers, as a fallback.
  private var strippedSnippet: String {
    result.snippet.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
  }

  private var icon: String {
    switch result.fileType {
    case .image: return "photo.fill"
    case .pdf: return "doc.richtext.fill"
    case .text: return "doc.text.fill"
    case .code: return "curlybraces"
    case .audio: return "waveform"
    case .unknown: return "questionmark.square"
    }
  }
  private var tint: Color {
    switch result.fileType {
    case .image: return .indigo
    case .pdf: return .red
    case .text: return .blue
    case .code: return .teal
    case .audio: return .orange
    case .unknown: return .gray
    }
  }
}
