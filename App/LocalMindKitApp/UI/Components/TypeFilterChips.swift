import SwiftUI
import LocalMindKitCore

struct TypeFilterChips: View {
    @Binding var selection: Set<FileType>

    private let allTypes: [FileType] = [.image, .pdf, .text, .code]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allTypes, id: \.self) { type in
                    let selected = selection.contains(type)
                    Button {
                        if selected { selection.remove(type) } else { selection.insert(type) }
                    } label: {
                        Label(type.rawValue.capitalized, systemImage: icon(for: type))
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(selected ? AppTheme.accent : Color(.secondarySystemFill))
                            )
                            .foregroundStyle(selected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func icon(for type: FileType) -> String {
        switch type {
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .text: return "doc.text"
        case .code: return "curlybraces"
        case .audio: return "waveform"
        case .unknown: return "questionmark"
        }
    }
}
