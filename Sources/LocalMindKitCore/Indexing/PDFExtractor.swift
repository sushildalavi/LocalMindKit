import Foundation
import PDFKit

/// Extracts selectable text from PDFs using PDFKit.
public struct PDFExtractor: Sendable {
  public init() {}

  public func extractText(from data: Data) -> String {
    guard let document = PDFDocument(data: data) else { return "" }
    return document.string ?? ""
  }

  public func extractText(from url: URL) -> String {
    guard let document = PDFDocument(url: url) else { return "" }
    return document.string ?? ""
  }
}
