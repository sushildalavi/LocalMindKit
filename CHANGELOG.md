# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims
to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once it
reaches a tagged release.

## [Unreleased]

### Added
- Opt-in **prefix search** (`SearchOptions.prefixMatch`) for as-you-type queries
  — only the trailing term becomes a prefix match, so multi-word queries stay
  precise.
- Database **maintenance ops**: `optimize()` (FTS5 optimize + `ANALYZE` + WAL
  checkpoint) and `vacuum()`.
- Database **stats** for the privacy dashboard: `indexSizeBytes()` and
  per-type `fileCounts()`.
- OCR **quality controls**: `minimumConfidence` and `minimumTextHeight` filters
  so low-confidence/noise text doesn't pollute the index.
- A tiny `Log` facade over `os.Logger` (no-op where `os` is unavailable);
  indexing failures are now logged instead of silently swallowed.
- Project hygiene: `.swift-format`, `.editorconfig`, `SECURITY.md`,
  `CODE_OF_CONDUCT.md`, `CHANGELOG.md`, a `Makefile`, Dependabot config, and
  issue templates.
- Expanded the XCTest suite (prefix search, oversize-sentence splitting, BOM
  handling, index stats, and SQL-level type filtering).

### Changed
- SQLite tuned with `busy_timeout`, `temp_store=MEMORY`, and a page cache pragma.
- File-type filtering is now applied in SQL (`f.file_type IN (...)`) instead of
  in Swift after over-fetching.
- Text decoding order made predictable: UTF-8 → Windows-1252 → Latin-1 (the bare
  UTF-16 attempt was dropped because it succeeds on almost any byte sequence).
- CI hardened: least-privilege permissions, concurrency cancellation, manual
  dispatch, and a pinned swift-format configuration.

### Fixed
- Chunker now **hard-splits a single oversize sentence** so code/URLs/OCR text
  with few sentence breaks can't produce one giant chunk.
- Text extractor strips a leading UTF-8 BOM that would otherwise pollute the
  first token and snippet.
- PDF extractor skips locked/encrypted documents instead of returning a partial
  or empty string ambiguously.

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
