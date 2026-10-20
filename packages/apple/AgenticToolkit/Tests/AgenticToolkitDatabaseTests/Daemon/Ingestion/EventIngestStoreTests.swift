import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// `ingestEvent` and its readers, through the `DaemonDatabase` methods: the
/// session row an event creates, the activity rule, the import dedup and the
/// newest-first recent read.
final class EventIngestStoreTests: XCTestCase {

    private var store: DaemonDatabase!
    private var path: String!

    override func setUpWithError() throws {
        (store, path) = try TestDaemonDatabase.makeSessionDatabase()
    }

    override func tearDownWithError() throws {
        store = nil
        TestDaemonDatabase.remove(path: path)
    }

    private func eventLogCount(sessionId: String) throws -> Int {
        var count = 0
        try store.query(
            "SELECT COUNT(*) FROM event_log WHERE session_id = ?", params: [sessionId]
        ) { count = store.int($0, 0) }
        return count
    }

    func testSessionStartCreatesTheSessionAndAPrecomputedDetailRow() throws {
        let hookData: [String: Any] = ["session_id": "s1", "cwd": "/tmp/myapp", "model": "sonnet"]
        try store.ingestEvent(
            eventType: "SessionStart", timestamp: "2026-06-01T12:00:00Z", hookData: hookData
        )

        let session = try XCTUnwrap(try store.fetchSession(sessionId: "s1"))
        XCTAssertEqual(session.status, "active")
        XCTAssertEqual(session.cwd, "/tmp/myapp")
        XCTAssertEqual(try eventLogCount(sessionId: "s1"), 1)
        let events = try store.fetchEvents(sessionId: "s1")
        XCTAssertEqual(
            events.first?.detail,
            computeDetail(eventType: "SessionStart", hookData: hookData)
        )
    }

    func testAnAmbientEventDoesNotMoveLastActivity() throws {
        let ambient = try XCTUnwrap(HookEventType.ambientEventTypes.sorted().first)
        try store.ingestEvent(
            eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
            hookData: ["session_id": "ambient", "cwd": "/tmp"]
        )
        try store.ingestEvent(
            eventType: ambient, timestamp: "2026-06-02T12:00:00Z",
            hookData: ["session_id": "ambient", "cwd": "/tmp"]
        )

        let session = try XCTUnwrap(try store.fetchSession(sessionId: "ambient"))
        XCTAssertEqual(session.lastActivityAt.prefix(10), "2026-06-01",
                       "\(ambient) must not move the clock, got \(session.lastActivityAt)")
    }

    func testImportingTheSameMessageTwiceKeepsOneRow() throws {
        func insert() throws -> Int64? {
            try store.insertImportedEvent(
                eventType: "assistant", timestamp: "2026-06-01T12:00:00Z", sessionId: "imp",
                cwd: "/tmp", detail: "{}", messageId: "msg-1"
            )
        }
        XCTAssertNotNil(try insert())
        XCTAssertNil(try insert(), "a duplicate message_id is skipped")
        XCTAssertEqual(try eventLogCount(sessionId: "imp"), 1)
    }

    func testFetchRecentEventsReturnsTheNewestFirst() throws {
        for (stamp, tool) in [("2026-06-01T12:00:00Z", "Read"), ("2026-06-01T12:05:00Z", "Edit")] {
            try store.ingestEvent(
                eventType: "PreToolUse", timestamp: stamp,
                hookData: ["session_id": "recent", "cwd": "/tmp", "tool_name": tool]
            )
        }

        let newest = try store.fetchRecentEvents(sessionId: "recent", limit: 1)
        XCTAssertEqual(newest.count, 1)
        XCTAssertEqual(newest.first?.timestamp, "2026-06-01T12:05:00Z")
        XCTAssertTrue(newest.first?.detail.hasPrefix("Edit") ?? false)
    }

    func testAToolResponseWithItsOwnIdIsStoredBesideTheRowId() throws {
        try store.ingestEvent(
            eventType: "PostToolUse", timestamp: "2026-10-19T00:25:08Z",
            hookData: [
                "session_id": "cron", "cwd": "/tmp", "tool_name": "CronCreate",
                "tool_input": ["id": "in-1", "cron": "7 10 25 10 *"],
                "tool_response": ["id": "e96a2840", "event_log_id": "bogus", "recurring": false]
            ]
        )

        XCTAssertEqual(try eventLogCount(sessionId: "cron"), 1)
        var responseId: String?
        var eventLogMatches = false
        try store.query(
            """
            SELECT r.payload_id, r.event_log_id = e.id FROM tool_responses r
            JOIN event_log e ON e.id = r.event_log_id WHERE e.session_id = ?
            """,
            params: ["cron"]
        ) { row in
            responseId = store.string(row, 0)
            eventLogMatches = store.int(row, 1) == 1
        }
        XCTAssertEqual(responseId, "e96a2840")
        XCTAssertTrue(eventLogMatches, "the payload's event_log_id must not replace the row's")
        var inputId: String?
        try store.query("SELECT payload_id FROM tool_inputs", params: []) { inputId = store.string($0, 0) }
        XCTAssertEqual(inputId, "in-1")
    }
}
