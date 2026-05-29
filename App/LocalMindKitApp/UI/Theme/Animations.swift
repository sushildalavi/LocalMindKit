import SwiftUI

enum Animations {
    static let smoothInOut = Animation.easeInOut(duration: 0.25)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)
}
