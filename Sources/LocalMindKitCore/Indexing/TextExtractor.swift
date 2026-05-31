import Foundation

/// Extracts plain text from raw bytes or file URLs.
public struct TextExtractor: Sendable {
  public init() {}

  public func extractText(from data: Data) -> String {
    guard !data.isEmpty else { return "" }
    return Self.stripBOM(Self.decode(data))
  }

  public func extractText(from url: URL) -> String {
    guard let data = try? Data(contentsOf: url) else { return "" }
    return extractText(from: data)
  }

  /// Try encodings most-likely-first. UTF-8 covers the vast majority; UTF-16
  /// (BOM-tagged) and the single-byte fallbacks keep older exports readable
  /// instead of silently dropping a file.
  private static func decode(_ data: Data) -> String {
    if let s = String(data: data, encoding: .utf8) { return s }
    if let s = String(data: data, encoding: .utf16) { return s }
    if let s = String(data: data, encoding: .windowsCP1252) { return s }
    if let s = String(data: data, encoding: .isoLatin1) { return s }
    return ""
  }

  /// Remove a leading Unicode BOM (U+FEFF). Swift's UTF-8 decoder keeps the
  /// BOM, which would otherwise pollute the first token and search snippet.
  private static func stripBOM(_ text: String) -> String {
    guard text.unicodeScalars.first == "\u{FEFF}" else { return text }
    return String(String.UnicodeScalarView(text.unicodeScalars.dropFirst()))
  }
}
