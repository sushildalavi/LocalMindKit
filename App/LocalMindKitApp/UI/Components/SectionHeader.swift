import SwiftUI

/// A consistent section header with optional trailing accessory.
struct SectionHeader<Trailing: View>: View {
  let title: String
  var subtitle: String?
  @ViewBuilder var trailing: () -> Trailing

  init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
    self.title = title
    self.subtitle = subtitle
    self.trailing = trailing
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(Typography.section)
        if let subtitle {
          Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
      }
      Spacer()
      trailing()
    }
  }
}

extension SectionHeader where Trailing == EmptyView {
  init(_ title: String, subtitle: String? = nil) {
    self.init(title, subtitle: subtitle, trailing: { EmptyView() })
  }
}
