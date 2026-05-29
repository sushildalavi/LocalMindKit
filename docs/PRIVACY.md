# Privacy

## Threat Model (MVP)

- Protect screenshot/document contents from backend exfiltration by design.
- Minimize retained data to search-necessary derivatives.
- Provide user-visible destructive controls (delete-all) for index reset.
- Enforce "no network in core engine" during CI through symbol audit tests.

## What Leaves the Device

Nothing in normal core flows. `LocalMindKitCore` contains no networking calls
and CI fails if networking symbols appear in the core target.

## Storage Model

- SQLite database stores:
  - file identity metadata (external ID, source kind, timestamps),
  - derived text chunks + offsets,
  - SHA-256 content hashes (dedup + skip-unchanged).
- SQLite FTS5 stores searchable tokens/snippets derived from chunk text.
- Raw source image/PDF bytes are not persisted in the core index database.

## No-Network Guarantee

- Technical guarantee applies to the core indexing/retrieval engine.
- Enforcement mechanism: `NetworkAuditTests` scans compiled symbols in CI and
  fails if disallowed networking APIs are introduced.
- Scope caveat: platform frameworks (for example, Photos permission prompts or
  iCloud device backup behavior) are outside core query execution paths.

## Deletion Semantics

- `deleteAll` removes file rows, chunk rows, and FTS rows.
- After deletion, query results should return empty and privacy metrics should
  reflect zero indexed items.
- Delete-all is index scoped; it does not remove originals from Photos/files.

## Backup Behavior

- Index storage is configured to be excluded from iCloud backup.
- Original assets follow user system settings (Photos/files), independent of
  LocalMindKit index retention.
