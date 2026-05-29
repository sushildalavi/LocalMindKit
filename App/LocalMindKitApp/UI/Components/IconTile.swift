import SwiftUI

/// A rounded, tinted glyph tile — the recurring leading element on result rows,
/// metrics, and list items. Gives the UI a consistent visual rhythm.
struct IconTile: View {
  let symbol: String
  var tint: Color = AppTheme.accent
  var size: CGFloat = 38

  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: size * 0.45, weight: .semibold))
      .foregroundStyle(tint)
      .frame(width: size, height: size)
      .background(
        tint.opacity(0.14),
        in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
  }
}
