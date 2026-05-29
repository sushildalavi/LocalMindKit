import SwiftUI
import LocalMindKitCore

/// A production-grade search result row: leading type tile, title, highlighted
/// snippet, a metadata footer (type + relevance), and a chevron affordance.
struct ResultCard: View {
    let hit: SearchResult

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            IconTile(symbol: icon(for: hit.fileType), tint: tint(for: hit.fileType), size: 42)

            VStack(alignment: .leading, spacing: 5) {
                Text(hit.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                highlightedSnippet
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    Text(hit.fileType.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint(for: hit.fileType))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tint(for: hit.fileType).opacity(0.12), in: Capsule())

                    RelevanceBar(score: min(hit.score, 1))

                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
        }
        .padding(Spacing.md)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(AppTheme.hairline.opacity(0.3), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }

    /// Bolds the text FTS5 `snippet()` wrapped in `[` `]` so matched terms pop.
    private var highlightedSnippet: Text {
        var segments: [(text: String, isMatch: Bool)] = []
        var buffer = ""
        var insideBracket = false
        for ch in hit.snippet {
            switch ch {
            case "[", "]":
                if !buffer.isEmpty { segments.append((buffer, insideBracket)); buffer = "" }
                insideBracket = (ch == "[")
            default:
                buffer.append(ch)
            }
        }
        if !buffer.isEmpty { segments.append((buffer, insideBracket)) }
        guard !segments.isEmpty else { return Text(hit.snippet) }
        return segments.reduce(Text("")) { acc, seg in
            acc + (seg.isMatch
                   ? Text(seg.text).bold().foregroundColor(.primary)
                   : Text(seg.text))
        }
    }

    private func icon(for type: FileType) -> String {
        switch type {
        case .image: return "photo.fill"
        case .pdf: return "doc.richtext.fill"
        case .text: return "doc.text.fill"
        case .code: return "curlybraces"
        case .audio: return "waveform"
        case .unknown: return "questionmark.square"
        }
    }

    private func tint(for type: FileType) -> Color {
        switch type {
        case .image: return .indigo
        case .pdf: return .red
        case .text: return .blue
        case .code: return .teal
        case .audio: return .orange
        case .unknown: return .gray
        }
    }
}

/// A small 5-segment relevance meter — clearer than a raw decimal score.
private struct RelevanceBar: View {
    let score: Double   // 0...1
    private var filled: Int { max(1, Int((score * 5).rounded())) }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? AppTheme.accent : AppTheme.accent.opacity(0.18))
                    .frame(width: 10, height: 4)
            }
        }
        .accessibilityLabel("Relevance")
        .accessibilityValue("\(filled) of 5")
    }
}
