import Foundation

/// Extracts plain text from raw bytes or file URLs.
public struct TextExtractor: Sendable {
  public init() {}

  public func extractText(from data: Data) -> String {
    String(data: data, encoding: .utf8) ?? ""
  }

  public func extractText(from url: URL) -> String {
    (try? String(contentsOf: url, encoding: .utf8)) ?? ""
  }
}
