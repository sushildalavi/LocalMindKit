import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
  var prefersHaptics = true
  var lastError: String?
}
