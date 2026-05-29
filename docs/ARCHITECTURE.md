# Architecture

- `LocalMindKitCore` contains indexing, persistence, extraction, and ranking.
- `LocalMindKitApp` will remain a thin SwiftUI shell over the core package.
- SQLite FTS5 powers the MVP text and phrase search flow.
