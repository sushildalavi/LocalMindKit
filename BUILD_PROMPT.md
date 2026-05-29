# BUILD PROMPT — LocalMindKit

> A complete, self-contained build specification. Any LLM-assisted coding tool
> should be able to read this file and know exactly what to build, in what
> order, with what constraints. Every technical claim here has been checked
> against current Apple APIs and the existing scaffold in this repo.

---

## Role

Act as a senior iOS/Swift engineer. Build the project below with minimal,
idiomatic diffs, strict scope discipline, and complete honesty. Never fabricate
benchmark numbers. Never call the search "semantic" or "natural-language" until
it is actually backed by embeddings AND measured on a labeled eval set.

## Product (one sentence — use this exact wording in README/resume/UI copy)

LocalMindKit is a privacy-first iOS app that makes screenshots and imported PDFs
searchable with on-device OCR, local indexing, and hybrid retrieval. Nothing
leaves the device.

## Why it exists

A portfolio project optimized to signal Apple-native engineering: Swift/SwiftUI
+ first-party Apple frameworks, on-device intelligence, privacy-first systems
design, performance engineering, and product polish.

---

## Hard rules (do not violate)

1. **iOS cannot crawl the filesystem.** The sandbox forbids it. Content sources
   are ONLY:
   - **PhotoKit** (screenshots/photos) → Vision OCR.
   - **Imported PDFs / text** via the document picker (`fileImporter`) → PDFKit.
   Design around this constraint on purpose; it is a feature of the story.
2. **Honest wording.** The MVP is **text and phrase search** (FTS5 keyword
   search over OCR/PDF text). Do NOT describe it as "semantic" or
   "natural-language search" anywhere until on-device embeddings demonstrably
   improve Recall@5 / MRR on a labeled query set (that work is Phase 7, NOT in
   this build).
3. **Store derived text, never raw bytes.** Persist text chunks (with character
   offsets) and a SHA-256 content hash per file. Never store the original image
   or PDF bytes in the index. This keeps the index privacy-honest and supports
   snippets + future re-embedding.
4. **No third-party dependencies.** Use the system SQLite library (which
   includes FTS5) directly via its C API. Rationale: smaller blast radius, full
   control over schema and query plans, no network fetch at build time, and it
   is more defensible in an interview than pulling a wrapper.
5. **Scope boundary — THIS BUILD = Phase 0 → Phase 5.5 only.** Do NOT implement
   semantic search / embeddings, WidgetKit, App Intents, audio transcription,
   BackgroundTasks/background OCR, or CoreSpotlight in this build. They are
   explicitly deferred.

---

## Architecture

- **`LocalMindKitCore`** — a Swift Package with NO UIKit/SwiftUI/PhotoKit
  dependency, so it compiles and unit-tests on the macOS host without an iOS
  simulator. It contains all indexing, persistence, and retrieval logic.
- **`LocalMindKitApp`** — a thin SwiftUI iOS app that depends on the core
  package. Only the app layer touches PhotoKit, the document picker, and UI.
  Views hold no business logic; they call `@Observable` view models which call
  the core.

```
SwiftUI app  (Photos source · Documents source · @Observable view models)
      │  produces IngestItem(externalID, kind, data | url, dates)
      ▼
IndexCoordinator (actor)
   bounded TaskGroup · cooperative cancellation · progress · skip-unchanged
   ├─ OCRExtractor   (Vision)   ┐
   ├─ PDFExtractor   (PDFKit)   ├─→ Chunker (NaturalLanguage) ─→ Database (actor)
   └─ TextExtractor  (plain)    ┘                                SQLite + FTS5
QueryService ─→ Ranker (keyword bm25 + recency + type; semantic = stub) ←─ Database
```

### Module map (matches files already in this repo)

```
Sources/LocalMindKitCore/
  Domain/Models.swift          FileType, ChunkSource, IndexStatus,
                               IndexedFile, Chunk, SearchResult, ScoreComponents
  Persistence/SQLite.swift     SQLiteConnection (thin C-API wrapper), SQLiteValue, Statement
  Persistence/Database.swift   actor Database — schema + FTS5 triggers, upsertFile,
                               insertChunks, existingHash, deleteFile, deleteAll,
                               fileCount, chunkCount, keywordSearch (bm25 + snippet)
  Util/Hashing.swift           Hashing.sha256(Data) -> hex (CryptoKit)
  Indexing/Chunker.swift       sentence-aware chunking (NLTokenizer, .sentence)
  Indexing/OCRExtractor.swift  Vision VNRecognizeTextRequest (.accurate)
  Retrieval/QueryService.swift FTS5 search → SearchResult, SearchOptions, RankWeights
  Retrieval/Ranker.swift       pure ranking math (keyword/recency/combine)
```

These files already exist — **extend them, do not recreate them.**

---

## Tech stack (all first-party, versions verified)

| Concern        | Choice                                             | Notes |
|----------------|----------------------------------------------------|-------|
| Language       | Swift 6, strict concurrency                        | repo built with Swift 6.3 |
| UI             | SwiftUI + Observation (`@Observable`)              | `@Observable` requires iOS 17+ |
| Concurrency    | async/await, `actor`, `withThrowingTaskGroup`      | |
| Persistence    | System SQLite + **FTS5** via C API (`import SQLite3`) | FTS5 is compiled into Apple's system SQLite |
| OCR            | **Vision** — `VNRecognizeTextRequest`, `.accurate` | on-device; works on iOS + macOS (host-testable) |
| PDF            | **PDFKit** — `PDFDocument().string`                | available on iOS + macOS |
| Text prep      | **NaturalLanguage** — `NLTokenizer(unit: .sentence)` | sentence-aware chunk boundaries |
| Photos         | **PhotoKit** — `PHPhotoLibrary`, `PHAsset`, `PHImageManager` | app layer only |
| Hashing        | **CryptoKit** — `SHA256`                           | dedup + change detection |
| Preview        | PDFKit (`PDFView`) / QuickLook (`QLPreviewController`) | |
| Embeddings (Phase 7, later) | `NLEmbedding.sentenceEmbedding`, optionally a Core ML model | NOT in this build |
| Tests          | XCTest (XCUITest later)                            | core tests run on macOS host |
| Min OS         | **iOS 17+**                                        | nothing in MVP needs an 18-only API |

---

## Storage schema (SQLite — already implemented in `Database.swift`)

```sql
CREATE TABLE files (
  id           INTEGER PRIMARY KEY,
  external_id  TEXT NOT NULL UNIQUE,   -- PHAsset.localIdentifier or file path
  display_name TEXT NOT NULL,
  file_type    TEXT NOT NULL,          -- image | pdf | text | code | audio | unknown
  size_bytes   INTEGER NOT NULL,
  content_hash TEXT NOT NULL,          -- SHA-256 hex of source bytes
  created_at   REAL, modified_at REAL, indexed_at REAL,
  status       TEXT NOT NULL           -- indexed | failed | skipped | unsupported
);
CREATE INDEX idx_files_hash ON files(content_hash);

CREATE TABLE chunks (
  id         INTEGER PRIMARY KEY,
  file_id    INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  ordinal    INTEGER NOT NULL,
  text       TEXT NOT NULL,
  char_start INTEGER NOT NULL, char_end INTEGER NOT NULL,
  source     TEXT NOT NULL              -- ocr | pdf | plaintext | transcript
);
CREATE INDEX idx_chunks_file ON chunks(file_id);

-- External-content FTS5 table so chunk text is not duplicated.
CREATE VIRTUAL TABLE chunks_fts USING fts5(
  text, content='chunks', content_rowid='id', tokenize='porter unicode61'
);
-- Triggers keep chunks_fts in sync (INSERT/DELETE/UPDATE), using the
-- 'delete' command form required by external-content FTS5 tables.

-- embeddings(chunk_id PK, dim, vector BLOB)  -- Phase 7 ONLY, not this build
```

- **Incremental re-index:** compare `(modified_at, size, content_hash)`. Use a
  cheap `existingHash(externalID:)` check before extraction; unchanged → skip,
  changed → re-extract (upsert deletes old chunks via cascade), missing → remove.
- **Dedup:** SHA-256 over the source bytes. Identical hash → index content once.
- **Foreign keys + WAL** are enabled via PRAGMA at connection open.

---

## Retrieval (already partly implemented in `QueryService.swift` / `Ranker.swift`)

- **Keyword (MVP path):** FTS5 `MATCH` over `chunks_fts`, ordered by `bm25()`.
  In SQLite FTS5, `bm25()` returns a value where **more negative = more
  relevant**, so `ORDER BY bm25(chunks_fts)` ascending yields the best matches
  first. Highlighted snippets come from the built-in `snippet(chunks_fts, 0,
  '[', ']', '…', 12)`.
- **Query construction:** split user input on whitespace, strip embedded double
  quotes, wrap each term in quotes, and AND the terms. This prevents the user
  from accidentally invoking FTS5 operators.
- **Hybrid ranking formula** (components normalized to 0–1, combined linearly):
  ```
  score = w_kw * normalizedKeyword(bm25)
        + w_sem * cosineSimilarity        // 0 in MVP (no embeddings yet)
        + w_rec * recencyDecay            // exp half-life decay, default 90 days
        + w_type * (typeBoost - 1)        // type boost centered on 1.0
  ```
  Default `RankWeights` in the scaffold: `keyword 0.6, semantic 0.0,
  recency 0.3, typeBoost 0.1`. `normalizedKeyword` maps `-bm25` through a
  logistic curve into 0–1. These are tunable and exposed for a future "why this
  matched" debug view.
- **Filters:** file-type and date filters are applied before ranking.

---

## Concurrency & performance

- `IndexCoordinator` is an `actor`; it enumerates `IngestItem`s and runs
  extraction inside a bounded `withThrowingTaskGroup`, capping concurrency at
  about `ProcessInfo.processInfo.activeProcessorCount`.
- **Cooperative cancellation** via `Task.isCancelled`; a user "Stop" cancels the
  group.
- **Progress** is reported as `(done, total, currentItem)` to an `@Observable`
  model; throttle UI updates (do not republish per item at high frequency).
- **PhotoKit OCR performance is a headline feature, not a hidden detail:**
  request **bounded-size** images from `PHImageManager` (never full-resolution
  unless needed), process in **batches**, **skip already-indexed assets** by
  hash, keep **memory bounded**, and support **cancel + progress**.
- **Batched DB writes:** insert chunks inside a single transaction per batch
  (the scaffold wraps `insertChunks` in BEGIN/COMMIT).
- **Search:** debounce input (~150 ms); cache recent query results.

---

## Privacy & security

- **No network calls in core flows** (provable; there are none in the core
  package). The index database lives in the app container.
- **MVP privacy dashboard** (privacy ships in the MVP — it is part of the Apple
  story): total indexed items, on-disk index size, last-indexed time,
  **delete-all index** (then verify the tables are empty), and an
  extracted-text preview for a selected result.
- Persist **chunks + hashes only**, never raw source bytes. No telemetry, no
  logging of extracted content.
- Document the threat model in `docs/PRIVACY.md`: "What leaves the device:
  nothing, by default."

---

## UX / product polish (Phase 5.5)

Fast, responsive search interactions; clean loading + progress UI; result cards
with screenshot/PDF preview; clearly-written privacy copy; SF Symbols; haptics
where appropriate; Dynamic Type; VoiceOver labels; dark mode; and real empty /
loading / error states. The bar: it should feel like an Apple app, not an
engineering demo.

---

## Repository layout (target)

```
Package.swift
Sources/LocalMindKitCore/{Domain,Persistence,Indexing,Retrieval,Util}
Tests/LocalMindKitCoreTests/
App/LocalMindKitApp/{App,UI,Sources(Photos,Documents)}
Benchmarks/        # host CLI / XCTest measure (Phase 9, later)
SampleData/        # committed sample corpus + labeled queries (Phase 9)
docs/              # ARCHITECTURE, PRIVACY, BENCHMARKS, TRADEOFFS, FAILURE_MODES
README.md
```

---

## Phases — implement in this order

### Phase 0 — Core builds & spike tests (host, no Xcode needed)
Add `Tests/LocalMindKitCoreTests/`:
- `FTS5SearchTests` — insert chunks, run a MATCH query, assert expected hits and
  a highlighted snippet (proves persistence + FTS5 end to end).
- `OCRSpikeTests` — render a `CGImage` containing known text with Core Graphics,
  run `OCRExtractor`, assert key strings are present (fuzzy match — OCR output
  varies; do not assert exact text).
- `ChunkerTests` — chunk boundary and overlap behavior.
- `RankerTests` — deterministic recency / keyword-normalization / combine math.
- `DedupTests` — re-upserting the same `externalID` replaces its chunks with no
  orphans.
- `DeletionTests` — `deleteAll()` leaves `files`, `chunks`, and `chunks_fts`
  empty.
Also add `Indexing/PDFExtractor.swift` (PDFKit) with a small fixture PDF.
**Done when:** `swift build` and `swift test` are green on the macOS host.

### Phase 0.5 — Embedding spike (de-risk the AI claim early)
A throwaway test only (no integration): embed a handful of chunks with
`NLEmbedding.sentenceEmbedding(for: .english)`, compute cosine similarity
against example queries (e.g. "screenshot where I saved the Apple job link"),
and eyeball whether results are meaningful. Write a short viability note in
`docs/TRADEOFFS.md`. This decides whether the later semantic phase is worth it.

### Phase 1 — Indexing pipeline (core)
Implement `IndexCoordinator` (actor): takes `IngestItem`s, runs a bounded
`TaskGroup`, supports cancellation, reports progress, skips unchanged items via
`existingHash`, and writes chunks in batches. Integration test: ingest a fixture
set; re-ingest touches only changed items; cancellation works; assert chunk
counts and search hits.

### Phase 2 — iOS app target (requires full Xcode)
Create `App/LocalMindKitApp/` (SwiftUI, iOS 17+) depending on the core package.
Screens: onboarding/permissions, search (bar + results + filters + preview),
indexing progress, privacy dashboard, settings. `@Observable` view models; no
business logic in views.

### Phase 3 — PhotoKit source (performance is a headline feature)
Handle `PHPhotoLibrary` authorization including the **limited library** case.
Enumerate screenshots first (the Screenshots smart album), then photos, keyed by
`PHAsset.localIdentifier`. Request bounded-size images, batch, show progress,
support cancellation, skip already-indexed assets, dedup by asset id + hash, and
keep memory bounded.

### Phase 4 — Document import (keep it simple)
`fileImporter` → access the picked URL during import → **copy the file into the
app container** → index it via the same PDFKit/text → FTS5 pipeline. Do NOT
build persistent security-scoped bookmarks (out of scope). Imported files
survive relaunch because they live in the container.

### Phase 5 — MVP ship gate + basic privacy dashboard
Highlighted snippets, PDFKit/QuickLook preview, empty/loading/error states, and
the MVP privacy dashboard described above. The full screenshot-OCR → search →
preview → delete-index flow works end to end.

### Phase 5.5 — Apple-native UX polish
Apply the polish list above. Tag an MVP release and record a demo GIF.

### Deferred (NOT this build)
- Phase 6: concurrency hardening; background OCR via `BGProcessingTask` (stretch).
- Phase 7: on-device embeddings + true hybrid ranking (`NLEmbedding` first, a
  converted Core ML sentence model only if eval justifies it; store Float32
  vector blobs; brute-force cosine with Accelerate/`vDSP`; "why this matched"
  panel). Only after this, and only if Recall@5/MRR improve on a labeled set,
  may the app be called "semantic / natural-language search."
- Phase 8: V1 privacy (per-item delete, album exclusions, cache-purge verify,
  full audit).
- Phase 9: benchmark harness + retrieval eval + docs (files/min, OCR ms/image,
  PDF ms/page, search p50/p95, index size, Recall@5 / MRR). Always report
  hardware specs. Never fabricate numbers — measure them.
- Phase 10: App Intents/Siri, CoreSpotlight donation, audio (Speech), iPad/widget.

---

## Interview-defensible decisions to preserve

- **SQLite + FTS5 over SwiftData/Core Data** — needed FTS5, query-plan control,
  and vector blobs later; SwiftData hides the query plan and lacks FTS5.
- **Local-first over cloud** — the data is personal files; on-device frameworks
  make local viable, so there is no reason to upload.
- **Host-testable core / thin iOS shell** — deterministic tests without the
  simulator; logic lives outside SwiftUI views.
- **Store chunks (offsets), not raw bytes** — privacy + snippets + re-embedding.
- **Brute-force cosine until a benchmark proves it slow** — no premature ANN.

---

## Definition of done (this build)

- `swift build` and `swift test` green on the macOS host (core engine + all
  Phase 0/1 tests).
- iOS app builds in Xcode and runs on a simulator: screenshots are OCR'd,
  searchable with highlighted snippets and preview, and delete-all clears the
  index.
- `README.md` with the honest wording, a demo GIF, and a "Known limitations"
  section.
- No fabricated metrics anywhere in code, docs, or commit messages.

---

## Environment notes (this machine)

- Installed: **Command Line Tools only** — Swift 6.3, no full Xcode, no iOS SDK.
- Consequence: the **core package builds and unit-tests on the macOS host today**
  (Vision, PDFKit, NaturalLanguage, CryptoKit, and system SQLite are all
  available on macOS). The **iOS app target and PhotoKit layer require full
  Xcode** (`xcode-select` to an Xcode install) to build and run on a simulator
  or device.
- Recommended sequence: complete and verify Phases 0, 0.5, and 1 on the host
  first; switch to Xcode at Phase 2.

## Start

Begin at Phase 0: get the core compiling and all Phase 0 tests green on the Mac
host. Report the exact commands run and their results, then proceed phase by
phase. Stop after Phase 5.5 (the MVP ship gate + polish) and summarize.
```
