#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_PATH="${1:-.benchmarks/latest.json}"
DB_PATH="${2:-.benchmarks/persisted-index.sqlite}"
CORPUS_SIZE="${3:-2000}"
QUERY_RUNS="${4:-200}"

swift run -c release LocalMindKitBench \
  --mode run \
  --output "$OUTPUT_PATH" \
  --db-path "$DB_PATH" \
  --corpus-size "$CORPUS_SIZE" \
  --query-runs "$QUERY_RUNS"

echo "Benchmark JSON written to: $OUTPUT_PATH"
