# Failure Modes

## OCR extraction returns no text
- Cause: low-quality image render, language mismatch, or Vision edge cases.
- Handling: return empty text, keep indexing pipeline non-fatal, mark file as
  indexed with zero chunks, and surface "no text detected" status in UI/summary.

## Corrupted or unsupported PDF
- Cause: encrypted PDF, malformed bytes, unsupported encoding.
- Handling: extractor returns empty text or explicit extraction error;
  indexing summary tracks failed/empty outcomes without crashing batch.

## SQLite write failure
- Cause: disk full, permission, or file-lock errors.
- Handling: transaction rollback, preserve pre-existing index consistency, and
  surface retriable error in UI with actionable copy.

## User cancels indexing
- Cause: stop action or app lifecycle interruption.
- Handling: cooperative cancellation in task groups; completed writes remain
  valid, unfinished tasks stop early, and progress reports cancellation clearly.

## Duplicate / unchanged assets
- Cause: same screenshot/PDF re-ingested from source changes or re-sync.
- Handling: content hash check enables skip-unchanged; `upsertFile` replaces
  stale rows and cascades chunk/FTS cleanup on content change.

## Photos limited-access permission
- Cause: user grants limited library access or revokes access later.
- Handling: indexer only processes visible assets, shows reduced corpus counts,
  and prompts user to expand access when search quality degrades.

## Oversized import / memory pressure
- Cause: very large PDFs or many large images in one batch.
- Handling: bounded concurrency to cap active extraction tasks, cancellation
  support, and back-pressure via coordinator progress loop.
