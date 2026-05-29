# LocalMindKit

[![CI](https://github.com/sushildalavi/LocalMindKit/actions/workflows/ci.yml/badge.svg)](https://github.com/sushildalavi/LocalMindKit/actions/workflows/ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue.svg)
![No network](https://img.shields.io/badge/network-none%20(test--enforced)-success.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Privacy-first iOS search for screenshots and imported PDFs — fully on-device.**

LocalMindKit makes your screenshots and imported PDFs searchable by **text and
phrase queries**. It extracts text on-device (Vision OCR for images, PDFKit for
documents), indexes it locally with SQLite FTS5, and returns ranked, highlighted
results. There is no backend, no account, and no network call in the core
flows — nothing leaves the device.

> Scope note (kept deliberately honest): the current build is **text and phrase
> search**, not semantic / natural-language search. Local embeddings are the
> planned next phase and will only be described as "semantic" once they
> measurably improve retrieval quality on a labeled query set.

## Why this design

iOS sandboxing prevents arbitrary filesystem crawling, so LocalMindKit works
through user-approved sources — **PhotoKit** for screenshots/photos and the
**document picker** for imported PDFs/text. That constraint shaped the
architecture and makes the privacy model explicit rather than incidental.

The retrieval/indexing logic lives in a dependency-free Swift package
(`LocalMindKitCore`) that builds and unit-tests on the macOS host without a
simulator. The SwiftUI app is a thin shell on top of it.

## Architecture

```
SwiftUI app (PhotoKit source · document import · @Observable view models)
      │  IngestItem(externalID, kind, data | url, dates)
      ▼
IndexCoordinator (actor): bounded TaskGroup · cancellation · progress · skip-unchanged
   ├ OCRExtractor (Vision) ┐
   ├ PDFExtractor (PDFKit) ├→ Chunker (NaturalLanguage) → Database (actor, SQLite + FTS5)
   └ TextExtractor         ┘
QueryService → Ranker (keyword bm25 + recency + type; semantic = stubbed) ← Database
```

- **Persistence:** system SQLite + FTS5 via the C API (no third-party deps),
  behind a thin tested wrapper. Stores text **chunks** and SHA-256 hashes —
  never raw image/PDF bytes.
- **Retrieval:** FTS5 `MATCH` ordered by `bm25()`, with `snippet()`/`highlight()`
  for highlighted snippets. Hybrid-ready ranking (keyword + recency + type;
  semantic weight reserved for the embedding phase). Query terms are quoted and
  AND-ed before `MATCH` to avoid FTS operator injection.
- **Concurrency:** an actor coordinator runs extraction in a bounded task group
  with cancellation, progress reporting, and incremental skip-unchanged via
  content hash.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Privacy model (MVP)

- No backend, no API keys, **no network calls** in the core engine.
- Screenshot/PDF **text** is the index; **raw bytes are never stored** in the DB.
- Local SQLite index only; excluded from iCloud backup.
- **Delete-all** removes indexed files, chunks, and FTS rows; the privacy
  dashboard shows indexed item count, index size, and last-indexed time.
- The "no network" guarantee is **enforced by a test** (`NetworkAuditTests`)
  that fails the build if any networking symbol appears in `LocalMindKitCore`.

See [`docs/PRIVACY.md`](docs/PRIVACY.md).

## Status

- **Core engine:** implemented and host-tested — **18 passing XCTest cases**
  (FTS5 search, chunking, ranking, deduplication, deletion, incremental
  indexing, PDF/text extraction, query construction, and the network audit),
  plus 1 OCR test skipped (needs a runtime Vision call).
- **iOS app:** SwiftUI screens + view models + PhotoKit/document sources wired
  (`App/LocalMindKitApp`). **Pending device verification** — see limitations.

## Benchmarks

Host micro-benchmark (Apple M3, 16 GB, macOS 26.5, release build, in-memory
SQLite, 2,000 synthetic text docs / 2,000 chunks):

| Metric | Value |
|---|---|
| Keyword search latency p50 | ~1.3 ms |
| Keyword search latency p95 | ~1.4 ms |
| Indexing (chunk + FTS5 insert) | 2,000 files in 0.36 s |

**These are host engine numbers, not device numbers.** They show local FTS5
search is not the bottleneck. They **exclude OCR/PDF extraction** (the real
on-device cost), which is the subject of the planned device benchmark
(OCR ms/image, indexing throughput, memory, p95 search on persisted SQLite,
skip-unchanged re-index). See [`docs/BENCHMARKS.md`](docs/BENCHMARKS.md).

## Quick start

```bash
swift build
swift test          # 18 pass, 1 skipped (OCR)
```

Run the iOS app (requires full Xcode):

```bash
open LocalMindKit.xcodeproj
```

Regenerate the project from spec (optional):

```bash
brew install xcodegen && xcodegen generate
```

## Known limitations

- This dev environment is command-line-tools only (no Xcode/iOS SDK), so the
  iOS app target is not yet built/run on a simulator or device. UI is committed
  but not visually verified.
- Search is keyword-first FTS5; semantic embeddings are deferred to a later phase.
- Benchmarks are host-only so far; device OCR/indexing benchmarks are pending.

## Roadmap

1. Build and run the iOS app in Xcode; record a demo GIF (Photos permission →
   index screenshots → search → preview → privacy dashboard → delete index);
   add screenshots here.
2. Device benchmark: OCR ms/image, indexing throughput, memory, p50/p95 search
   over persisted SQLite, at 50/100/500 screenshots.
3. On-device semantic search (local embeddings) + true hybrid ranking; claim
   "semantic" only after measured Recall@5 / MRR improvement on a labeled set.
4. V1 privacy (per-item delete, album exclusions, cache-purge verification).
```
