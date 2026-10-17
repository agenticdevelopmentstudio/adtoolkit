import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import AIPluginKit

/// The oversight core: the subsystem gate, the `oversight_findings` store, the
/// live-fleet snapshot, and the `OversightService` tick (script observers + orphan
/// reconciliation). Per-script behavior lives in ScriptObserverTests.
final class OversightTests: XCTestCase {

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

    /// Seed a live (active) session whose status-line reports `usedPct`% of the context
    /// window consumed. Goes through the real ingest path so `session_metrics` is populated
    /// exactly as production does (remaining_percentage → context_used_pct).
    private func seedSession(_ id: String, usedPct: Int, windowSize: Int = 200_000) throws {
        try database.ingestEvent(
            eventType: "StatusLine",
            timestamp: iso8601(),
            hookData: [
                "session_id": id,
                "cwd": "/tmp/\(id)",
                "model": "sonnet",
                "context_window": [
                    "context_window_size": windowSize,
                    "remaining_percentage": Double(100 - usedPct)
                ]
            ]
        )
    }

    private func snapshot(_ id: String, pct: Int, window: Int = 200_000) -> LiveSessionSnapshot {
        LiveSessionSnapshot(
            sessionId: id, cwd: "/tmp/\(id)", status: "active", model: "sonnet",
            gitBranch: "", lastActivityAt: iso8601(), contextUsedPct: pct,
            contextWindowSize: window, termSessionId: ""
        )
    }

    private func runTask(enabled: Bool = true) async throws {
        if enabled { try database.setSetting("oversight_enabled", "true") }
        await OversightService.tick(
            database: database, makeObservers: { OversightService.defaultObservers(database: $0) }
        )
    }

    // MARK: - Subsystem gate (oversight_enabled)

    func testDisabledByDefault() {
        // A fresh DB never seeds oversight_enabled → the whole subsystem stays dark.
        XCTAssertFalse(Oversight.isEnabled(database))
    }

    func testEnabledWhenOptedInTrue() throws {
        try database.setSetting("oversight_enabled", "true")
        XCTAssertTrue(Oversight.isEnabled(database))
    }

    func testEnabledWhenOptedInOne() throws {
        try database.setSetting("oversight_enabled", "1")
        XCTAssertTrue(Oversight.isEnabled(database))
    }

    func testEnabledIsCaseInsensitive() throws {
        try database.setSetting("oversight_enabled", "TRUE")
        XCTAssertTrue(Oversight.isEnabled(database))
    }

    func testDisabledWhenExplicitlyFalse() throws {
        try database.setSetting("oversight_enabled", "false")
        XCTAssertFalse(Oversight.isEnabled(database))
    }

    func testDisabledWhenGarbage() throws {
        try database.setSetting("oversight_enabled", "maybe")
        XCTAssertFalse(Oversight.isEnabled(database), "only RawSetting's truthy words count as opt-in")
    }

    // MARK: - Threshold config

    func testDefaultThreshold() {
        XCTAssertEqual(Oversight.contextThresholdPct(database), Oversight.defaultContextThresholdPct)
        XCTAssertEqual(Oversight.defaultContextThresholdPct, 80)
    }

    func testCustomThreshold() throws {
        try database.setSetting("oversight_context_threshold_pct", "65")
        XCTAssertEqual(Oversight.contextThresholdPct(database), 65)
    }

    func testThresholdFallsBackWhenOutOfRange() throws {
        try database.setSetting("oversight_context_threshold_pct", "0")
        XCTAssertEqual(Oversight.contextThresholdPct(database), 80, "0 is out of 1...100 → default")
        try database.setSetting("oversight_context_threshold_pct", "150")
        XCTAssertEqual(Oversight.contextThresholdPct(database), 80, ">100 → default")
        try database.setSetting("oversight_context_threshold_pct", "notanumber")
        XCTAssertEqual(Oversight.contextThresholdPct(database), 80, "unparseable → default")
    }

    // MARK: - fetchLiveSessionsWithContext

    func testFetchLiveSessionsJoinsContextAndOrders() throws {
        try seedSession("low", usedPct: 20)
        try seedSession("high", usedPct: 88)
        let snapshots = try database.fetchLiveSessionsWithContext()
        XCTAssertEqual(snapshots.map(\.sessionId), ["high", "low"], "ordered by context pressure desc")
        XCTAssertEqual(snapshots.first?.contextUsedPct, 88)
        XCTAssertEqual(snapshots.first?.contextWindowSize, 200_000)
    }

    func testFetchLiveSessionsExcludesEnded() throws {
        try seedSession("live", usedPct: 88)
        try seedSession("done", usedPct: 88)
        try database.ingestEvent(
            eventType: "SessionEnd", timestamp: iso8601(),
            hookData: ["session_id": "done", "cwd": "/tmp/done"]
        )
        let ids = try database.fetchLiveSessionsWithContext().map(\.sessionId)
        XCTAssertEqual(ids, ["live"], "ended sessions are not part of the live fleet")
    }

    // MARK: - Findings store (upsert / reconcile / read)

    private func finding(_ session: String, severity: Int, reason: String = "r") -> SessionFinding {
        SessionFinding(
            sessionId: session, observer: "context", kind: "compact",
            severity: severity, source: .rule, reason: reason
        )
    }

    func testUpsertInsertsPending() throws {
        try database.upsertOversightFinding(finding("s1", severity: 85))
        let rows = try database.fetchOversightFindings()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.status, "pending")
        XCTAssertEqual(rows.first?.severity, 85)
        XCTAssertEqual(rows.first?.source, "rule")
    }

    func testUpsertUpdatesInPlaceKeepingPending() throws {
        try database.upsertOversightFinding(finding("s1", severity: 85, reason: "old"))
        try database.upsertOversightFinding(finding("s1", severity: 92, reason: "new"))
        let rows = try database.fetchOversightFindings()
        XCTAssertEqual(rows.count, 1, "same (session,observer,kind) refreshes, not duplicates")
        XCTAssertEqual(rows.first?.severity, 92)
        XCTAssertEqual(rows.first?.reason, "new")
        XCTAssertEqual(rows.first?.status, "pending", "acted/dismissed/pending preserved via ELSE branch")
    }

    func testStaleFindingRevivesOnRecurrence() throws {
        try database.upsertOversightFinding(finding("s1", severity: 85))
        // Reconcile with an empty keep-set → the pending finding goes stale.
        try database.markOversightFindingsResolved(observer: "context", exceptSessions: [])
        XCTAssertEqual(try database.fetchOversightFindings(status: "stale").count, 1)
        // Condition recurs → upsert revives it to pending.
        try database.upsertOversightFinding(finding("s1", severity: 88))
        let pending = try database.fetchOversightFindings(status: "pending")
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.severity, 88)
    }

    func testMarkResolvedStalesOnlyNonKept() throws {
        try database.upsertOversightFinding(finding("keep", severity: 85))
        try database.upsertOversightFinding(finding("drop", severity: 85))
        try database.markOversightFindingsResolved(observer: "context", exceptSessions: ["keep"])
        XCTAssertEqual(try database.fetchOversightFindings(status: "pending").map(\.sessionId), ["keep"])
        XCTAssertEqual(try database.fetchOversightFindings(status: "stale").map(\.sessionId), ["drop"])
    }

    func testMarkResolvedScopedToObserver() throws {
        try database.upsertOversightFinding(finding("s1", severity: 85))
        try database.upsertOversightFinding(
            SessionFinding(sessionId: "s1", observer: "other", kind: "compact",
                           severity: 70, source: .rule, reason: "r")
        )
        // Reconciling only "context" must leave the "other" observer's finding pending.
        try database.markOversightFindingsResolved(observer: "context", exceptSessions: [])
        let pending = try database.fetchOversightFindings(status: "pending")
        XCTAssertEqual(pending.map(\.observer), ["other"])
    }

    func testFetchOrdersBySeverityDesc() throws {
        try database.upsertOversightFinding(finding("low", severity: 70))
        try database.upsertOversightFinding(finding("high", severity: 95))
        let rows = try database.fetchOversightFindings()
        XCTAssertEqual(rows.map(\.sessionId), ["high", "low"])
    }

    func testFindingCountByStatus() throws {
        try database.upsertOversightFinding(finding("a", severity: 85))
        try database.upsertOversightFinding(finding("b", severity: 85))
        XCTAssertEqual(try database.oversightFindingCount(), 2)
        try database.markOversightFindingsResolved(observer: "context", exceptSessions: ["a"])
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 1)
        XCTAssertEqual(try database.oversightFindingCount(status: "stale"), 1)
    }

    // MARK: - OversightService (end-to-end tick)

    func testTaskWritesNothingWhenDisabled() async throws {
        try seedSession("hot", usedPct: 90)
        try await runTask(enabled: false)   // oversight_enabled never set
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 0)
    }

    func testTaskRecordsFindingForHotSession() async throws {
        try seedSession("hot", usedPct: 90)
        try seedSession("cool", usedPct: 30)
        try await runTask()
        let pending = try database.fetchOversightFindings(status: "pending")
        XCTAssertEqual(pending.map(\.sessionId), ["hot"])
        XCTAssertEqual(pending.first?.kind, "compact")
    }

    func testTaskReconcilesWhenContextDrops() async throws {
        try seedSession("s1", usedPct: 90)
        try await runTask()
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 1)

        // Context drops below threshold (e.g. the user compacted) → next tick stales it.
        try seedSession("s1", usedPct: 20)
        try await runTask()
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 0)
        XCTAssertEqual(try database.oversightFindingCount(status: "stale"), 1)
    }

    func testTaskStalesOrphanedObserverFindings() async throws {
        // A pending finding from an observer that no longer runs — the retired
        // "context" observer, or a deleted/disabled script — goes stale on the
        // next tick instead of lingering as pending forever.
        try database.upsertOversightFinding(
            SessionFinding(sessionId: "s-legacy", observer: "context", kind: "compact",
                           severity: 90, source: .rule, reason: "legacy")
        )
        try await runTask()
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 0)
        XCTAssertEqual(
            try database.fetchOversightFindings(status: "stale").map(\.observer), ["context"]
        )
    }

    func testTaskRunsDisabledScriptsNot() async throws {
        // Disable the shipped compact script: its findings stop AND its existing
        // pending finding goes stale via orphan reconciliation.
        try seedSession("hot", usedPct: 90)
        try await runTask()
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 1)

        var compact = try XCTUnwrap(ScriptStore.script(id: "compact", database: database))
        compact.enabled = false
        try ScriptStore.save(compact, database: database)

        try await runTask()
        XCTAssertEqual(try database.oversightFindingCount(status: "pending"), 0)
        XCTAssertEqual(try database.oversightFindingCount(status: "stale"), 1)
    }
}
