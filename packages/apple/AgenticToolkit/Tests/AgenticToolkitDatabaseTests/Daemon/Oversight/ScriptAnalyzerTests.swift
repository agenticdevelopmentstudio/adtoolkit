import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import AIPluginKit

/// The LLM judgment layer: keyword-parameterized verdict parsing, the
/// graceful-degradation contract, the prompt shape, and the `oversight_llm_enabled`
/// gate.
final class ScriptAnalyzerTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    let compactConfirmation = LLMConfirmation(systemPrompt: "sys", actKeyword: "COMPACT")

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

    private func snapshot(_ id: String, pct: Int) -> LiveSessionSnapshot {
        LiveSessionSnapshot(
            sessionId: id, cwd: "/tmp/\(id)", status: "active", model: "sonnet",
            gitBranch: "feature", lastActivityAt: iso8601(), contextUsedPct: pct,
            contextWindowSize: 200_000, termSessionId: ""
        )
    }

    // MARK: - parse

    func testParseActKeyword() {
        XCTAssertEqual(
            ScriptAnalyzer.parse("COMPACT: last edit landed", actKeyword: "COMPACT"),
            .act(reason: "last edit landed")
        )
    }

    func testParseCustomKeyword() {
        XCTAssertEqual(
            ScriptAnalyzer.parse("NUDGE: it's been idle a while", actKeyword: "NUDGE"),
            .act(reason: "it's been idle a while")
        )
        // A different script's keyword must not match.
        XCTAssertEqual(ScriptAnalyzer.parse("COMPACT: go", actKeyword: "NUDGE"), .unavailable)
    }

    func testParseWait() {
        XCTAssertEqual(ScriptAnalyzer.parse("WAIT: mid-task", actKeyword: "COMPACT"), .wait(reason: "mid-task"))
    }

    func testParseIsCaseInsensitiveAndStripsQuotes() {
        XCTAssertEqual(
            ScriptAnalyzer.parse("\"compact: go now\"", actKeyword: "COMPACT"),
            .act(reason: "go now")
        )
    }

    func testParseUsesOnlyFirstLine() {
        XCTAssertEqual(
            ScriptAnalyzer.parse("WAIT: still editing\nignored second line", actKeyword: "COMPACT"),
            .wait(reason: "still editing")
        )
    }

    func testParseMissingReasonUsesDefault() {
        guard case .act(let reason) = ScriptAnalyzer.parse("COMPACT", actKeyword: "COMPACT") else {
            return XCTFail("expected .act")
        }
        XCTAssertFalse(reason.isEmpty, "a reasonless keyword still carries a default reason")
    }

    func testParseGarbageIsUnavailable() {
        XCTAssertEqual(ScriptAnalyzer.parse("hmm, maybe later", actKeyword: "COMPACT"), .unavailable)
        XCTAssertEqual(ScriptAnalyzer.parse("", actKeyword: "COMPACT"), .unavailable)
    }

    func testParseEmptyKeywordNeverActs() {
        // A blank act keyword must not turn every reply into an act (`hasPrefix("")`
        // is always true, which would invert the WAIT safety confirmation): WAIT
        // stays WAIT, and anything else is unavailable rather than a spurious act.
        XCTAssertEqual(ScriptAnalyzer.parse("WAIT: mid-task", actKeyword: ""), .wait(reason: "mid-task"))
        XCTAssertEqual(ScriptAnalyzer.parse("COMPACT: go", actKeyword: ""), .unavailable)
    }

    func testParseWaitWinsOverPrefixKeyword() {
        // A keyword that is itself a prefix of WAIT must not steal a WAIT verdict.
        XCTAssertEqual(
            ScriptAnalyzer.parse("WAIT: still editing", actKeyword: "WA"),
            .wait(reason: "still editing")
        )
    }

    // MARK: - verdict (graceful degradation)

    func testVerdictReturnsParsedReply() async throws {
        let analyzer = ScriptAnalyzer(chat: { _, _, _, _ in "COMPACT: safe breakpoint" })
        let verdict = try await analyzer.verdict(
            for: snapshot("s", pct: 90), confirmation: compactConfirmation, database: database
        )
        XCTAssertEqual(verdict, .act(reason: "safe breakpoint"))
    }

    func testVerdictIsUnavailableWhenChatThrows() async throws {
        let analyzer = ScriptAnalyzer(chat: { _, _, _, _ in
            throw DaemonAIChat.ChatError.providerError("unreachable")
        })
        let verdict = try await analyzer.verdict(
            for: snapshot("s", pct: 90), confirmation: compactConfirmation, database: database
        )
        XCTAssertEqual(verdict, .unavailable, "a thrown transport error must degrade, not crash the tick")
    }

    func testVerdictRethrowsGuardRefusal() async {
        // A guard refusal must NOT degrade to .unavailable — the observer needs it
        // to halt further model calls for the rest of the tick.
        let analyzer = ScriptAnalyzer(chat: { _, _, _, _ in
            throw AIGuardError.blocked("model over budget")
        })
        do {
            _ = try await analyzer.verdict(
                for: snapshot("s", pct: 90), confirmation: compactConfirmation, database: database
            )
            XCTFail("expected AIGuardError to rethrow")
        } catch {
            XCTAssertEqual(error, .blocked("model over budget"))
        }
    }

    func testVerdictUsesTheConfirmationSystemPrompt() async throws {
        let seen = Captured()
        let analyzer = ScriptAnalyzer(chat: { systemPrompt, _, _, _ in
            seen.record(systemPrompt)
            return "WAIT: x"
        })
        _ = try await analyzer.verdict(
            for: snapshot("s", pct: 90),
            confirmation: LLMConfirmation(systemPrompt: "custom instructions", actKeyword: "GO"),
            database: database
        )
        XCTAssertEqual(seen.values, ["custom instructions"])
    }

    private final class Captured: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [String] = []
        func record(_ value: String) { lock.withLock { stored.append(value) } }
        var values: [String] { lock.withLock { stored } }
    }

    // MARK: - prompt

    func testBuildPromptIncludesContextAndRecentActivity() throws {
        try database.ingestEvent(
            eventType: "PreToolUse", timestamp: iso8601(),
            hookData: ["session_id": "s", "cwd": "/tmp/s", "tool_name": "Edit",
                       "tool_use_id": "t1", "tool_input": [String: Any]()]
        )
        let prompt = ScriptAnalyzer.buildPrompt(session: snapshot("s", pct: 88), database: database)
        XCTAssertTrue(prompt.contains("88% used"), "prompt states how full the context is")
        XCTAssertTrue(prompt.contains("Branch: feature"))
        XCTAssertTrue(prompt.contains("PreToolUse"), "prompt includes recent activity")
    }

    // MARK: - config gate

    func testLLMDisabledByDefault() {
        XCTAssertFalse(Oversight.llmEnabled(database))
    }

    func testLLMEnabledWhenOptedIn() throws {
        try database.setSetting("oversight_llm_enabled", "true")
        XCTAssertTrue(Oversight.llmEnabled(database))
        try database.setSetting("oversight_llm_enabled", "1")
        XCTAssertTrue(Oversight.llmEnabled(database))
    }

    func testModelLabelDefaultsToCLIWithoutProvider() {
        XCTAssertEqual(ScriptAnalyzer.modelLabel(database), "claude-cli")
    }
}
