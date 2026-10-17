import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// Phase 3 of AI-oversight: the daemon-side safety gate + act recorder that a human-approved
/// (and, later, autonomous) `/compact` injection funnels through. Exercises the idle gate
/// (only a `Stop`-ended session is actionable), the terminal target it hands back, and the
/// `pending → acted` transition — all via the injectable seams, no terminal driven.
final class OversightActionServiceTests: XCTestCase {

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

    /// Ingest one event for `id`, carrying the terminal fields so the session row gets a
    /// `term_program`/`term_session_id`/`pid` (the UPSERT only writes them when non-empty).
    @discardableResult
    private func ingest(
        _ id: String, eventType: String,
        termProgram: String = "iTerm.app", termSessionId: String = "w0t0p0:ABC-123", pid: Int = 4242
    ) throws -> String {
        try database.ingestEvent(
            eventType: eventType, timestamp: iso8601(),
            hookData: [
                "session_id": id, "cwd": "/tmp/\(id)", "model": "sonnet",
                "term_program": termProgram, "term_session_id": termSessionId, "pid": pid
            ]
        )
        return id
    }

    /// Create a pending finding for `id` and return its row id (the key the action APIs use).
    /// Defaults to the shipped compact script's namespace so `target()` resolves its action.
    private func seedFinding(
        _ id: String, observer: String = "compact", kind: String = "compact", severity: Int = 88
    ) throws -> Int {
        try database.upsertOversightFinding(
            SessionFinding(sessionId: id, observer: observer, kind: kind, severity: severity,
                           source: .rule, reason: "Context \(severity)% used")
        )
        let finding = try XCTUnwrap(
            try database.fetchOversightFindings().first { $0.sessionId == id && $0.kind == kind }
        )
        return finding.id
    }

    // MARK: - lastEventType

    func testLastEventTypeReflectsMostRecentEvent() throws {
        try ingest("s1", eventType: "UserPromptSubmit")
        try ingest("s1", eventType: "PreToolUse")
        try ingest("s1", eventType: "Stop")
        XCTAssertEqual(try database.lastEventType(sessionId: "s1"), "Stop")

        try ingest("s1", eventType: "PreToolUse")
        XCTAssertEqual(try database.lastEventType(sessionId: "s1"), "PreToolUse", "the newest event wins")
    }

    func testLastEventTypeEmptyForUnknownSession() throws {
        XCTAssertEqual(try database.lastEventType(sessionId: "nope"), "")
    }

    // MARK: - target: the safety gate

    func testActionableWhenIdleITermSession() throws {
        try ingest("hot", eventType: "Stop")
        let id = try seedFinding("hot")

        let target = OversightActionService.target(findingId: id, database: database)
        XCTAssertTrue(target.actionable)
        XCTAssertEqual(target.reason, "")
        XCTAssertEqual(target.sessionId, "hot")
        XCTAssertEqual(target.termProgram, "iTerm.app")
        XCTAssertEqual(target.termSessionId, "w0t0p0:ABC-123")
        XCTAssertEqual(target.pid, 4242)
        XCTAssertEqual(target.injectText, "/compact")
    }

    func testBlockedWhenMidResponse() throws {
        try ingest("busy", eventType: "Stop")
        try ingest("busy", eventType: "PreToolUse")  // now mid-response
        let id = try seedFinding("busy")

        let target = OversightActionService.target(findingId: id, database: database)
        XCTAssertFalse(target.actionable)
        XCTAssertTrue(target.reason.contains("mid-response"), target.reason)
    }

    func testBlockedWhenSessionEnded() throws {
        try ingest("gone", eventType: "Stop")
        try ingest("gone", eventType: "SessionEnd")  // flips status → ended
        let id = try seedFinding("gone")

        let target = OversightActionService.target(findingId: id, database: database)
        XCTAssertFalse(target.actionable)
        XCTAssertTrue(target.reason.contains("ended"), target.reason)
    }

    func testBlockedWhenScriptMissing() throws {
        // A legacy pre-scripts finding (the retired "context" observer) or one from a
        // deleted script: no script to resolve the action from → blocked.
        try ingest("legacy", eventType: "Stop")
        let id = try seedFinding("legacy", observer: "context")

        let target = OversightActionService.target(findingId: id, database: database)
        XCTAssertFalse(target.actionable)
        XCTAssertTrue(target.reason.contains("script"), target.reason)
    }

    func testBlockedForRecordOnlyScript() throws {
        let recordOnly = OversightScript(
            id: "watcher", name: "Watcher", enabled: true, builtIn: false, version: 1,
            trigger: ScriptTrigger(
                predicate: .condition(field: .sessionStatus, operation: .equals, value: "active")
            ),
            response: ScriptResponse(kind: "attention", reasonTemplate: "r", action: .none)
        )
        try ScriptStore.save(recordOnly, database: database)
        try ingest("watched", eventType: "Stop")
        let id = try seedFinding("watched", observer: "watcher", kind: "attention")

        let target = OversightActionService.target(findingId: id, database: database)
        XCTAssertFalse(target.actionable)
        XCTAssertTrue(target.reason.contains("without an action"), target.reason)
    }

    func testBlockedWhenFindingMissing() {
        let target = OversightActionService.target(findingId: 999_999, database: database)
        XCTAssertFalse(target.actionable)
        XCTAssertEqual(target.findingId, 999_999)
        XCTAssertTrue(target.reason.contains("no longer exists"), target.reason)
    }

    func testBlockedWhenAlreadyActed() throws {
        try ingest("done", eventType: "Stop")
        let id = try seedFinding("done")
        _ = OversightActionService.act(findingId: id, database: database)

        let target = OversightActionService.target(findingId: id, database: database)
        XCTAssertFalse(target.actionable)
        XCTAssertTrue(target.reason.contains("acted"), target.reason)
    }

    // MARK: - act: the record

    func testActMarksPendingFindingActed() throws {
        try ingest("act1", eventType: "Stop")
        let id = try seedFinding("act1")

        guard case .acted(let finding) = OversightActionService.act(findingId: id, database: database) else {
            return XCTFail("expected .acted")
        }
        XCTAssertEqual(finding.id, id)
        XCTAssertEqual(finding.status, "acted")
        // Persisted, so the list read reflects it too.
        let reread = try XCTUnwrap(try database.fetchOversightFinding(id: id))
        XCTAssertEqual(reread.status, "acted")
    }

    func testActIsIdempotentOnAnAlreadyActedFinding() throws {
        try ingest("act2", eventType: "Stop")
        let id = try seedFinding("act2")
        _ = OversightActionService.act(findingId: id, database: database)

        guard case .notPending(let status) = OversightActionService.act(findingId: id, database: database) else {
            return XCTFail("expected .notPending on the second act")
        }
        XCTAssertEqual(status, "acted")
    }

    func testActOnMissingFindingReturnsNotFound() {
        guard case .notFound = OversightActionService.act(findingId: 123_456, database: database) else {
            return XCTFail("expected .notFound")
        }
    }

    // MARK: - result serialization

    func testResultForActedIsOK() throws {
        try ingest("r1", eventType: "Stop")
        let id = try seedFinding("r1")
        let outcome = OversightActionService.act(findingId: id, database: database)
        let result = OversightActionService.result(for: outcome, findingId: id)
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.status, "acted")
    }

    func testResultForNotFoundIsNotOK() {
        let result = OversightActionService.result(for: .notFound, findingId: 7)
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.findingId, 7)
        XCTAssertTrue(result.reason.contains("not found"), result.reason)
    }
}
