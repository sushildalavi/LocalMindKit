# Security Policy

## Threat model

LocalMindKit is an **on-device, offline** application. Its core engine
(`LocalMindKitCore`) performs no network I/O — this is enforced by
`NetworkAuditTests`, which fails the build if any networking symbol is linked
into the core target.

Because nothing leaves the device, the primary security properties we protect
are:

- **No data exfiltration.** The index is built and queried entirely locally.
  Raw image/PDF bytes are never persisted — only extracted text chunks and
  SHA-256 content hashes.
- **No injection via user input.** Search queries are tokenized and quoted
  before being passed to SQLite FTS5 `MATCH`, so a query cannot inject FTS
  operators or alter the query plan.
- **Local-only persistence.** The SQLite index lives in the app sandbox and is
  excluded from iCloud backup.

## Supported versions

This is a portfolio project under active development. Security fixes are applied
to `main` only.

## Reporting a vulnerability

If you discover a security issue, please **do not open a public issue**.
Instead, email the maintainer at the address on the GitHub profile, or use
GitHub's private vulnerability reporting ("Report a vulnerability" under the
Security tab).

Please include:

- a description of the issue and its impact,
- steps to reproduce (a failing test or minimal sample is ideal),
- any suggested remediation.

You can expect an initial acknowledgement within a few days.

## Scope

In scope:

- the `LocalMindKitCore` engine (persistence, retrieval, indexing),
- the SwiftUI app's handling of imported content and permissions.

Out of scope:

- issues that require a jailbroken device or physical access with the device
  unlocked,
- third-party platform/SDK vulnerabilities (report those upstream to Apple).
