# LocalMindKit developer tasks.
# Run `make help` for the list.

.DEFAULT_GOAL := help
SHELL := /bin/bash

# Benchmark defaults (override on the command line, e.g. `make bench CORPUS=5000`).
BENCH_JSON ?= .benchmarks/latest.json
BENCH_DB   ?= .benchmarks/persisted-index.sqlite
CORPUS     ?= 2000
QUERY_RUNS ?= 200

.PHONY: help build test release lint format bench bench-doc clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Debug build of the package
	swift build

release: ## Release build of the package
	swift build -c release

test: ## Run the unit test suite
	swift test --parallel

lint: ## Check formatting (matches CI)
	swift-format lint --recursive --strict --configuration .swift-format Sources Tests

format: ## Apply formatting in place
	swift-format format --recursive --in-place --configuration .swift-format Sources Tests

bench: ## Run the persisted benchmark harness -> $(BENCH_JSON)
	bash scripts/run_benchmarks.sh "$(BENCH_JSON)" "$(BENCH_DB)" "$(CORPUS)" "$(QUERY_RUNS)"

bench-doc: ## Regenerate docs/BENCHMARKS.md from $(BENCH_JSON)
	bash scripts/update_benchmarks_doc.sh "$(BENCH_JSON)"

clean: ## Remove build artifacts
	swift package clean
	rm -rf .build
