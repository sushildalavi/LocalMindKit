import SwiftUI
import LocalMindKitCore

struct ResultCard: View {
    let hit: SearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Leading type glyph in a tinted rounded tile.
            Image(systemName: icon(for: hit.fileType))
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(hit.displayName)
                    .font(.headline)
                    .lineLimit(1)

                // Snippet with FTS5 highlight markers [ ... ] rendered bold.
                highlightedSnippet
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 6) {
                    Text(hit.fileType.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.sand, in: Capsule())
                    Spacer()
                    Label(String(format: "%.0f%%", min(hit.score, 1) * 100), systemImage: "chart.bar.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    /// Renders the snippet, bolding the text that FTS5 `snippet()` wrapped in
    /// `[` `]` markers so matched terms stand out. Segments inside brackets are
    /// emphasized; everything else is rendered plainly.
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
            acc + (seg.isMatch ? Text(seg.text).bold().foregroundColor(.primary) : Text(seg.text))
        }
    }

    private func icon(for type: FileType) -> String {
        switch type {
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .text: return "doc.text"
        case .code: return "curlybraces"
        case .audio: return "waveform"
        case .unknown: return "questionmark.square"
        }
    }
}
