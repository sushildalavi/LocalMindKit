import SwiftUI

/// Apple-native palette: lean on system semantic colors so everything adapts
/// to light/dark mode and Increase-Contrast automatically. A single restrained
/// accent (indigo) carries the brand; no decorative gradients or glassmorphism.
enum AppTheme {
    /// Primary text. System-driven so it adapts to appearance + contrast.
    static let ink = Color.primary
    /// The one accent color. Used for the tab tint, controls, and emphasis.
    static let accent = Color.indigo
    /// Secondary accent for stat glyphs.
    static let accentSecondary = Color.teal

    // Kept for source compatibility with existing call sites.
    static let ocean = Color.indigo
    static let mint = Color.teal
    static let sand = Color(.tertiarySystemFill)

    /// Page background. A near-flat blend of system grouped backgrounds —
    /// subtle depth without looking like a marketing gradient. Adapts to mode.
    static let pageGradient = LinearGradient(
        colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card surface color (used by `lmkCard`).
    static let cardSurface = Color(.secondarySystemGroupedBackground)
    // Kept for source compatibility; resolves to the flat card surface.
    static let cardGradient = LinearGradient(
        colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground)],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// A clean, Apple-style card: flat system surface, continuous corners, and a
/// soft neutral shadow. No tinted glow, no glass.
struct LMKCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardSurface)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

extension View {
    func lmkCard() -> some View { modifier(LMKCardStyle()) }
}
