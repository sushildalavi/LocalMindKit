import SwiftUI

struct SettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Haptic feedback", isOn: $viewModel.prefersHaptics)
                        .onChange(of: viewModel.prefersHaptics) { _, newValue in
                            Haptics.enabled = newValue
                        }
                    Toggle("Larger result cards", isOn: $viewModel.prefersLargeCards)
                } header: {
                    Text("Experience")
                } footer: {
                    Text("Preferences are stored on device.")
                }

                Section("About") {
                    LabeledContent("Version", value: "MVP")
                    LabeledContent("Search", value: "Text & phrase (FTS5)")
                    LabeledContent("On-device", value: "OCR · PDFKit · SQLite")
                    HStack {
                        Label("Network", systemImage: "wifi.slash")
                        Spacer()
                        Text("None").foregroundStyle(.green)
                    }
                }

                Section("Documentation") {
                    link("Architecture", "doc.text.magnifyingglass",
                         "https://github.com/sushildalavi/LocalMindKit/blob/main/docs/ARCHITECTURE.md")
                    link("Privacy model", "lock.shield",
                         "https://github.com/sushildalavi/LocalMindKit/blob/main/docs/PRIVACY.md")
                    link("Benchmarks", "speedometer",
                         "https://github.com/sushildalavi/LocalMindKit/blob/main/docs/BENCHMARKS.md")
                }

                if let error = viewModel.lastError {
                    Section("Diagnostics") {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { Haptics.enabled = viewModel.prefersHaptics }
        }
    }

    private func link(_ title: String, _ symbol: String, _ urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    Label(title, systemImage: symbol)
                }
            }
        }
    }
}
