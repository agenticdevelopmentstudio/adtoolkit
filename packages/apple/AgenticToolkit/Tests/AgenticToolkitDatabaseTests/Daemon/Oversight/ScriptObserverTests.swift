import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import AIPluginKit

/// One script as an observer: the deterministic rule path, the LLM-confirmation
/// path (act / wait / unavailable), the `oversight_llm_enabled` double gate, and
/// the per-tick budget shared across scripts.
final class ScriptObserverTests: XCTestCase {

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

    private func iso8601() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }

    private func snapshot(_ id: String, pct: Int, window: Int = 200_000) -> LiveSessionSnapshot {
        LiveSessionSnapshot(
            sessionId: id, cwd: "/tmp/\(id)", status: "active", model: "sonnet",
            gitBranch: "", lastActivityAt: iso8601(), contextUsedPct: pct,
            contextWindowSize: window, termSessionId: ""
        )
    }

    private func observer(
        script: OversightScript = ShippedScripts.compact(),
        budget: LLMTickBudget = LLMTickBudget(Oversight.maxLLMEvaluationsPerTick),
        reply: String? = nil
    ) -> ScriptObserver {
        guard let reply else { return ScriptObserver(script: script, budget: budget) }
        return ScriptObserver(
            script: script, budget: budget,
            analyzer: ScriptAnalyzer(chat: { _, _, _, _ in reply })
        )
    }

    // MARK: - Rule path (LLM off)

    func testFiresAtTokensThresholdAndNotBelow() async {
        // 40% of 200k = 80k ≥ 70k fires; 30% = 60k doesn't.
        let findings = await observer().observe(
            sessions: [snapshot("hot", pct: 40), snapshot("cool", pct: 30)],
            database: database
        )
        XCTAssertEqual(findings.map(\.sessionId), ["hot"])
        let finding = findings[0]
        XCTAssertEqual(finding.observer, "compact", "findings are namespaced by the script id")
        XCTAssertEqual(finding.kind, "compact")
        XCTAssertEqual(finding.source, .rule)
        XCTAssertEqual(finding.severity, 40)
        XCTAssertEqual(finding.reason, "Context 40% used — compact at a clean breakpoint",
                       "the reason template renders live values")
    }

    func testDisabledScriptReportsDisabled() {
        var script = ShippedScripts.compact()
        script.enabled = false
        XCTAssertFalse(observer(script: script).isEnabled(database))
    }

    func testCustomScriptFieldsFlowIntoFinding() async {
        let script = OversightScript(
            id: "stop-watch", name: "Stop watcher", enabled: true, builtIn: false, version: 1,
            trigger: ScriptTrigger(
                predicate: .condition(field: .sessionStatus, operation: .equals, value: "active")
            ),
            response: ScriptResponse(kind: "attention", reasonTemplate: "active session", action: .none)
        )
        let findings = await observer(script: script).observe(
            sessions: [snapshot("s", pct: 5)], database: database
        )
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings[0].observer, "stop-watch")
        XCTAssertEqual(findings[0].kind, "attention")
    }

    // MARK: - LLM confirmation path

    func testLLMActVerdictProducesLLMFinding() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let findings = await observer(reply: "COMPACT: clean pause")
            .observe(sessions: [snapshot("s", pct: 90)], database: database)
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings[0].source, .llm)
        XCTAssertEqual(findings[0].reason, "clean pause")
        XCTAssertEqual(findings[0].model, "claude-cli", "no provider configured → CLI label")
    }

    func testLLMWaitVerdictProducesNoFinding() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let findings = await observer(reply: "WAIT: mid-edit")
            .observe(sessions: [snapshot("s", pct: 95)], database: database)
        XCTAssertTrue(findings.isEmpty, "the model said not now → no finding")
    }

    func testLLMUnavailableFallsBackToRule() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let failing = ScriptObserver(
            script: ShippedScripts.compact(),
            budget: LLMTickBudget(4),
            analyzer: ScriptAnalyzer(chat: { _, _, _, _ in
                throw DaemonAIChat.ChatError.providerError("model down")
            })
        )
        let findings = await failing.observe(sessions: [snapshot("s", pct: 90)], database: database)
        XCTAssertEqual(findings.map(\.source), [.rule], "an unreachable model degrades to the rule")
    }

    func testLLMDisabledSkipsConfirmationEntirely() async {
        // oversight_llm_enabled unset → the analyzer is never consulted, the match stands.
        let findings = await observer(reply: "WAIT: should be ignored")
            .observe(sessions: [snapshot("s", pct: 90)], database: database)
        XCTAssertEqual(findings.map(\.source), [.rule])
    }

    // MARK: - Shared budget

    func testBudgetIsSharedAcrossScripts() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let budget = LLMTickBudget(1)
        let calls = CallCounter()
        let analyzer = ScriptAnalyzer(chat: { _, _, _, _ in
            calls.increment()
            return "WAIT: not now"
        })

        var second = ShippedScripts.compact()
        second.id = "compact-2"
        let first = ScriptObserver(script: ShippedScripts.compact(), budget: budget, analyzer: analyzer)
        let other = ScriptObserver(script: second, budget: budget, analyzer: analyzer)

        let sessions = [snapshot("s", pct: 90)]
        let firstFindings = await first.observe(sessions: sessions, database: database)
        let secondFindings = await other.observe(sessions: sessions, database: database)

        XCTAssertEqual(calls.count, 1, "one shared budget slot → exactly one model call across scripts")
        XCTAssertTrue(firstFindings.isEmpty, "the budgeted evaluation said WAIT")
        XCTAssertEqual(secondFindings.map(\.source), [.rule],
                       "beyond the shared budget → deterministic rule, not another model call")
    }

    func testBudgetOverflowWithinOneScriptFallsBackToRule() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let extra = 2
        let budget = LLMTickBudget(Oversight.maxLLMEvaluationsPerTick)
        let candidates = (0..<(Oversight.maxLLMEvaluationsPerTick + extra)).map { snapshot("s\($0)", pct: 90) }
        let findings = await observer(budget: budget, reply: "WAIT: not now")
            .observe(sessions: candidates, database: database)
        XCTAssertEqual(findings.count, extra, "only overflow candidates (rule) yield findings")
        XCTAssertTrue(findings.allSatisfy { $0.source == .rule })
    }

    // MARK: - Guard refusal halts the tick's LLM calls

    /// A guard refusal is terminal for the tick (mirrors SummarizeTask's halt): the
    /// first `AIGuardError` drains the shared budget, so the remaining candidates
    /// degrade to the rule WITHOUT calling the model — at most one guard row per tick.
    func testGuardRefusalHaltsLLMCallsForRestOfTick() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let calls = CallCounter()
        let refusing = ScriptObserver(
            script: ShippedScripts.compact(),
            budget: LLMTickBudget(Oversight.maxLLMEvaluationsPerTick),
            analyzer: ScriptAnalyzer(chat: { _, _, _, _ in
                calls.increment()
                throw AIGuardError.blocked("model over budget")
            })
        )
        let candidates = [snapshot("s1", pct: 90), snapshot("s2", pct: 91), snapshot("s3", pct: 92)]
        let findings = await refusing.observe(sessions: candidates, database: database)

        XCTAssertEqual(calls.count, 1, "the first refusal must stop further model calls this tick")
        XCTAssertEqual(findings.count, candidates.count, "every candidate still gets its rule finding")
        XCTAssertTrue(findings.allSatisfy { $0.source == .rule })
    }

    func testGuardRefusalPoisonsSharedBudgetAcrossScripts() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let budget = LLMTickBudget(Oversight.maxLLMEvaluationsPerTick)
        let laterCalls = CallCounter()

        var second = ShippedScripts.compact()
        second.id = "compact-2"
        let refusing = ScriptObserver(
            script: ShippedScripts.compact(), budget: budget,
            analyzer: ScriptAnalyzer(chat: { _, _, _, _ in throw AIGuardError.deferred("pressure") })
        )
        let other = ScriptObserver(
            script: second, budget: budget,
            analyzer: ScriptAnalyzer(chat: { _, _, _, _ in
                laterCalls.increment()
                return "WAIT: not now"
            })
        )

        let sessions = [snapshot("s", pct: 90)]
        let firstFindings = await refusing.observe(sessions: sessions, database: database)
        let secondFindings = await other.observe(sessions: sessions, database: database)

        XCTAssertEqual(firstFindings.map(\.source), [.rule], "the refused candidate degrades to the rule")
        XCTAssertEqual(laterCalls.count, 0, "a later script sharing the poisoned budget must not call the model")
        XCTAssertEqual(secondFindings.map(\.source), [.rule])
    }

    func testNextTickRetriesTheModelAfterAGuardHalt() async throws {
        try database.setSetting("oversight_llm_enabled", "true")
        let calls = CallCounter()
        let analyzer = ScriptAnalyzer(chat: { _, _, _, _ in
            calls.increment()
            throw AIGuardError.blocked("model over budget")
        })
        let sessions = [snapshot("s1", pct: 90), snapshot("s2", pct: 91)]

        // Tick 1: halted after one call. Tick 2 gets a FRESH budget (OversightService
        // builds one per tick) → the model is consulted again.
        for tick in 1...2 {
            let observer = ScriptObserver(
                script: ShippedScripts.compact(),
                budget: LLMTickBudget(Oversight.maxLLMEvaluationsPerTick),
                analyzer: analyzer
            )
            _ = await observer.observe(sessions: sessions, database: database)
            XCTAssertEqual(calls.count, tick, "each tick attempts exactly one call before halting")
        }
    }

    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        func increment() { lock.withLock { value += 1 } }
        var count: Int { lock.withLock { value } }
    }
}
