import CoreGraphics
import Foundation
import ImageIO
import LocalMindKitCore

struct BenchConfig {
  var outputPath: String = ".benchmarks/latest.json"
  var dbPath: String = ".benchmarks/persisted-index.sqlite"
  var corpusSize: Int = 2000
  var queryRuns: Int = 200
  var ocrSamplesPath: String?
  var pdfSamplesPath: String?
  var mode: Mode = .run

  enum Mode: String {
    case run
    case updateDocs = "update-docs"
  }
}

struct BenchReport: Codable {
  struct Environment: Codable {
    let host: String
    let os: String
    let swift: String
    let timestampUTC: String
    let storageMode: String
    let datasetSize: Int
    let queryRuns: Int
  }

  struct MetricDistribution: Codable {
    let p50Ms: Double
    let p95Ms: Double
    let sampleCount: Int
  }

  struct Indexing: Codable {
    let firstPassTotalMs: Double
    let firstPassFilesPerSecond: Double
    let reindexSkipTotalMs: Double
    let reindexSkipFilesPerSecond: Double
  }

  struct Search: Codable {
    let keywordLatency: MetricDistribution
  }

  struct Storage: Codable {
    let sqliteBytes: Int64
    let sqliteMegabytes: Double
    let fileCount: Int
    let chunkCount: Int
  }

  struct OptionalExtraction: Codable {
    let ocrLatency: MetricDistribution?
    let pdfLatency: MetricDistribution?
  }

  let environment: Environment
  let indexing: Indexing
  let search: Search
  let storage: Storage
  let extraction: OptionalExtraction
}

@main
enum LocalMindKitBenchMain {
  static func main() async {
    do {
      let config = try parseArgs(CommandLine.arguments)
      switch config.mode {
      case .run:
        try await runBenchmarks(config: config)
      case .updateDocs:
        try updateBenchmarksDoc(from: config.outputPath)
      }
    } catch {
      fputs("error: \(error)\n", stderr)
      Foundation.exit(1)
    }
  }
}

private enum ArgError: Error, CustomStringConvertible {
  case invalidValue(String)
  case missingValue(String)

  var description: String {
    switch self {
    case .invalidValue(let m): return m
    case .missingValue(let m): return m
    }
  }
}

private func parseArgs(_ argv: [String]) throws -> BenchConfig {
  var config = BenchConfig()
  var i = 1
  while i < argv.count {
    let arg = argv[i]
    switch arg {
    case "--mode":
      let value = try nextValue(argv, i: &i, flag: arg)
      guard let mode = BenchConfig.Mode(rawValue: value) else {
        throw ArgError.invalidValue("unsupported mode: \(value)")
      }
      config.mode = mode
    case "--output":
      config.outputPath = try nextValue(argv, i: &i, flag: arg)
    case "--db-path":
      config.dbPath = try nextValue(argv, i: &i, flag: arg)
    case "--corpus-size":
      let value = try nextValue(argv, i: &i, flag: arg)
      guard let n = Int(value), n > 0 else {
        throw ArgError.invalidValue("--corpus-size must be a positive integer")
      }
      config.corpusSize = n
    case "--query-runs":
      let value = try nextValue(argv, i: &i, flag: arg)
      guard let n = Int(value), n > 0 else {
        throw ArgError.invalidValue("--query-runs must be a positive integer")
      }
      config.queryRuns = n
    case "--ocr-samples":
      config.ocrSamplesPath = try nextValue(argv, i: &i, flag: arg)
    case "--pdf-samples":
      config.pdfSamplesPath = try nextValue(argv, i: &i, flag: arg)
    case "--help":
      printUsageAndExit()
    default:
      throw ArgError.invalidValue("unknown arg: \(arg)")
    }
    i += 1
  }
  return config
}

private func nextValue(_ argv: [String], i: inout Int, flag: String) throws -> String {
  let next = i + 1
  guard next < argv.count else {
    throw ArgError.missingValue("missing value for \(flag)")
  }
  i = next
  return argv[next]
}

private func printUsageAndExit() -> Never {
  let usage = """
    LocalMindKitBench usage:
      swift run -c release LocalMindKitBench --mode run [options]
      swift run -c release LocalMindKitBench --mode update-docs --output <report.json>

    Options for --mode run:
      --output <path>         JSON output path (default: .benchmarks/latest.json)
      --db-path <path>        Persisted sqlite db path (default: .benchmarks/persisted-index.sqlite)
      --corpus-size <n>       Synthetic files to index (default: 2000)
      --query-runs <n>        Query latency samples (default: 200)
      --ocr-samples <dir>     Optional directory of image samples for OCR timing
      --pdf-samples <dir>     Optional directory of PDF samples for extraction timing
    """
  print(usage)
  Foundation.exit(0)
}

private func runBenchmarks(config: BenchConfig) async throws {
  let fm = FileManager.default
  try fm.createDirectory(atPath: ".benchmarks", withIntermediateDirectories: true)
  if fm.fileExists(atPath: config.dbPath) {
    try fm.removeItem(atPath: config.dbPath)
  }

  let db = try Database(path: config.dbPath)
  let coordinator = IndexCoordinator(db: db, chunker: .init(targetChars: 500, overlapChars: 50), maxConcurrent: 4)
  let queryService = QueryService(db: db)

  let corpus = syntheticCorpus(size: config.corpusSize)
  let firstPassMs = try await measureMs {
    _ = try await coordinator.index(items: corpus)
  }
  let reindexMs = try await measureMs {
    _ = try await coordinator.index(items: corpus)
  }

  let keywords = ["invoice", "design", "privacy", "benchmark", "swift", "report"]
  var querySamples: [Double] = []
  querySamples.reserveCapacity(config.queryRuns)
  for i in 0..<config.queryRuns {
    let q = keywords[i % keywords.count]
    let elapsed = try await measureMs {
      _ = try await queryService.search(q)
    }
    querySamples.append(elapsed)
  }

  let fileCount = try await db.fileCount()
  let chunkCount = try await db.chunkCount()
  let sqliteBytes = sqliteSizeBytes(dbPath: config.dbPath)
  let ocrDistribution = try measureOCRIfPresent(config.ocrSamplesPath)
  let pdfDistribution = try measurePDFIfPresent(config.pdfSamplesPath)

  let report = BenchReport(
    environment: .init(
      host: Host.current().localizedName ?? "Unknown",
      os: ProcessInfo.processInfo.operatingSystemVersionString,
      swift: swiftVersionString(),
      timestampUTC: iso8601UTC(Date()),
      storageMode: "persisted-sqlite",
      datasetSize: config.corpusSize,
      queryRuns: config.queryRuns
    ),
    indexing: .init(
      firstPassTotalMs: firstPassMs,
      firstPassFilesPerSecond: Double(config.corpusSize) / (firstPassMs / 1000.0),
      reindexSkipTotalMs: reindexMs,
      reindexSkipFilesPerSecond: Double(config.corpusSize) / (reindexMs / 1000.0)
    ),
    search: .init(keywordLatency: distribution(querySamples)),
    storage: .init(
      sqliteBytes: sqliteBytes,
      sqliteMegabytes: Double(sqliteBytes) / 1_048_576.0,
      fileCount: fileCount,
      chunkCount: chunkCount
    ),
    extraction: .init(ocrLatency: ocrDistribution, pdfLatency: pdfDistribution)
  )

  let outURL = URL(fileURLWithPath: config.outputPath)
  try FileManager.default.createDirectory(
    at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let data = try encoder.encode(report)
  try data.write(to: outURL)
  print("Wrote benchmark report: \(config.outputPath)")
}

private func updateBenchmarksDoc(from reportPath: String) throws {
  let reportURL = URL(fileURLWithPath: reportPath)
  let data = try Data(contentsOf: reportURL)
  let report = try JSONDecoder().decode(BenchReport.self, from: data)

  let docPath = "docs/BENCHMARKS.md"
  let doc = """
    # Benchmarks

    ## Environment (Last Automated Run)

    - Host: \(report.environment.host)
    - OS: \(report.environment.os)
    - Swift: \(report.environment.swift)
    - Timestamp (UTC): \(report.environment.timestampUTC)
    - Storage mode: \(report.environment.storageMode)
    - Dataset: \(report.environment.datasetSize) synthetic docs
    - Query runs: \(report.environment.queryRuns)

    ## Indexing

    - First pass total: \(fmt(report.indexing.firstPassTotalMs)) ms
    - First pass throughput: \(fmt(report.indexing.firstPassFilesPerSecond)) files/s
    - Re-index (skip unchanged) total: \(fmt(report.indexing.reindexSkipTotalMs)) ms
    - Re-index (skip unchanged) throughput: \(fmt(report.indexing.reindexSkipFilesPerSecond)) files/s

    ## Search

    - Keyword query latency p50: \(fmt(report.search.keywordLatency.p50Ms)) ms
    - Keyword query latency p95: \(fmt(report.search.keywordLatency.p95Ms)) ms
    - Query sample count: \(report.search.keywordLatency.sampleCount)

    ## Storage

    - Persisted SQLite size: \(report.storage.sqliteBytes) bytes (\(fmt(report.storage.sqliteMegabytes)) MB)
    - Indexed files: \(report.storage.fileCount)
    - Indexed chunks: \(report.storage.chunkCount)

    ## Optional Extraction Metrics

    - OCR p50/p95: \(extractionLine(report.extraction.ocrLatency))
    - PDF p50/p95: \(extractionLine(report.extraction.pdfLatency))

    ## Device Benchmark Checklist (Run on iPhone before external performance claims)

    - Run with representative screenshot corpus sizes (50/100/500).
    - Include OCR latency p50/p95 on physical device.
    - Include peak memory while indexing.
    - Include persisted-search latency p50/p95.
    - Include skip-unchanged re-index speedup.
    """
  try doc.write(toFile: docPath, atomically: true, encoding: .utf8)
  print("Updated benchmarks doc: \(docPath)")
}

private func extractionLine(_ dist: BenchReport.MetricDistribution?) -> String {
  guard let dist else { return "not provided (pass sample directory)" }
  return "\(fmt(dist.p50Ms)) / \(fmt(dist.p95Ms)) ms over \(dist.sampleCount) samples"
}

private func syntheticCorpus(size: Int) -> [IngestItem] {
  var items: [IngestItem] = []
  items.reserveCapacity(size)
  for i in 0..<size {
    let text = """
      Quarterly privacy report \(i). Swift indexing benchmark data and invoice details.
      Local search relevance for screenshots and PDFs using SQLite FTS5 and ranking.
      """
    let data = Data(text.utf8)
    items.append(
      IngestItem(
        externalID: "synthetic-\(i)",
        displayName: "doc-\(i).txt",
        fileType: .text,
        sizeBytes: Int64(data.count),
        data: data,
        createdAt: Date(),
        modifiedAt: Date()))
  }
  return items
}

private func measureOCRIfPresent(_ directory: String?) throws -> BenchReport.MetricDistribution? {
  guard let directory else { return nil }
  let urls = try sampleURLs(directory: directory, allowedExtensions: ["png", "jpg", "jpeg", "heic"])
  guard !urls.isEmpty else { return nil }
  let ocr = OCRExtractor()
  var times: [Double] = []
  for url in urls {
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    guard let image = makeCGImage(from: data) else { continue }
    let ms = try measureSyncMs {
      _ = try ocr.recognizeText(in: image)
    }
    times.append(ms)
  }
  return times.isEmpty ? nil : distribution(times)
}

private func measurePDFIfPresent(_ directory: String?) throws -> BenchReport.MetricDistribution? {
  guard let directory else { return nil }
  let urls = try sampleURLs(directory: directory, allowedExtensions: ["pdf"])
  guard !urls.isEmpty else { return nil }
  let pdf = PDFExtractor()
  var times: [Double] = []
  for url in urls {
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    let ms = try measureSyncMs {
      _ = pdf.extractText(from: data)
    }
    times.append(ms)
  }
  return distribution(times)
}

private func sampleURLs(directory: String, allowedExtensions: Set<String>) throws -> [URL] {
  let root = URL(fileURLWithPath: directory, isDirectory: true)
  let values = try FileManager.default.contentsOfDirectory(
    at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
  return values.filter { url in
    allowedExtensions.contains(url.pathExtension.lowercased())
  }
}

private func makeCGImage(from data: Data) -> CGImage? {
  guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
  return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

private func distribution(_ samples: [Double]) -> BenchReport.MetricDistribution {
  let sorted = samples.sorted()
  func percentile(_ p: Double) -> Double {
    if sorted.isEmpty { return 0 }
    let rank = Int(round((Double(sorted.count - 1)) * p))
    return sorted[max(0, min(sorted.count - 1, rank))]
  }
  return .init(p50Ms: percentile(0.50), p95Ms: percentile(0.95), sampleCount: sorted.count)
}

private func sqliteSizeBytes(dbPath: String) -> Int64 {
  let fm = FileManager.default
  let paths = [dbPath, "\(dbPath)-wal", "\(dbPath)-shm"]
  return paths.reduce(into: Int64(0)) { total, path in
    if let attrs = try? fm.attributesOfItem(atPath: path),
      let n = attrs[.size] as? NSNumber
    {
      total += n.int64Value
    }
  }
}

private func swiftVersionString() -> String {
  #if swift(>=6.0)
    return "6.x"
  #else
    return "5.x"
  #endif
}

private func iso8601UTC(_ date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}

private func fmt(_ value: Double) -> String {
  String(format: "%.2f", value)
}

private func measureSyncMs(_ block: () throws -> Void) throws -> Double {
  let start = DispatchTime.now().uptimeNanoseconds
  try block()
  let end = DispatchTime.now().uptimeNanoseconds
  return Double(end - start) / 1_000_000.0
}

private func measureMs(_ block: () async throws -> Void) async throws -> Double {
  let start = DispatchTime.now().uptimeNanoseconds
  try await block()
  let end = DispatchTime.now().uptimeNanoseconds
  return Double(end - start) / 1_000_000.0
}
