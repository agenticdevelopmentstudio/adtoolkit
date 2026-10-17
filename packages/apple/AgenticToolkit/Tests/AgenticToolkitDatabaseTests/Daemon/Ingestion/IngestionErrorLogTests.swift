import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The `ingestion_errors` table's lifecycle through the `DaemonDatabase`
/// methods: failing, exhausted, recovered and cleared.
final class IngestionErrorLogTests: XCTestCase {

    private var store: DaemonDatabase!
    private var path: String!

    override func setUpWithError() throws {
        (store, path) = try TestDaemonDatabase.makeSessionDatabase()
    }

    override func tearDownWithError() throws {
        store = nil
        TestDaemonDatabase.remove(path: path)
    }

    private func record(
        _ filename: String, quarantinedAt: String = "2026-01-01T00:00:00Z",
        retryCount: Int = 0, exhausted: Bool = false
    ) throws {
        try store.recordIngestionError(
            filename: filename, eventType: "PreToolUse", sessionId: "s-1", reason: "boom",
            sqliteCode: 19, quarantinedAt: quarantinedAt, retryCount: retryCount,
            lastRetriedAt: nil, exhausted: exhausted
        )
    }

    private func row(_ filename: String) throws -> IngestionErrorLogDTO {
        try XCTUnwrap(try store.recentIngestionErrors().first { $0.filename == filename })
    }

    func testAnUpsertKeepsTheFirstQuarantineTimeAndTracksTheLatestAttempt() throws {
        try record("a.json", quarantinedAt: "2026-01-01T00:00:00Z", retryCount: 0)
        try record("a.json", quarantinedAt: "2026-02-02T00:00:00Z", retryCount: 1)

        var entry = try row("a.json")
        XCTAssertEqual(entry.quarantinedAt, "2026-01-01T00:00:00Z")
        XCTAssertEqual(entry.retryCount, 1)
        XCTAssertEqual(entry.status, "failing")

        try record("a.json", retryCount: 3, exhausted: true)
        entry = try row("a.json")
        XCTAssertEqual(entry.retryCount, 3)
        XCTAssertEqual(entry.status, "exhausted")
        XCTAssertEqual(try store.recentIngestionErrors().count, 1)
    }

    func testResolveMarksTheRowRecoveredAndStampsResolvedAt() throws {
        try record("a.json")
        XCTAssertNil(try row("a.json").resolvedAt)

        try store.resolveIngestionError(filename: "a.json")

        let entry = try row("a.json")
        XCTAssertEqual(entry.status, "recovered")
        XCTAssertNotNil(entry.resolvedAt)
    }

    func testClearTouchesOnlyTheStillActiveRows() throws {
        try record("failing.json")
        try record("exhausted.json", retryCount: 3, exhausted: true)
        try record("done.json")
        try store.resolveIngestionError(filename: "done.json")

        try store.clearActiveIngestionErrors()

        XCTAssertEqual(try row("failing.json").status, "cleared")
        XCTAssertEqual(try row("exhausted.json").status, "cleared")
        XCTAssertNotNil(try row("failing.json").resolvedAt)
        XCTAssertEqual(try row("done.json").status, "recovered", "history is not rewritten")
    }

    func testALostEventIsATerminalResolvedRowThatClearLeavesAlone() throws {
        try store.recordLostIngestionEvent(filename: "empty.json", detectedAt: "2026-03-03T00:00:00Z")

        var entry = try row("empty.json")
        XCTAssertEqual(entry.status, "lost")
        XCTAssertEqual(entry.reason, "empty drop file — the event was lost before it was written")
        XCTAssertEqual(entry.quarantinedAt, "2026-03-03T00:00:00Z")
        XCTAssertEqual(entry.retryCount, 0)
        XCTAssertNotNil(entry.resolvedAt, "history, not an open problem")

        try store.clearActiveIngestionErrors()
        entry = try row("empty.json")
        XCTAssertEqual(entry.status, "lost")
    }

    func testAResolvedFilenameQuarantinedAgainTakesAFreshQuarantineTime() throws {
        try record("again.json", quarantinedAt: "2026-01-01T00:00:00Z")
        try store.resolveIngestionError(filename: "again.json")
        XCTAssertEqual(try row("again.json").status, "recovered")

        try record("again.json", quarantinedAt: "2026-05-05T00:00:00Z")

        let entry = try row("again.json")
        XCTAssertEqual(entry.status, "failing")
        XCTAssertEqual(entry.quarantinedAt, "2026-05-05T00:00:00Z")
        XCTAssertNil(entry.resolvedAt)
    }

    func testRecentReturnsTheNewestFirstAndHonoursTheLimit() throws {
        try record("old.json")
        try store.execute("UPDATE ingestion_errors SET updated_at = '2000-01-01 00:00:00'")
        try record("new.json")

        let newest = try store.recentIngestionErrors(limit: 1)
        XCTAssertEqual(newest.map(\.filename), ["new.json"])
        XCTAssertEqual(try store.recentIngestionErrors().count, 2)
    }
}
