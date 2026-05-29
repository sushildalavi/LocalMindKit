# Failure Modes

## OCR extraction returns no text
- Cause: low-quality image render, language mismatch, or Vision edge cases.
- Handling: return empty text, mark indexed file as successful but with zero chunks, keep app responsive.

## Corrupted or unsupported PDF
- Cause: encrypted PDF, malformed bytes, unsupported encoding.
- Handling: extractor returns empty text; indexing summary tracks failed/empty outcomes.

## SQLite write failure
- Cause: disk full, permission, or file-lock errors.
- Handling: transaction rollback, surface error message in UI, preserve prior index consistency.

## User cancels indexing
- Cause: stop action or app lifecycle interruption.
- Handling: cooperative cancellation in task groups, no partial transaction corruption.
