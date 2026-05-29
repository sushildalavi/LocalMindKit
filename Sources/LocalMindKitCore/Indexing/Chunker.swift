import Foundation
import NaturalLanguage

/// Splits extracted text into overlapping, sentence-aware chunks.
///
/// We use NaturalLanguage for sentence segmentation rather than naive
/// fixed-width slicing so chunk boundaries fall on real sentence breaks —
/// this keeps snippets readable and embeddings semantically coherent.
public struct Chunker: Sendable {
    public var targetChars: Int
    public var overlapChars: Int

    public init(targetChars: Int = 800, overlapChars: Int = 100) {
        self.targetChars = targetChars
        self.overlapChars = overlapChars
    }

    public func chunk(_ text: String, fileID: Int64, source: ChunkSource) -> [Chunk] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Collect sentence ranges via NaturalLanguage.
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = trimmed
        var sentences: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: trimmed.startIndex..<trimmed.endIndex) { range, _ in
            sentences.append(range)
            return true
        }
        if sentences.isEmpty {
            sentences = [trimmed.startIndex..<trimmed.endIndex]
        }

        var chunks: [Chunk] = []
        var ordinal = 0
        var current = ""
        var currentStart: String.Index?

        func flush(end: String.Index) {
            guard let start = currentStart, !current.isEmpty else { return }
            let s = trimmed.distance(from: trimmed.startIndex, to: start)
            let e = trimmed.distance(from: trimmed.startIndex, to: end)
            chunks.append(Chunk(
                fileID: fileID,
                ordinal: ordinal,
                text: current.trimmingCharacters(in: .whitespacesAndNewlines),
                charStart: s,
                charEnd: e,
                source: source
            ))
            ordinal += 1
        }

        for range in sentences {
            let sentence = String(trimmed[range])
            if currentStart == nil { currentStart = range.lowerBound }
            current += sentence

            if current.count >= targetChars {
                flush(end: range.upperBound)
                // Start next chunk with a small overlap tail for context continuity.
                let tail = String(current.suffix(overlapChars))
                current = tail
                currentStart = range.upperBound
            }
        }
        flush(end: trimmed.endIndex)
        return chunks
    }
}
