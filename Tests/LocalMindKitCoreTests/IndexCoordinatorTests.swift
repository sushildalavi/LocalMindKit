import Foundation
import XCTest
@testable import LocalMindKitCore

private actor ProgressCollector {
    var events: [IndexProgress] = []
    func append(_ event: IndexProgress) { events.append(event) }
    func snapshot() -> [IndexProgress] { events }
}

final class IndexCoordinatorTests: XCTestCase {
    func testReindexSkipsUnchangedAndProcessesChangedItems() async throws {
        let db = try Database(path: ":memory:")
        let coordinator = IndexCoordinator(db: db, chunker: Chunker(targetChars: 32, overlapChars: 8), maxConcurrent: 2)

        let itemA1 = IngestItem(
            externalID: "a",
            displayName: "A.txt",
            fileType: .text,
            sizeBytes: 18,
            data: Data("hello apple world".utf8)
        )
        let itemB1 = IngestItem(
            externalID: "b",
            displayName: "B.txt",
            fileType: .text,
            sizeBytes: 18,
            data: Data("swift sqlite fts".utf8)
        )

        let first = try await coordinator.index(items: [itemA1, itemB1])
        XCTAssertEqual(first.indexed, 2)
        XCTAssertEqual(first.skipped, 0)
        XCTAssertEqual(first.failed, 0)

        let unchangedAndChanged = [
            itemA1,
            IngestItem(
                externalID: "b",
                displayName: "B.txt",
                fileType: .text,
                sizeBytes: 22,
                data: Data("swift sqlite fts updated".utf8)
            )
        ]
        let second = try await coordinator.index(items: unchangedAndChanged)
        XCTAssertEqual(second.indexed, 1)
        XCTAssertEqual(second.skipped, 1)
        XCTAssertEqual(second.failed, 0)

        let results = try await QueryService(db: db).search("updated")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.externalID, "b")
    }

    func testProgressReportsDoneTotalAndCurrentItem() async throws {
        let db = try Database(path: ":memory:")
        let coordinator = IndexCoordinator(db: db, maxConcurrent: 1)

        let items = [
            IngestItem(externalID: "1", displayName: "1.txt", fileType: .text, sizeBytes: 8, data: Data("alpha".utf8)),
            IngestItem(externalID: "2", displayName: "2.txt", fileType: .text, sizeBytes: 8, data: Data("beta".utf8)),
        ]

        let collector = ProgressCollector()
        _ = try await coordinator.index(items: items) { event in
            await collector.append(event)
        }
        let progressEvents = await collector.snapshot()

        XCTAssertEqual(progressEvents.count, 2)
        XCTAssertEqual(progressEvents.last?.done, 2)
        XCTAssertEqual(progressEvents.last?.total, 2)
        XCTAssertNotNil(progressEvents.last?.currentExternalID)
    }

    func testCancellationStopsBatch() async throws {
        let db = try Database(path: ":memory:")
        let coordinator = IndexCoordinator(db: db, maxConcurrent: 2)

        let payload = String(repeating: "localmindkit ", count: 8_000)
        let items = (0..<12).map { i in
            IngestItem(
                externalID: "c-\(i)",
                displayName: "C\(i).txt",
                fileType: .text,
                sizeBytes: Int64(payload.utf8.count),
                data: Data(payload.utf8)
            )
        }

        let task = Task { try await coordinator.index(items: items) }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation to throw")
        } catch is CancellationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected CancellationError, got: \(error)")
        }
    }
}
