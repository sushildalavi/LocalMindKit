# Tradeoffs

## SQLite plus FTS5

Chosen for explicit query-plan control and future vector storage support.

## Host-testable core

Business logic is isolated in a Swift package so indexing and retrieval are testable without an iOS simulator.

## Embeddings status

Semantic retrieval is deferred until measured improvements are demonstrated on a labeled evaluation set.
