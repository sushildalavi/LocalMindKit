import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        TabView {
            SearchScreen(viewModel: store.search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            IndexScreen(viewModel: store.indexing)
                .tabItem { Label("Index", systemImage: "square.stack.3d.up") }
            PrivacyScreen(viewModel: store.privacy)
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
            SettingsScreen(viewModel: store.settings)
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(AppTheme.ocean)
    }
}
