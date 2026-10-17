import XCTest
import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// Backstops the chunking contract:
/// - When a batch is full (deleted == batchSize), a pass reports `.rerun` so the
///   caller re-enqueues it at once. Without this, a multi-month backlog only drains
///   `batchSize` rows per check interval.
/// - When the backlog is drained (deleted < batchSize), it reports `.complete` so the
///   schedule falls back to the configured interval.
final class RetentionServiceTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    // MARK: - Helpers

    private func iso8601() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }

    private func ingestEvents(count: Int, sessionId: String = "ret-sess") throws {
        let sessionHook: [String: Any] = [
            "session_id": sessionId,
            "cwd": "/tmp",
            "model": "sonnet",
            "pid": 0,
            "term_program": "TestRunner"
        ]
        try database.ingestEvent(eventType: "SessionStart", timestamp: iso8601(), hookData: sessionHook)
        for _ in 0..<count {
            let hookData: [String: Any] = [
                "session_id": sessionId,
                "cwd": "/tmp",
                "tool_name": "Read",
                "tool_use_id": "tu-\(UUID().uuidString)",
                "tool_input": [String: Any]()
            ]
            try database.ingestEvent(eventType: "PreToolUse", timestamp: iso8601(), hookData: hookData)
        }
    }

    /// A pass with a zero-day window (every event is age-eligible) and the given
    /// ceiling. `nil` means no ceiling.
    private func runOnce(finalizedThrough: String? = nil) throws -> RetentionService.Outcome {
        try RetentionService(
            database: database, retentionDays: 0, finalizedThrough: { finalizedThrough }
        ).runOnce()
    }

    private static func utcDay(_ daysAgo: Int) -> String {
        UTCDay.string(from: Date().addingTimeInterval(-Double(daysAgo) * 86400))
    }

    /// Ingest a PreToolUse on a specific UTC day. `hour` lets today's events be
    /// stamped early so they're age-eligible even at a zero-day window.
    private func ingest(dayAgo: Int, hour: String = "12") throws {
        let day = Self.utcDay(dayAgo)
        let hook: [String: Any] = [
            "session_id": "ret-sess", "cwd": "/tmp", "tool_name": "Read",
            "tool_use_id": "tu-\(UUID().uuidString)", "tool_input": [String: Any]()
        ]
        try database.ingestEvent(eventType: "PreToolUse", timestamp: "\(day)T\(hour):00:01Z", hookData: hook)
    }

    private func eventDays() throws -> [String] {
        var days: [String] = []
        try database.query("""
            SELECT DISTINCT substr(timestamp, 1, 10) AS day FROM event_log ORDER BY day ASC
        """) { row in days.append(database.string(row, 0)) }
        return days
    }

    private func eventCount(sessionId: String) throws -> Int {
        var count = 0
        try database.query(
            "SELECT COUNT(*) FROM event_log WHERE session_id = ? AND event_type = 'PreToolUse'",
            params: [sessionId]
        ) { row in count = Int(database.int(row, 0)) }
        return count
    }

    // MARK: - Re-enqueue contract

    func testReEnqueuesWhenBatchFull() throws {
        // batchSize is 50 — ingest comfortably more so the first batch fills.
        try ingestEvents(count: 60)
        XCTAssertEqual(try runOnce(), .rerun, "full batch (deleted >= batchSize) must re-enqueue immediately")
    }

    func testReturnsCompleteWhenDrained() throws {
        // Fewer events than batchSize — one pass drains everything.
        try ingestEvents(count: 5)
        XCTAssertEqual(try runOnce(), .complete,
                       "drained backlog completes; the schedule falls back to its interval")
    }

    func testActuallyDrainsAcrossMultipleCalls() throws {
        // Ingest >2x batchSize so we need at least two full chunks + a tail.
        try ingestEvents(count: 120)

        var calls = 0
        while try runOnce() == .rerun {
            calls += 1
            XCTAssertLessThan(calls, 20, "must converge in bounded iterations")
        }
        XCTAssertEqual(try eventCount(sessionId: "ret-sess"), 0, "retention eventually deletes every eligible event")
    }

    // MARK: - Opt-in gating (retention_enabled)

    /// A fresh DB does NOT seed `retention_enabled`, so retention must stay disabled.
    func testDisabledByDefault() throws {
        XCTAssertFalse(RetentionService.isEnabled(database),
                       "retention must be OFF until the user opts in via retention_enabled")
    }

    func testEnabledWhenOptedInTrue() throws {
        try database.setSetting("retention_enabled", "true")
        XCTAssertTrue(RetentionService.isEnabled(database))
    }

    func testEnabledWhenOptedInOne() throws {
        try database.setSetting("retention_enabled", "1")
        XCTAssertTrue(RetentionService.isEnabled(database))
    }

    func testTruthyValueIsCaseInsensitive() throws {
        try database.setSetting("retention_enabled", "TRUE")
        XCTAssertTrue(RetentionService.isEnabled(database))
    }

    func testDisabledWhenExplicitlyFalse() throws {
        try database.setSetting("retention_enabled", "false")
        XCTAssertFalse(RetentionService.isEnabled(database))
    }

    func testDisabledWhenValueIsGarbage() throws {
        try database.setSetting("retention_enabled", "maybe")   // not a RawSetting truthy word
        XCTAssertFalse(RetentionService.isEnabled(database),
                       "only RawSetting's truthy words count as opt-in; anything else stays off")
    }

    // MARK: - Window

    func testRetentionDaysSettingOverridesTheFallback() throws {
        try database.setSetting("retention_days", "30")
        XCTAssertEqual(RetentionService.effectiveRetentionDays(database, fallback: 2), 30)
    }

    func testFallbackUsedWhenRetentionDaysIsNotAnInteger() throws {
        try database.setSetting("retention_days", "soon")
        XCTAssertEqual(RetentionService.effectiveRetentionDays(database, fallback: 2), 2)
    }

    func testDefaultWindowIsSevenDays() {
        XCTAssertEqual(RetentionService.defaultRetentionDays, 7)
    }

    // MARK: - Ceiling

    func testDoesNotDeletePastTheCeiling() throws {
        // Ceiling = yesterday: only days <= yesterday may be deleted, even though
        // today's event is also age-eligible (zero-day window).
        try ingest(dayAgo: 1, hour: "12")          // yesterday - under the ceiling, deletable
        try ingest(dayAgo: 0, hour: "00")          // today - above the ceiling, must survive

        _ = try runOnce(finalizedThrough: Self.utcDay(1))

        XCTAssertEqual(try eventDays(), [Self.utcDay(0)],
                       "deletion capped at the ceiling: yesterday gone, today retained")
    }

    func testNilCeilingMeansAgeAloneDecides() throws {
        try ingest(dayAgo: 1, hour: "12")
        try ingest(dayAgo: 0, hour: "00")

        XCTAssertEqual(try runOnce(finalizedThrough: nil), .complete)

        XCTAssertEqual(try eventDays(), [], "no ceiling: every row older than the window is deleted")
    }

    // MARK: - Empty-session reaping

    func testEndedSessionsWithNoEventsAreReaped() throws {
        try ingestEvents(count: 1, sessionId: "keeps-events")
        let hook: [String: Any] = ["session_id": "empty", "cwd": "/tmp", "model": "sonnet", "pid": 0]
        try database.ingestEvent(eventType: "SessionStart", timestamp: iso8601(), hookData: hook)
        database.updateSessionStatus(.ended, sessionId: "empty")
        try database.execute("DELETE FROM event_log WHERE session_id = ?", params: ["empty"])

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(), 1)
        XCTAssertNil(try database.fetchSession(sessionId: "empty"))
        XCTAssertNotNil(try database.fetchSession(sessionId: "keeps-events"))
    }
}
