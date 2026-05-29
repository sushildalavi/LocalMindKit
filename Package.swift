// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LocalMindKit",
  platforms: [
    // The app ships iOS 17+. macOS is declared so the core engine
    // builds and tests on the host without an iOS SDK / simulator.
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(name: "LocalMindKitCore", targets: ["LocalMindKitCore"]),
    .executable(name: "LocalMindKitBench", targets: ["LocalMindKitBench"]),
  ],
  targets: [
    .target(
      name: "LocalMindKitCore",
      // We talk to SQLite (incl. FTS5) directly via the system library.
      // No third-party dependencies on purpose: smaller blast radius,
      // full control over schema/query-plan, and easy to benchmark.
      linkerSettings: [
        .linkedLibrary("sqlite3")
      ]
    ),
    .testTarget(
      name: "LocalMindKitCoreTests",
      dependencies: ["LocalMindKitCore"]
    ),
    .executableTarget(
      name: "LocalMindKitBench",
      dependencies: ["LocalMindKitCore"]
    ),
  ]
)
