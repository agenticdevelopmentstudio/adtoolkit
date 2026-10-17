import XCTest

/// Every file under `Database/Daemon` must open with
/// `#if canImport(AgenticToolkitCore)`: that guard is what keeps the daemon
/// tier out of the iOS slice, which compiles the directory anyway.
final class DaemonGuardTests: XCTestCase {

    func testEveryDaemonFileOpensWithTheCoreGuard() throws {
        let tests = URL(fileURLWithPath: #filePath)
        // .../AgenticToolkit/Tests/AgenticToolkitDatabaseTests/Daemon/<file>
        let root = tests.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let daemonDir = root.appendingPathComponent("Database/Daemon")
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(
            at: daemonDir, includingPropertiesForKeys: nil
        ))
        var checked = 0
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let code = try String(contentsOf: url, encoding: .utf8)
                .split(separator: "\n", omittingEmptySubsequences: true)
                .first { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return !trimmed.hasPrefix("//")
                }
            XCTAssertEqual(
                code?.trimmingCharacters(in: .whitespaces),
                "#if canImport(AgenticToolkitCore)",
                "\(url.lastPathComponent) must begin with the Core guard"
            )
            checked += 1
        }
        XCTAssertGreaterThan(checked, 0, "found no Daemon sources at \(daemonDir.path)")
    }
}
