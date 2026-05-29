import SwiftUI
import LocalMindKitCore

/// A premium search-result card: a type-colored accent rail, a tinted glyph
/// tile, title, highlighted snippet, and a clean metadata footer. Elevated
/// surface with a soft shadow for depth.
struct ResultCard: View {
    let hit: SearchResult

    var body: some View {
        HStack(spacing: 0) {
            // Type-colored accent rail for visual rhythm down the list.
            Rectangle()
                .fill(tint)
                .frame(width: 4)

            HStack(alignment: .top, spacing: Spacing.md) {
                IconTile(symbol: icon, tint: tint, size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text(hit.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    highlightedSnippet
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.sm) {
                        Text(hit.fileType.rawValue.capitalized)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12), in: Capsule())
                        Spacer(minLength: 0)
                        RelevanceBar(score: min(hit.score, 1))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(Spacing.md)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
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

    private var icon: String {
        switch hit.fileType {
        case .image: return "photo.fill"
        case .pdf: return "doc.richtext.fill"
        case .text: return "doc.text.fill"
        case .code: return "curlybraces"
        case .audio: return "waveform"
        case .unknown: return "questionmark.square"
        }
    }
    private var tint: Color {
        switch hit.fileType {
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
    let score: Double
    private var filled: Int { max(1, Int((score * 5).rounded())) }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? AppTheme.accent : AppTheme.accent.opacity(0.18))
                    .frame(width: 11, height: 4)
            }
        }
        .accessibilityLabel("Relevance")
        .accessibilityValue("\(filled) of 5")
    }
}
