import SwiftUI

/// Type scale. Rounded display faces for headings give a friendly,
/// product-grade feel while body text stays in the system default for legibility.
enum Typography {
    static let hero = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let section = Font.system(.headline, design: .rounded).weight(.semibold)
    static let cardTitle = Font.system(.headline)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption)
}
