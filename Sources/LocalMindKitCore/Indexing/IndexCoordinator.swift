import Foundation
import CoreGraphics
import ImageIO

public struct IndexProgress: Sendable {
    public var done: Int
    public var total: Int
    public var currentExternalID: String?

    public init(done: Int, total: Int, currentExternalID: String?) {
        self.done = done
        self.total = total
        self.currentExternalID = currentExternalID
    }
}

public struct IndexSummary: Sendable, Equatable {
    public var indexed: Int
    public var skipped: Int
    public var failed: Int

    public init(indexed: Int = 0, skipped: Int = 0, failed: Int = 0) {
        self.indexed = indexed
        self.skipped = skipped
        self.failed = failed
    }
}

public actor IndexCoordinator {
    private let db: Database
    private let chunker: Chunker
    private let ocr = OCRExtractor()
    private let pdf = PDFExtractor()
    private let textExtractor = TextExtractor()
    private let maxConcurrent: Int

    public init(
        db: Database,
        chunker: Chunker = .init(),
        maxConcurrent: Int = max(1, ProcessInfo.processInfo.activeProcessorCount)
    ) {
        self.db = db
        self.chunker = chunker
        self.maxConcurrent = maxConcurrent
    }

    public func index(
        items: [IngestItem],
        progress: (@Sendable (IndexProgress) async -> Void)? = nil
    ) async throws -> IndexSummary {
        if items.isEmpty { return .init() }

        var summary = IndexSummary()
        var done = 0

        try await withThrowingTaskGroup(of: IndexSummary.self) { group in
            var iterator = items.makeIterator()
            var inFlight = 0

            while inFlight < maxConcurrent, let item = iterator.next() {
                inFlight += 1
                group.addTask { try await self.indexSingle(item) }
            }

            while let result = try await group.next() {
                inFlight -= 1
                done += 1
                summary.indexed += result.indexed
                summary.skipped += result.skipped
                summary.failed += result.failed
                if let progress {
                    await progress(IndexProgress(done: done, total: items.count, currentExternalID: nil))
                }

                guard !Task.isCancelled else {
                    group.cancelAll()
                    throw CancellationError()
                }

                if let next = iterator.next() {
                    inFlight += 1
                    group.addTask { try await self.indexSingle(next) }
                }
            }
        }

        return summary
    }

    private func indexSingle(_ item: IngestItem) async throws -> IndexSummary {
        if Task.isCancelled { throw CancellationError() }
        do {
            let payload = try resolveData(for: item)
            let hash = Hashing.sha256(payload)
            if let existing = try await db.existingHash(externalID: item.externalID), existing == hash {
                return .init(indexed: 0, skipped: 1, failed: 0)
            }

            let extracted = try extractText(item: item, data: payload)
            let fileID = try await db.upsertFile(IndexedFile(
                externalID: item.externalID,
                displayName: item.displayName,
                fileType: item.fileType,
                sizeBytes: item.sizeBytes,
                contentHash: hash,
                createdAt: item.createdAt,
                modifiedAt: item.modifiedAt,
                indexedAt: Date(),
                status: .indexed
            ))
            let chunks = chunker.chunk(extracted, fileID: fileID, source: sourceForType(item.fileType))
            try await db.insertChunks(chunks)
            return .init(indexed: 1, skipped: 0, failed: 0)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            _ = try? await db.upsertFile(IndexedFile(
                externalID: item.externalID,
                displayName: item.displayName,
                fileType: item.fileType,
                sizeBytes: item.sizeBytes,
                contentHash: "",
                createdAt: item.createdAt,
                modifiedAt: item.modifiedAt,
                indexedAt: Date(),
                status: .failed
            ))
            return .init(indexed: 0, skipped: 0, failed: 1)
        }
    }

    private func resolveData(for item: IngestItem) throws -> Data {
        if let data = item.data { return data }
        if let url = item.url { return try Data(contentsOf: url) }
        return Data()
    }

    private func extractText(item: IngestItem, data: Data) throws -> String {
        switch item.fileType {
        case .image:
            guard let image = makeCGImage(from: data) else { return "" }
            return try ocr.recognizeText(in: image).text
        case .pdf:
            return pdf.extractText(from: data)
        case .text, .code:
            return textExtractor.extractText(from: data)
        case .audio, .unknown:
            return ""
        }
    }

    private func makeCGImage(from data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    private func sourceForType(_ type: FileType) -> ChunkSource {
        switch type {
        case .image: return .ocr
        case .pdf: return .pdf
        case .text, .code: return .plaintext
        case .audio: return .transcript
        case .unknown: return .plaintext
        }
    }
}
