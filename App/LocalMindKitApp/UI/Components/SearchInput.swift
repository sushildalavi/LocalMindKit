import SwiftUI

/// The primary search field. Larger tap target, clear affordance, and a focus
/// ring that uses the brand accent.
struct SearchInput: View {
    @Binding var text: String
    var placeholder: String = "Search screenshots and PDFs"
    let onChange: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(focused ? AppTheme.accent : .secondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($focused)
                .onChange(of: text) { _, _ in onChange() }

            if !text.isEmpty {
                Button {
                    text = ""
                    Haptics.tap()
                    onChange()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(focused ? AppTheme.accent.opacity(0.6) : AppTheme.hairline.opacity(0.4),
                              lineWidth: focused ? 1.5 : 0.5)
        )
        .animation(.easeOut(duration: 0.18), value: focused)
        .animation(.easeOut(duration: 0.18), value: text.isEmpty)
    }
}
