import Foundation

#if canImport(os)
  import os

  /// Tiny logging facade over `os.Logger`. The core engine does no network I/O,
  /// so structured logs are the main runtime signal when an extraction or query
  /// misbehaves. Messages are developer strings (not user content) and are
  /// marked public so they survive release-build redaction; never pass file
  /// contents, OCR text, or query text through here.
  public enum Log {
    private static let logger = Logger(subsystem: "LocalMindKit", category: "core")

    public static func debug(_ message: @autoclosure () -> String) {
      let text = message()
      logger.debug("\(text, privacy: .public)")
    }

    public static func info(_ message: @autoclosure () -> String) {
      let text = message()
      logger.info("\(text, privacy: .public)")
    }

    public static func error(_ message: @autoclosure () -> String) {
      let text = message()
      logger.error("\(text, privacy: .public)")
    }
  }
#else
  /// No-op logger for platforms without `os` (e.g. Linux CI).
  public enum Log {
    public static func debug(_ message: @autoclosure () -> String) {}
    public static func info(_ message: @autoclosure () -> String) {}
    public static func error(_ message: @autoclosure () -> String) {}
  }
#endif
