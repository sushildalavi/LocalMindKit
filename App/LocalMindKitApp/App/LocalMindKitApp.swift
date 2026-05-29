import SwiftUI

@main
struct LocalMindKitApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
        }
    }
}
