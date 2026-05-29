#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_PATH="${1:-.benchmarks/latest.json}"

if [[ ! -f "$REPORT_PATH" ]]; then
  echo "Benchmark report not found: $REPORT_PATH" >&2
  echo "Run scripts/run_benchmarks.sh first." >&2
  exit 1
fi

swift run -c release LocalMindKitBench \
  --mode update-docs \
  --output "$REPORT_PATH"

echo "Updated docs/BENCHMARKS.md from: $REPORT_PATH"
