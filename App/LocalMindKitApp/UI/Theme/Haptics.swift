import UIKit

/// Lightweight haptic feedback helper. Main-actor isolated so the mutable
/// `enabled` flag is concurrency-safe under Swift 6; all call sites are UI.
@MainActor
enum Haptics {
  static var enabled = true

  static func tap() {
    guard enabled else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }

  static func success() {
    guard enabled else { return }
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  static func warning() {
    guard enabled else { return }
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }
}
