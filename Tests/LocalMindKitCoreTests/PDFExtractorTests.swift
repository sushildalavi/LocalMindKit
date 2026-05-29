import CoreGraphics
import CoreText
import Foundation
import XCTest
@testable import LocalMindKitCore

final class PDFExtractorTests: XCTestCase {
    func testExtractTextFromFixturePDFData() throws {
        let data = try makeFixturePDFData(text: "LocalMindKit PDF fixture text")
        let extracted = PDFExtractor().extractText(from: data).lowercased()
        XCTAssertTrue(extracted.contains("localmindkit"))
        XCTAssertTrue(extracted.contains("fixture"))
    }

    private func makeFixturePDFData(text: String) throws -> Data {
        let mutable = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutable as CFMutableData) else {
            throw NSError(domain: "PDFExtractorTests", code: 1)
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "PDFExtractorTests", code: 2)
        }

        ctx.beginPDFPage(nil)
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: mediaBox.height)
        ctx.scaleBy(x: 1.0, y: -1.0)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName("Helvetica" as CFString, 20, nil),
            .foregroundColor: CGColor(gray: 0.0, alpha: 1.0),
        ]
        let attr = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attr as CFAttributedString)
        ctx.textPosition = CGPoint(x: 72, y: 120)
        CTLineDraw(line, ctx)
        ctx.endPDFPage()
        ctx.closePDF()

        return mutable as Data
    }
}
