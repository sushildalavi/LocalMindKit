import SwiftUI

/// A circular progress ring with a centered label. Used on the indexing hero.
struct ProgressRing: View {
  var progress: Double  // 0...1
  var tint: Color = AppTheme.accent
  var lineWidth: CGFloat = 10
  var size: CGFloat = 116

  var body: some View {
    ZStack {
      Circle()
        .stroke(tint.opacity(0.15), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: max(0.001, min(progress, 1)))
        .stroke(
          AngularGradient(colors: [tint.opacity(0.7), tint], center: .center),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(Animations.spring, value: progress)
      VStack(spacing: 0) {
        Text("\(Int((min(progress, 1)) * 100))")
          .font(.system(.title, design: .rounded).weight(.bold))
          .contentTransition(.numericText())
        Text("percent")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: size, height: size)
    .accessibilityLabel("Indexing progress")
    .accessibilityValue("\(Int(min(progress, 1) * 100)) percent")
  }
}
