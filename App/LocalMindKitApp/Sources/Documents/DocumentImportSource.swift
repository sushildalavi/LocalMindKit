import Foundation
import UniformTypeIdentifiers
import LocalMindKitCore

struct DocumentImportSource {
    static let supportedTypes: [UTType] = [.pdf, .plainText, .text]

    func persistImportedFile(_ sourceURL: URL) throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = base.appendingPathComponent("LocalMindKit/Imported", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let destination = folder.appendingPathComponent(sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }

    func makeIngestItem(for persistedURL: URL) throws -> IngestItem {
        let values = try persistedURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
        let size = Int64(values.fileSize ?? 0)
        let ext = persistedURL.pathExtension.lowercased()
        let type: FileType = ext == "pdf" ? .pdf : .text

        return IngestItem(
            externalID: persistedURL.path,
            displayName: persistedURL.lastPathComponent,
            fileType: type,
            sizeBytes: size,
            url: persistedURL,
            createdAt: values.creationDate,
            modifiedAt: values.contentModificationDate
        )
    }
}
