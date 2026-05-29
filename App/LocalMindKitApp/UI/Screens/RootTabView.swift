import SwiftUI

struct RootTabView: View {
  @Environment(AppStore.self) private var store

  var body: some View {
    TabView {
      SearchScreen(viewModel: store.search)
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
      IndexScreen(viewModel: store.indexing)
        .tabItem { Label("Library", systemImage: "square.stack.3d.up.fill") }
      PrivacyScreen(viewModel: store.privacy)
        .tabItem { Label("Privacy", systemImage: "lock.shield.fill") }
      SettingsScreen(viewModel: store.settings)
        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
    }
    .tint(AppTheme.accent)
  }
}
