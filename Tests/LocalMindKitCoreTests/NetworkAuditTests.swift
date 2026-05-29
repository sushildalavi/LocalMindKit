import XCTest

/// Privacy guard: the core engine must never make network calls. The whole
/// "nothing leaves the device" claim rests on this, so we enforce it as a test
/// rather than a promise — it scans the core sources for networking symbols and
/// fails the build if any are introduced.
final class NetworkAuditTests: XCTestCase {
    func testCoreHasNoNetworkingSymbols() throws {
        let coreDir = Self.coreSourcesDirectory()
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: coreDir, includingPropertiesForKeys: nil) else {
            return XCTFail("Could not enumerate \(coreDir.path)")
        }

        // Symbols that imply outbound networking. Their absence is the proof.
        let forbidden = [
            "URLSession", "URLRequest", "dataTask", "downloadTask", "uploadTask",
            "import Network", "NWConnection", "NWListener",
            "CFStream", "Socket(", "import CFNetwork",
        ]

        var offenders: [String] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let source = try String(contentsOf: url, encoding: .utf8)
            for symbol in forbidden where source.contains(symbol) {
                offenders.append("\(url.lastPathComponent): \(symbol)")
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "LocalMindKitCore must have no networking. Found: \(offenders.joined(separator: ", "))"
        )
    }

    /// Locate Sources/LocalMindKitCore relative to this test file.
    private static func coreSourcesDirectory() -> URL {
        // .../Tests/LocalMindKitCoreTests/NetworkAuditTests.swift
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // LocalMindKitCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("Sources/LocalMindKitCore", isDirectory: true)
    }
}
