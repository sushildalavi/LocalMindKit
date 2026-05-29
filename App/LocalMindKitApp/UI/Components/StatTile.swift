import SwiftUI

struct StatTile: View {
    let label: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.ocean)
                .frame(width: 34, height: 34)
                .background(AppTheme.mint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer()
        }
        .lmkCard()
    }
}
