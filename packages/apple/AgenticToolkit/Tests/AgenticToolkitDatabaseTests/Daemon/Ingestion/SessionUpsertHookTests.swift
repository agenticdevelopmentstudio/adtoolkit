import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The injected post-upsert hook: called once per `sessions` upsert with the
/// session id, the event timestamp and the activity flag, inside the ingest
/// transaction.
final class SessionUpsertHookTests: XCTestCase {

    private struct Boom: Error {}

    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var items: [(String, String, Bool)] = []
        func record(_ id: String, _ stamp: String, _ activity: Bool) {
            lock.lock(); defer { lock.unlock() }
            items.append((id, stamp, activity))
        }
        var all: [(String, String, Bool)] {
            lock.lock(); defer { lock.unlock() }
            return items
        }
    }

    func testCalledOncePerUpsertWithTheRightArguments() throws {
        let recorder = Recorder()
        let (store, path) = try TestDaemonDatabase.makeSessionDatabase(
            sessionUpsertHook: { _, id, stamp, activity in recorder.record(id, stamp, activity) }
        )
        defer { TestDaemonDatabase.remove(path: path) }

        try store.ingestEvent(
            eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
            hookData: ["session_id": "h1", "cwd": "/tmp"]
        )
        let ambient = try XCTUnwrap(HookEventType.ambientEventTypes.sorted().first)
        try store.ingestEvent(
            eventType: ambient, timestamp: "2026-06-01T12:05:00Z",
            hookData: ["session_id": "h1", "cwd": "/tmp"]
        )

        let calls = recorder.all
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].0, "h1")
        XCTAssertEqual(calls[0].1, "2026-06-01T12:00:00Z")
        XCTAssertTrue(calls[0].2)
        XCTAssertEqual(calls[1].1, "2026-06-01T12:05:00Z")
        XCTAssertFalse(calls[1].2, "an ambient event is not activity")
    }

    func testAThrowingHookRollsTheIngestBack() throws {
        let (store, path) = try TestDaemonDatabase.makeSessionDatabase(
            sessionUpsertHook: { _, _, _, _ in throw Boom() }
        )
        defer { TestDaemonDatabase.remove(path: path) }

        XCTAssertThrowsError(try store.ingestEvent(
            eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
            hookData: ["session_id": "rb", "cwd": "/tmp"]
        ))
        XCTAssertNil(try store.fetchSession(sessionId: "rb"))
        XCTAssertEqual(try store.totalEventCount(), 0)
    }
}
