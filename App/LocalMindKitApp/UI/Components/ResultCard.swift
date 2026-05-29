import SwiftUI
import LocalMindKitCore

struct ResultCard: View {
    let hit: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(hit.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Image(systemName: icon(for: hit.fileType))
                    .foregroundStyle(AppTheme.ocean)
                Spacer().frame(width: 4)
                Text(String(format: "%.2f", hit.score))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

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
