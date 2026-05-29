import SwiftUI

/// A polished empty/onboarding state with an icon, message, and optional
/// tappable example chips to guide the user.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var examples: [String] = []
    var onExampleTap: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 84, height: 84)
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xl)

            if !examples.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Text("TRY")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .kerning(0.8)
                    ForEach(examples, id: \.self) { example in
                        Button {
                            onExampleTap?(example)
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.accent)
                                Text(example)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .frame(minHeight: 44)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(AppTheme.surface,
                                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }
}
