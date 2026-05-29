# Tradeoffs

## SQLite plus FTS5

Chosen for explicit query-plan control and future vector storage support.

## Host-testable core

Business logic is isolated in a Swift package so indexing and retrieval are testable without an iOS simulator.

## Embeddings status

Semantic retrieval is deferred until measured improvements are demonstrated on a labeled evaluation set.

### Early viability note (Phase 0.5 spike)

- Initial intent remains to test `NLEmbedding.sentenceEmbedding(for: .english)` as a low-risk baseline.
- Integration is intentionally blocked until we have a labeled query set and can report Recall@5/MRR.
- No semantic-search wording should be used before that evaluation is complete.
