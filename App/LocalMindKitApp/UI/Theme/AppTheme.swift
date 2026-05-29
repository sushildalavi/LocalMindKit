import SwiftUI

// MARK: - Design tokens

/// Consistent spacing scale (4-pt grid).
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Corner-radius scale.
enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
}

/// Palette: system semantic colors so everything adapts to light/dark and
/// Increase-Contrast, with a single restrained brand accent (indigo).
enum AppTheme {
    static let ink = Color.primary
    static let accent = Color.indigo
    static let accentSecondary = Color.teal

    // Source-compat aliases used by older call sites.
    static let ocean = Color.indigo
    static let mint = Color.teal
    static let sand = Color(.tertiarySystemFill)

    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let surfaceMuted = Color(.tertiarySystemGroupedBackground)
    static let hairline = Color(.separator)

    static let pageGradient = LinearGradient(
        colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
        startPoint: .top, endPoint: .bottom
    )
    static let cardGradient = LinearGradient(
        colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground)],
        startPoint: .top, endPoint: .bottom
    )
    static let cardSurface = Color(.secondarySystemGroupedBackground)

    /// Subtle brand gradient, used sparingly on hero surfaces only.
    static let brandGradient = LinearGradient(
        colors: [Color.indigo, Color.indigo.opacity(0.75), Color.purple.opacity(0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Card surface

/// A clean, elevated card: flat system surface, continuous corners, hairline
/// border, soft neutral shadow. No glassmorphism, no tinted glow.
struct LMKCardStyle: ViewModifier {
    var padding: CGFloat = Spacing.lg
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(AppTheme.hairline.opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func lmkCard(padding: CGFloat = Spacing.lg) -> some View {
        modifier(LMKCardStyle(padding: padding))
    }
}

// MARK: - Button styles

/// Full-width prominent action with a subtle press scale.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(tint.opacity(configuration.isPressed ? 0.85 : 1),
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Full-width secondary action on a tinted fill.
struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(tint)
            .background(tint.opacity(configuration.isPressed ? 0.18 : 0.12),
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
