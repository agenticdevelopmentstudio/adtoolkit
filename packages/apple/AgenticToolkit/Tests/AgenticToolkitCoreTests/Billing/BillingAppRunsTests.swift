import XCTest
@testable import AgenticToolkitCore

final class BillingAppRunsTests: XCTestCase {
    let start = "2026-10-01T09:00:00Z", end = "2026-10-01T10:00:00Z", now = "2026-10-01T12:00:00Z"
    private func idle(_ from: String, _ until: String) -> BillingIdleInterval {
        .init(idleFrom: from, idleUntil: until)
    }

    func testNoIdleIsOneRun() {
        XCTAssertEqual(
            BillingDerivation.appRuns(spanStart: start, spanEnd: end, idle: [], cutoffSeconds: 900, now: now),
            [BillingRun(startedAt: start, endedAt: end, seconds: 3600)])
    }
    func testIdleJustUnderCutoffStaysBilled() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T09:10:00Z", "2026-10-01T09:24:59Z")], cutoffSeconds: 900, now: now)
        XCTAssertEqual(runs.map(\.seconds), [3600])
    }
    func testIdleAtCutoffIsCut() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T09:10:00Z", "2026-10-01T09:25:00Z")], cutoffSeconds: 900, now: now)
        XCTAssertEqual(runs, [BillingRun(startedAt: start, endedAt: "2026-10-01T09:10:00Z", seconds: 600),
                              BillingRun(startedAt: "2026-10-01T09:25:00Z", endedAt: end, seconds: 2100)])
    }
    func testIdleOverlappingSpanEdgesIsClipped() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T08:00:00Z", "2026-10-01T09:30:00Z")], cutoffSeconds: 900, now: now)
        XCTAssertEqual(runs, [BillingRun(startedAt: "2026-10-01T09:30:00Z", endedAt: end, seconds: 1800)])
    }
    func testOpenSpanActiveNowIsRunning() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: "", idle: [], cutoffSeconds: 900,
                                             now: "2026-10-01T09:30:00Z")
        XCTAssertEqual(runs, [BillingRun(startedAt: start, endedAt: "", seconds: 0)])
    }
    func testOpenSpanWhileIdlePastCutoffEndsAtLastInput() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: "",
            idle: [idle("2026-10-01T09:20:00Z", "")], cutoffSeconds: 900, now: "2026-10-01T09:40:00Z")
        XCTAssertEqual(runs, [BillingRun(startedAt: start, endedAt: "2026-10-01T09:20:00Z", seconds: 1200)])
    }
    func testOpenSpanIdleUnderCutoffIsStillRunning() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: "",
            idle: [idle("2026-10-01T09:20:00Z", "")], cutoffSeconds: 900, now: "2026-10-01T09:25:00Z")
        XCTAssertEqual(runs, [BillingRun(startedAt: start, endedAt: "", seconds: 0)])
    }
    func testMalformedTimestampIsEmpty() {
        XCTAssertEqual(
            BillingDerivation.appRuns(spanStart: "x", spanEnd: end, idle: [], cutoffSeconds: 900, now: now), [])
    }
    func testWholeSpanIdleIsEmpty() {
        XCTAssertEqual(BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T08:00:00Z", "2026-10-01T11:00:00Z")], cutoffSeconds: 900, now: now), [])
    }
    func testOverlappingIdlesAreUnioned() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T09:10:00Z", "2026-10-01T09:30:00Z"),
                   idle("2026-10-01T09:20:00Z", "2026-10-01T09:40:00Z")], cutoffSeconds: 900, now: now)
        XCTAssertEqual(runs, [BillingRun(startedAt: start, endedAt: "2026-10-01T09:10:00Z", seconds: 600),
                              BillingRun(startedAt: "2026-10-01T09:40:00Z", endedAt: end, seconds: 1200)])
    }
    func testSpanRowSessionIdMatchesActivitySpanSession() {
        let row = BillingAppSpanRow(id: "X1", bundleId: "b", appName: "A", windowTitle: "", workingPath: "",
                                    repoRoot: "", branch: "", startedAt: start, endedAt: "", tz: "UTC")
        XCTAssertEqual(row.sessionId, ActivitySpanSession.sessionId(spanId: "X1"))
        XCTAssertEqual(ActivitySpanSession.spanId(sessionId: row.sessionId), "X1")
    }
}
