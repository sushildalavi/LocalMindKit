import Foundation
import Vision
import CoreGraphics

/// On-device OCR via Apple's Vision framework. Runs the accurate text
/// recognizer over a CGImage and returns the concatenated text plus a
/// mean confidence. Works on iOS and macOS, so it is unit-testable on the host.
public struct OCRExtractor: Sendable {
    public init() {}

    public struct Result: Sendable {
        public let text: String
        public let confidence: Double
    }

    public func recognizeText(in image: CGImage, languages: [String] = ["en-US"]) throws -> Result {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return Result(text: "", confidence: 0)
        }

        var lines: [String] = []
        var confidenceSum: Float = 0
        var count = 0
        for obs in observations {
            guard let top = obs.topCandidates(1).first else { continue }
            lines.append(top.string)
            confidenceSum += top.confidence
            count += 1
        }
        let avg = count > 0 ? Double(confidenceSum) / Double(count) : 0
        return Result(text: lines.joined(separator: "\n"), confidence: avg)
    }
}
