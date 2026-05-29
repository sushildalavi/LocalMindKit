import SwiftUI

struct SettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                Form {
                    Section("Experience") {
                        Toggle("Use haptics", isOn: $viewModel.prefersHaptics)
                        Toggle("Use larger result cards", isOn: $viewModel.prefersLargeCards)
                    }

                    Section("About") {
                        LabeledContent("Version", value: "MVP")
                        LabeledContent("Search", value: "FTS5 keyword + ranking")
                        LabeledContent("Network", value: "Off for core flows")
                    }

                    if let error = viewModel.lastError {
                        Section("Diagnostics") {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
