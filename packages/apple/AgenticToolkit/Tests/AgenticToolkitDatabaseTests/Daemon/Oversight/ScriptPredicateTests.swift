import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// Predicate evaluation over a live session: every field and operator, the derived
/// tokens-in-context, all/any semantics (empty group = false), idle time against an
/// injected clock, and reason-template substitution.
final class ScriptPredicateTests: XCTestCase {

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

    private func iso8601(_ date: Date = Date()) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: date)
    }

    private func snapshot(
        pct: Int = 40, window: Int = 200_000, status: String = "active",
        model: String = "sonnet", cwd: String = "/tmp/proj", lastActivity: String? = nil
    ) -> LiveSessionSnapshot {
        LiveSessionSnapshot(
            sessionId: "s", cwd: cwd, status: status, model: model,
            gitBranch: "", lastActivityAt: lastActivity ?? iso8601(), contextUsedPct: pct,
            contextWindowSize: window, termSessionId: ""
        )
    }

    private func evaluate(_ predicate: ScriptPredicate, on session: LiveSessionSnapshot,
                          now: Date = Date()) -> Bool {
        var context = EvaluationContext(session: session, database: database, now: now)
        return predicate.evaluate(&context)
    }

    // MARK: - tokens_in_context (the derived field)

    func testTokensInContextDerivation() {
        // 40% of 200k = 80k → fires at the 70k default; 30% = 60k → doesn't.
        let trigger = ScriptPredicate.condition(field: .tokensInContext, operation: .greaterOrEqual, value: "70000")
        XCTAssertTrue(evaluate(trigger, on: snapshot(pct: 40, window: 200_000)))
        XCTAssertFalse(evaluate(trigger, on: snapshot(pct: 30, window: 200_000)))
    }

    func testTokensInContextUnknownWindowIsZero() {
        let trigger = ScriptPredicate.condition(field: .tokensInContext, operation: .greaterOrEqual, value: "1")
        XCTAssertFalse(evaluate(trigger, on: snapshot(pct: 90, window: 0)),
                       "no window report → 0 tokens, never fires")
    }

    // MARK: - Operators

    func testNumericOperators() {
        let session = snapshot(pct: 80)
        func pct(_ operation: ConditionOperator, _ value: String) -> Bool {
            evaluate(.condition(field: .contextUsedPct, operation: operation, value: value), on: session)
        }
        XCTAssertTrue(pct(.equals, "80"))
        XCTAssertTrue(pct(.notEquals, "70"))
        XCTAssertTrue(pct(.greaterThan, "79"))
        XCTAssertFalse(pct(.greaterThan, "80"))
        XCTAssertTrue(pct(.greaterOrEqual, "80"))
        XCTAssertTrue(pct(.lessThan, "81"))
        XCTAssertTrue(pct(.lessOrEqual, "80"))
        XCTAssertFalse(pct(.contains, "8"), "contains on a numeric field fails closed")
        XCTAssertFalse(pct(.greaterOrEqual, "not-a-number"), "unparseable numeric value fails closed")
    }

    func testStringOperators() {
        let session = snapshot(model: "claude-sonnet-4-6", cwd: "/Users/me/projects/steno")
        XCTAssertTrue(evaluate(.condition(field: .model, operation: .contains, value: "sonnet"), on: session))
        XCTAssertTrue(evaluate(.condition(field: .sessionStatus, operation: .equals, value: "active"), on: session))
        XCTAssertTrue(evaluate(.condition(field: .sessionStatus, operation: .notEquals, value: "ended"), on: session))
        XCTAssertTrue(evaluate(.condition(field: .projectPath, operation: .contains, value: "steno"), on: session))
        XCTAssertFalse(evaluate(.condition(field: .model, operation: .greaterThan, value: "a"), on: session),
                       "ordering on strings fails closed")
    }

    // MARK: - last_event_type (DB-backed)

    func testLastEventTypeCondition() throws {
        try database.ingestEvent(
            eventType: "Stop", timestamp: iso8601(),
            hookData: ["session_id": "s", "cwd": "/tmp/s"]
        )
        XCTAssertTrue(evaluate(.condition(field: .lastEventType, operation: .equals, value: "Stop"), on: snapshot()))
        XCTAssertFalse(evaluate(
            .condition(field: .lastEventType, operation: .equals, value: "PreToolUse"), on: snapshot()
        ))
    }

    // MARK: - idle_minutes

    func testIdleMinutesAgainstInjectedNow() {
        let tenMinutesAgo = iso8601(Date(timeIntervalSinceNow: -600))
        let session = snapshot(lastActivity: tenMinutesAgo)
        XCTAssertTrue(evaluate(.condition(field: .idleMinutes, operation: .greaterOrEqual, value: "9"), on: session))
        XCTAssertFalse(evaluate(.condition(field: .idleMinutes, operation: .greaterOrEqual, value: "11"), on: session))
    }

    func testIdleMinutesParsesSQLiteDateTimeFormat() {
        // Live sessions store last_activity_at via SQLite datetime() — "yyyy-MM-dd
        // HH:mm:ss" (UTC, space, no zone), which ISO8601DateFormatter can't parse.
        // idle_minutes must still work, or it silently reads 0 in production.
        let now = Date()
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let session = snapshot(lastActivity: fmt.string(from: now.addingTimeInterval(-600)))
        XCTAssertTrue(evaluate(.condition(field: .idleMinutes, operation: .greaterOrEqual, value: "9"),
                               on: session, now: now))
        XCTAssertFalse(evaluate(.condition(field: .idleMinutes, operation: .greaterOrEqual, value: "11"),
                                on: session, now: now))
    }

    func testIdleMinutesUnparseableTimestampIsZero() {
        let session = snapshot(lastActivity: "garbage")
        XCTAssertFalse(evaluate(.condition(field: .idleMinutes, operation: .greaterThan, value: "0"), on: session),
                       "unknown last-activity must not read as idle-forever")
    }

    // MARK: - Groups

    func testAllRequiresEveryCondition() {
        let both = ScriptPredicate.all([
            .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "80"),
            .condition(field: .sessionStatus, operation: .equals, value: "active")
        ])
        XCTAssertTrue(evaluate(both, on: snapshot(pct: 85)))
        XCTAssertFalse(evaluate(both, on: snapshot(pct: 50)))
    }

    func testAnyRequiresOneCondition() {
        let either = ScriptPredicate.any([
            .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "80"),
            .condition(field: .model, operation: .equals, value: "sonnet")
        ])
        XCTAssertTrue(evaluate(either, on: snapshot(pct: 10, model: "sonnet")))
        XCTAssertFalse(evaluate(either, on: snapshot(pct: 10, model: "haiku")))
    }

    func testEmptyGroupsAreFalse() {
        XCTAssertFalse(evaluate(.all([]), on: snapshot()))
        XCTAssertFalse(evaluate(.any([]), on: snapshot()))
    }

    func testNestedGroups() {
        let nested = ScriptPredicate.any([
            .all([
                .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "80"),
                .condition(field: .model, operation: .equals, value: "sonnet")
            ]),
            .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "95")
        ])
        XCTAssertTrue(evaluate(nested, on: snapshot(pct: 85, model: "sonnet")))
        XCTAssertTrue(evaluate(nested, on: snapshot(pct: 96, model: "haiku")))
        XCTAssertFalse(evaluate(nested, on: snapshot(pct: 85, model: "haiku")))
    }

    // MARK: - Reason templates

    func testRenderReasonSubstitutesFields() {
        var context = EvaluationContext(session: snapshot(pct: 85, window: 200_000), database: database)
        let rendered = context.renderReason("Context {{context_used_pct}}% of {{context_window_size}} tokens")
        XCTAssertEqual(rendered, "Context 85% of 200000 tokens")
    }

    func testRenderReasonLeavesUnknownPlaceholders() {
        var context = EvaluationContext(session: snapshot(), database: database)
        XCTAssertEqual(context.renderReason("{{not_a_field}} stays"), "{{not_a_field}} stays")
    }
}
