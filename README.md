# LocalMindKit

LocalMindKit is a privacy-first iOS app that makes screenshots and imported PDFs searchable with on-device OCR, local indexing, and hybrid retrieval. Nothing leaves the device.

## Status

- Core package indexing and retrieval are implemented and host-tested.
- iOS SwiftUI app scaffold exists under `App/LocalMindKitApp`.
- Project generation for app target is configured with `project.yml` (XcodeGen).

## Known limitations

- Current environment is command-line-tools only, so iOS app target work requires full Xcode.
- MVP search path is keyword-first FTS5; semantic embeddings are deferred.

## Quick Start

```bash
swift build
swift test
brew install xcodegen
xcodegen generate
open LocalMindKit.xcodeproj
```
