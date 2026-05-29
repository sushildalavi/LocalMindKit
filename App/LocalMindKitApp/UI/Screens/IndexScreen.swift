import SwiftUI
import Photos

struct IndexScreen: View {
    @Bindable var viewModel: IndexingViewModel
    @State private var stats: (files: Int, chunks: Int) = (0, 0)
    @State private var importing = false

    private var progress: Double {
        viewModel.total == 0 ? 0 : Double(viewModel.done) / Double(max(viewModel.total, 1))
    }
    private var isBusy: Bool { viewModel.state == .indexing }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        heroCard
                        if viewModel.photoAuthorization == .notDetermined || viewModel.photoAuthorization == .denied {
                            permissionBanner
                        }
                        actions
                        metrics
                        demoControls
                    }
                    .padding(Spacing.lg)
                    .animation(Animations.spring, value: viewModel.done)
                    .animation(Animations.spring, value: viewModel.state)
                }
            }
            .navigationTitle("Library")
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: DocumentImportSource.supportedTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Haptics.tap()
                    viewModel.ingestDocument(at: url)
                }
            }
            .task { stats = await viewModel.refreshStats() }
            .onChange(of: viewModel.state) { _, newValue in
                if newValue == .complete { Haptics.success() }
                Task { stats = await viewModel.refreshStats() }
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: Spacing.lg) {
            ProgressRing(progress: progress)
            VStack(spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    Circle().fill(stateColor).frame(width: 8, height: 8)
                    Text(stateLabel).font(Typography.section)
                }
                Text(viewModel.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if isBusy {
                    Text("\(viewModel.done) of \(viewModel.total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .lmkCard(padding: Spacing.xl)
    }

    private var stateColor: Color {
        switch viewModel.state {
        case .indexing: return .orange
        case .complete: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .idle: return .secondary
        }
    }
    private var stateLabel: String {
        switch viewModel.state {
        case .idle: return "Ready"
        case .indexing: return "Indexing…"
        case .complete: return "Up to date"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }

    // MARK: - Permission banner

    private var permissionBanner: some View {
        HStack(spacing: Spacing.md) {
            IconTile(symbol: "photo.on.rectangle.angled", tint: .orange, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("Allow Photos Access").font(.subheadline.weight(.semibold))
                Text("Needed to index your screenshots on-device.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Allow") {
                Haptics.tap()
                viewModel.requestPhotoAccess()
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .lmkCard(padding: Spacing.md)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            Button {
                Haptics.tap()
                viewModel.ingestScreenshots()
            } label: {
                Label(isBusy ? "Indexing…" : "Index Screenshots", systemImage: "photo.stack")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isBusy)

            Button {
                importing = true
            } label: {
                Label("Import Document", systemImage: "doc.badge.plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isBusy)

            if isBusy {
                Button(role: .cancel) {
                    Haptics.warning()
                    viewModel.cancel()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle(tint: .red))
            }
        }
    }

    // MARK: - Metrics

    private var metrics: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader("Index")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)],
                      spacing: Spacing.md) {
                MetricCard(symbol: "doc.text.fill", value: "\(stats.files)", label: "Files", tint: .blue)
                MetricCard(symbol: "text.quote", value: "\(stats.chunks)", label: "Chunks", tint: .teal)
                MetricCard(symbol: "photo.on.rectangle", value: permissionLabel(viewModel.photoAuthorization), label: "Photos", tint: .indigo)
                MetricCard(symbol: "bolt.fill", value: stateLabel, label: "Status", tint: .orange)
            }
        }
    }

    // MARK: - Demo

    private var demoControls: some View {
        HStack {
            Text("Developer")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Run Demo") {
                Haptics.tap()
                viewModel.startMockRun()
            }
            .font(.subheadline)
            .tint(AppTheme.accent)
            .disabled(isBusy)
        }
        .padding(.top, Spacing.xs)
    }

    private func permissionLabel(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Full"
        case .limited: return "Limited"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "—"
        @unknown default: return "Unknown"
        }
    }
}
