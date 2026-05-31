# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims
to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once it
reaches a tagged release.

## [Unreleased]

### Added
- `.swift-format` configuration so formatting is deterministic and matches the
  CI lint job.
- `.editorconfig` for consistent whitespace across editors.
- `SECURITY.md`, `CODE_OF_CONDUCT.md`, and a `CHANGELOG.md`.
- `Makefile` with `build`, `test`, `format`, `lint`, and `bench` targets.
- Dependabot configuration for GitHub Actions updates.
- Issue templates for bug reports and feature requests.

### Changed
- _Pending._

### Fixed
- _Pending._

## History

The project began as an on-device, privacy-first search engine for screenshots
and imported PDFs:

- Dependency-free `LocalMindKitCore` Swift package (SQLite + FTS5) with
  host-runnable unit tests.
- Vision OCR / PDFKit / plain-text extraction pipeline behind an actor-based
  `IndexCoordinator` with bounded concurrency, cancellation, progress, and
  skip-unchanged incremental indexing.
- FTS5 keyword retrieval with `bm25()` ranking, recency/type boosts, and
  highlighted snippets.
- A test-enforced "no network" guarantee for the core engine.
- SwiftUI app with search, result detail, library/indexing, and privacy
  screens.
- Host micro-benchmark harness with JSON output and doc auto-update.
