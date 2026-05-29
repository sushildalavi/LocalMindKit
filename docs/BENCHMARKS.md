# Benchmarks

## Environment (Last Automated Run)

- Host: Sushil’s MacBook Air
- OS: Version 26.5 (Build 25F71)
- Swift: 6.x
- Timestamp (UTC): 2026-05-29T18:08:29Z
- Storage mode: persisted-sqlite
- Dataset: 2000 synthetic docs
- Query runs: 300

## Indexing

- First pass total: 291.83 ms
- First pass throughput: 6853.32 files/s
- Re-index (skip unchanged) total: 33.77 ms
- Re-index (skip unchanged) throughput: 59216.49 files/s

## Search

- Keyword query latency p50: 1.66 ms
- Keyword query latency p95: 1.75 ms
- Query sample count: 300

## Storage

- Persisted SQLite size: 1880104 bytes (1.79 MB)
- Indexed files: 2000
- Indexed chunks: 2000

## Optional Extraction Metrics

- OCR p50/p95: 126.38 / 529.36 ms over 4 samples
- PDF p50/p95: not provided (pass sample directory)

## Device Benchmark Checklist (Run on iPhone before external performance claims)

- Run with representative screenshot corpus sizes (50/100/500).
- Include OCR latency p50/p95 on physical device.
- Include peak memory while indexing.
- Include persisted-search latency p50/p95.
- Include skip-unchanged re-index speedup.