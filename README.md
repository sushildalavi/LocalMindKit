# LocalMindKit

LocalMindKit is a privacy-first iOS app that makes screenshots and imported PDFs searchable with on-device OCR, local indexing, and hybrid retrieval. Nothing leaves the device.

## Status

Core package scaffolding, indexing pipeline foundation, and host tests are in progress.

## Known limitations

- Current environment is command-line-tools only, so iOS app target work requires full Xcode.
- MVP search path is keyword-first FTS5; semantic embeddings are deferred.
