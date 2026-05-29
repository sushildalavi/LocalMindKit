# Architecture

LocalMindKit is split into a reusable Swift package (`LocalMindKitCore`) and an
iOS shell app (`LocalMindKitApp`).

## Module Responsibilities

- `LocalMindKitCore/Domain`: shared types (`IngestItem`, chunk metadata, query/results).
- `LocalMindKitCore/Indexing`: extraction and indexing orchestration.
- `LocalMindKitCore/Persistence`: SQLite wrapper, schema, and FTS5 operations.
- `LocalMindKitCore/Retrieval`: query construction and result ranking.
- `LocalMindKitApp`: SwiftUI screens, view models, and user-approved data sources.

## Data Flow (Ingest)

1. User grants access to Photos or imports a file via document picker.
2. App constructs `IngestItem` with stable external ID, kind, dates, and
   either in-memory bytes or file URL.
3. `IndexCoordinator` receives items and schedules bounded concurrent work.
4. Coordinator computes content hash and checks persistence for unchanged content.
5. Matching extractor (`OCRExtractor`, `PDFExtractor`, `TextExtractor`) derives text.
6. `Chunker` splits text into chunks with offsets.
7. `Database` upserts file row and chunk rows, then updates FTS5 index.

## Data Flow (Search)

1. User enters query text and optional filters.
2. `QueryService` normalizes terms, quotes tokens, and constructs an AND-ed
   `MATCH` expression for FTS5.
3. `Database` returns candidate rows with FTS rank + highlight/snippet support.
4. `Ranker` combines keyword score, recency, and source-type weighting.
5. App displays ranked results and full extracted text for selected item.

## Deletion and Privacy Flow

1. User triggers delete-all from privacy screen.
2. Core calls `Database.deleteAll()`.
3. Files/chunks/FTS rows are removed in one local operation.
4. Privacy dashboard refreshes counts and storage metrics.

## Concurrency Model

- `IndexCoordinator` is an `actor` to centralize cancellation, progress, and
  incremental indexing decisions.
- `Database` is an `actor` so SQLite access is serialized and safe.
- Extraction is scheduled with a bounded task group to avoid unbounded memory
  growth while still enabling overlap of expensive extraction tasks.

## Storage Model

- Primary tables: `files` metadata + `chunks` text segments.
- Full-text table: SQLite FTS5 external-content index over `chunks`.
- Stored: derived text, timestamps, source/type metadata, content hashes.
- Not stored: raw image/PDF bytes.
