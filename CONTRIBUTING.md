# Contributing

LocalMindKit is a personal portfolio project, but it is built to a production
bar and contributions / suggestions are welcome.

## Project layout

```
Sources/LocalMindKitCore/   Dependency-free engine (Domain, Persistence,
                            Indexing, Retrieval, Util). Builds + tests on host.
Tests/LocalMindKitCoreTests/  XCTest suite for the engine.
App/LocalMindKitApp/        Thin SwiftUI iOS app (requires full Xcode).
docs/                       Architecture, privacy, benchmarks, tradeoffs, etc.
```

## Development

The core engine has no third-party dependencies and runs on the macOS host
without Xcode:

```bash
swift build
swift test
```

The iOS app target requires full Xcode:

```bash
xcodegen generate   # optional: regenerate the project from project.yml
open LocalMindKit.xcodeproj
```

## Ground rules

- **No networking in `LocalMindKitCore`.** The privacy model depends on it and
  it is enforced by `NetworkAuditTests` — that test must stay green.
- **Store derived text, never raw bytes.** Persist chunks + SHA-256 hashes only.
- **Keep the engine UI-free.** Business logic lives in the core package, not in
  SwiftUI views.
- **Add a test with behavior changes.** The engine is fully host-testable.
- **Honest claims only.** Don't describe search as "semantic" until local
  embeddings measurably improve retrieval on a labeled query set.

## Commit style

Small, single-concern commits with short, lowercase messages.
