import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var prefersHaptics = true
    var prefersLargeCards = false
    var lastError: String?
}
