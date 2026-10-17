import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The injected `StatusLine` hook: `ingestEvent` hands a StatusLine payload to
/// the consumer's closure, and only that event type.
final class StatusLineIngestHookTests: XCTestCase {

    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var calls: [(sessionId: String, version: String, account: String)] = []

        func record(sessionId: String, hookData: [String: Any], account: String) {
            lock.lock(); defer { lock.unlock() }
            calls.append((sessionId, hookData["version"] as? String ?? "", account))
        }

        var all: [(sessionId: String, version: String, account: String)] {
            lock.lock(); defer { lock.unlock() }
            return calls
        }
    }

    func testOnlyAStatusLineEventReachesTheHook() throws {
        let recorder = Recorder()
        let (store, path) = try TestDaemonDatabase.makeSessionDatabase(
            statusLineIngest: { _, sessionId, hookData, _, account in
                recorder.record(sessionId: sessionId, hookData: hookData, account: account)
            }
        )
        defer { TestDaemonDatabase.remove(path: path) }

        try store.ingestEvent(
            eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
            hookData: ["session_id": "hook", "cwd": "/tmp"]
        )
        XCTAssertTrue(recorder.all.isEmpty, "a PreToolUse must not reach the StatusLine hook")

        try store.ingestEvent(
            eventType: "StatusLine", timestamp: "2026-06-01T12:01:00Z",
            hookData: ["session_id": "hook", "cwd": "/tmp", "version": "2.1.0"],
            accountEmail: "me@example.com"
        )
        XCTAssertEqual(recorder.all.count, 1)
        XCTAssertEqual(recorder.all.first?.sessionId, "hook")
        XCTAssertEqual(recorder.all.first?.version, "2.1.0")
        XCTAssertEqual(recorder.all.first?.account, "me@example.com")
    }
}
