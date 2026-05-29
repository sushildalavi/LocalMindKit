import LocalMindKitCore
import SwiftUI

/// Horizontal file-type filter bar with an "All" reset. Selected chips fill
/// with the brand accent; the rest are quiet system fills.
struct TypeFilterChips: View {
  @Binding var selection: Set<FileType>

  private let allTypes: [FileType] = [.image, .pdf, .text, .code]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Spacing.sm) {
        chip(
          label: "All", symbol: "square.grid.2x2",
          selected: selection.isEmpty
        ) {
          selection.removeAll()
          Haptics.tap()
        }
        ForEach(allTypes, id: \.self) { type in
          chip(
            label: type.rawValue.capitalized,
            symbol: icon(for: type),
            selected: selection.contains(type)
          ) {
            if selection.contains(type) { selection.remove(type) } else { selection.insert(type) }
            Haptics.tap()
          }
        }
      }
      .padding(.vertical, 2)
    }
  }

  @ViewBuilder
  private func chip(label: String, symbol: String, selected: Bool, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Label(label, systemImage: symbol)
        .labelStyle(.titleAndIcon)
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: 38)
        .background(
          Capsule().fill(selected ? AppTheme.accent : Color(.secondarySystemFill))
        )
        .foregroundStyle(selected ? Color.white : Color.primary)
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? .isSelected : [])
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
