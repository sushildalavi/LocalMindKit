import Foundation
import SQLite3

// SQLite wants to know whether a bound string/blob is transient (copy it)
// or static (don't). We always pass transient to be safe.
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public enum SQLiteError: Error, CustomStringConvertible {
  case open(String)
  case prepare(String)
  case step(String)
  case exec(String)

  public var description: String {
    switch self {
    case .open(let m): return "sqlite open failed: \(m)"
    case .prepare(let m): return "sqlite prepare failed: \(m)"
    case .step(let m): return "sqlite step failed: \(m)"
    case .exec(let m): return "sqlite exec failed: \(m)"
    }
  }
}

/// Thin, synchronous wrapper over the system SQLite C API.
///
/// Not thread-safe by itself — it is owned by `Database`, which is an actor,
/// so all access is already serialized. Keeping this layer dumb makes the
/// FTS5 / query-plan behaviour easy to reason about and benchmark.
final class SQLiteConnection {
  private var handle: OpaquePointer?

  init(path: String) throws {
    let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
    if sqlite3_open_v2(path, &handle, flags, nil) != SQLITE_OK {
      let msg = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
      throw SQLiteError.open(msg)
    }
    // Pragmas: WAL for concurrent reads during indexing, normal sync for speed.
    try exec("PRAGMA journal_mode=WAL;")
    try exec("PRAGMA synchronous=NORMAL;")
    try exec("PRAGMA foreign_keys=ON;")
    // Wait up to 5s for a lock instead of failing immediately. WAL lets readers
    // and a single writer coexist, but checkpoints and concurrent indexing can
    // still briefly contend; a busy timeout keeps those transient and retried.
    try exec("PRAGMA busy_timeout=5000;")
    // Keep temp B-trees (FTS sorts, ORDER BY) off disk for snappier queries.
    try exec("PRAGMA temp_store=MEMORY;")
    // ~8 MB page cache (negative = KiB). Cheap on-device, fewer page faults.
    try exec("PRAGMA cache_size=-8000;")
  }

  deinit { sqlite3_close_v2(handle) }

  var lastInsertRowID: Int64 { sqlite3_last_insert_rowid(handle) }

  func exec(_ sql: String) throws {
    var err: UnsafeMutablePointer<CChar>?
    if sqlite3_exec(handle, sql, nil, nil, &err) != SQLITE_OK {
      let msg = err.map { String(cString: $0) } ?? "unknown"
      sqlite3_free(err)
      throw SQLiteError.exec(msg)
    }
  }

  /// Run a statement with bound params and a row handler. Returns when done.
  func query(
    _ sql: String,
    params: [SQLiteValue] = [],
    row: (Statement) -> Void = { _ in }
  ) throws {
    let stmt = try prepare(sql, params: params)
    defer { sqlite3_finalize(stmt.raw) }
    while true {
      let rc = sqlite3_step(stmt.raw)
      if rc == SQLITE_ROW {
        row(stmt)
      } else if rc == SQLITE_DONE {
        break
      } else {
        throw SQLiteError.step(String(cString: sqlite3_errmsg(handle)))
      }
    }
  }

  /// Execute a write statement and return last insert rowid.
  @discardableResult
  func run(_ sql: String, params: [SQLiteValue] = []) throws -> Int64 {
    try query(sql, params: params)
    return lastInsertRowID
  }

  private func prepare(_ sql: String, params: [SQLiteValue]) throws -> Statement {
    var raw: OpaquePointer?
    if sqlite3_prepare_v2(handle, sql, -1, &raw, nil) != SQLITE_OK {
      throw SQLiteError.prepare(String(cString: sqlite3_errmsg(handle)))
    }
    guard let raw else { throw SQLiteError.prepare("nil statement") }
    let stmt = Statement(raw: raw)
    for (i, value) in params.enumerated() {
      value.bind(to: raw, at: Int32(i + 1))
    }
    return stmt
  }
}

/// A bindable parameter value.
enum SQLiteValue {
  case int(Int64)
  case double(Double)
  case text(String)
  case null

  func bind(to stmt: OpaquePointer, at index: Int32) {
    switch self {
    case .int(let v): sqlite3_bind_int64(stmt, index, v)
    case .double(let v): sqlite3_bind_double(stmt, index, v)
    case .text(let v): sqlite3_bind_text(stmt, index, v, -1, SQLITE_TRANSIENT)
    case .null: sqlite3_bind_null(stmt, index)
    }
  }
}

/// Typed column readers for a stepped row.
struct Statement {
  let raw: OpaquePointer

  func int(_ column: Int32) -> Int64 { sqlite3_column_int64(raw, column) }
  func double(_ column: Int32) -> Double { sqlite3_column_double(raw, column) }
  func string(_ column: Int32) -> String {
    guard let c = sqlite3_column_text(raw, column) else { return "" }
    return String(cString: c)
  }
  func isNull(_ column: Int32) -> Bool {
    sqlite3_column_type(raw, column) == SQLITE_NULL
  }
}
