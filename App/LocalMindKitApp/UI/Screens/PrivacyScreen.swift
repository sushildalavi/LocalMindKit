import SwiftUI

struct PrivacyScreen: View {
    @Bindable var viewModel: PrivacyViewModel
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        hero
                        metrics
                        explainer
                        dangerZone
                        if let message = viewModel.message {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Privacy")
            .task { await viewModel.refresh() }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(.white.opacity(0.18), in: Circle())

            Text("Private by design")
                .font(Typography.title)
                .foregroundStyle(.white)
            Text("Nothing leaves your device. No account, no servers, no network in the core app.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Label("Network calls: none (enforced by tests)", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .background(.white.opacity(0.18), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(AppTheme.brandGradient,
                    in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.25), radius: 16, x: 0, y: 8)
    }

    // MARK: - Metrics

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.md),
                            GridItem(.flexible(), spacing: Spacing.md)],
                  spacing: Spacing.md) {
            MetricCard(symbol: "archivebox.fill", value: "\(viewModel.totalFiles)", label: "Indexed items", tint: .blue)
            MetricCard(symbol: "text.alignleft", value: "\(viewModel.totalChunks)", label: "Stored chunks", tint: .teal)
            MetricCard(symbol: "internaldrive.fill",
                       value: ByteCountFormatter.string(fromByteCount: viewModel.indexSizeBytes, countStyle: .file),
                       label: "Index size", tint: .indigo)
            MetricCard(symbol: "clock.fill",
                       value: viewModel.lastRefresh.map { Formatters.shortDateTime.string(from: $0) } ?? "Never",
                       label: "Last refreshed", tint: .orange)
        }
    }

    // MARK: - Explainer

    private var explainer: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader("What's stored on device")
            row(icon: "checkmark.circle.fill", tint: .green,
                title: "Extracted text chunks",
                detail: "The searchable text from your screenshots and PDFs.")
            row(icon: "checkmark.circle.fill", tint: .green,
                title: "SHA-256 hashes",
                detail: "Used for deduplication and change detection.")
            Divider().padding(.vertical, 2)
            row(icon: "xmark.circle.fill", tint: .red,
                title: "Raw images & PDF bytes",
                detail: "Never copied into the index database.")
            row(icon: "xmark.circle.fill", tint: .red,
                title: "Anything off-device",
                detail: "No uploads, analytics, or telemetry.")
        }
        .lmkCard()
    }

    private func row(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon).foregroundStyle(tint).font(.body)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Danger zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader("Your data")
            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                if viewModel.isDeleting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Label("Delete Entire Index", systemImage: "trash.fill")
                }
            }
            .buttonStyle(SecondaryButtonStyle(tint: .red))
            .disabled(viewModel.isDeleting)
            .accessibilityLabel("Delete entire local index")
        }
        .confirmationDialog(
            "Delete the entire local index?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                Haptics.warning()
                Task { await viewModel.deleteAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all indexed files, chunks, and search data from this device. Your original screenshots and PDFs are not affected.")
        }
    }
}
