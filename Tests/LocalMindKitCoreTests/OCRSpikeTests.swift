import CoreGraphics
import CoreText
import XCTest
@testable import LocalMindKitCore

final class OCRSpikeTests: XCTestCase {
    func testOCRExtractsKnownWordsFromRenderedImage() throws {
        let image = try XCTUnwrap(makeTestImage(text: "Apple LocalMindKit OCR Test"))
        let result = try OCRExtractor().recognizeText(in: image)
        let lower = result.text.lowercased()

        XCTAssertTrue(lower.contains("apple"))
        XCTAssertTrue(lower.contains("localmindkit") || lower.contains("local mind kit"))
    }

    private func makeTestImage(text: String) -> CGImage? {
        let width = 1200
        let height = 300
        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let ctx = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        ctx.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1.0, y: -1.0)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName("Helvetica" as CFString, 72, nil),
            .foregroundColor: CGColor(gray: 0.0, alpha: 1.0),
        ]
        let attr = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attr as CFAttributedString)

        ctx.textPosition = CGPoint(x: 40, y: 160)
        CTLineDraw(line, ctx)
        return ctx.makeImage()
    }
}
