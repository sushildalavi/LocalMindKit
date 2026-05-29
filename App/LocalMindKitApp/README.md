# LocalMindKitApp

iOS SwiftUI app layer for LocalMindKit.

## Build

1. Ensure Xcode is installed and selected.
2. Generate the Xcode project from `project.yml` with XcodeGen:
   - `brew install xcodegen`
   - `xcodegen generate`
3. Open `LocalMindKit.xcodeproj` and run `LocalMindKitApp` on an iOS 17+ simulator.

## Notes

- `LocalMindKitCore` remains host-testable via `swift test`.
- The app shell is intentionally thin; indexing and retrieval logic live in the core package.
