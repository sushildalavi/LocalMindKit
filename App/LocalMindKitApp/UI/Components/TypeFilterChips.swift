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
                        Text(type.rawValue.uppercased())
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selected ? AppTheme.ocean.opacity(0.2) : .white.opacity(0.8))
                            .foregroundStyle(selected ? AppTheme.ocean : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
