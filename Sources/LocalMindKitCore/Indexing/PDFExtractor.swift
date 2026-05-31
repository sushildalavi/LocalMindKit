import Foundation
import PDFKit

/// Extracts selectable text from PDFs using PDFKit.
public struct PDFExtractor: Sendable {
  public init() {}

  public func extractText(from data: Data) -> String {
    // A locked (encrypted, no password) PDF exposes no readable text layer.
    guard let document = PDFDocument(data: data), !document.isLocked else { return "" }
    return document.string ?? ""
  }

  public func extractText(from url: URL) -> String {
    guard let document = PDFDocument(url: url), !document.isLocked else { return "" }
    return document.string ?? ""
  }
}
