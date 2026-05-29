import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let ocean = Color(red: 0.08, green: 0.38, blue: 0.65)
    static let mint = Color(red: 0.12, green: 0.73, blue: 0.62)
    static let sand = Color(red: 0.95, green: 0.91, blue: 0.82)

    static let pageGradient = LinearGradient(
        colors: [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.89, green: 0.94, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [.white.opacity(0.95), .white.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct LMKCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.cardGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.ocean.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func lmkCard() -> some View { modifier(LMKCardStyle()) }
}
