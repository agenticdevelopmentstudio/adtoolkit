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
    /// Review F1: a restart mid-absence splits one 20-minute idle into two
    /// 10-minute rows a minute apart. The absence is past the cutoff, so its
    /// rows are cut; the minute between them, recorded by no row, stays.
    func testAnAbsenceSplitByARestartIsCutAsOne() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T09:10:00Z", "2026-10-01T09:20:00Z"),
                   idle("2026-10-01T09:21:00Z", "2026-10-01T09:31:00Z")], cutoffSeconds: 900, now: now)
        XCTAssertEqual(runs, [
            BillingRun(startedAt: start, endedAt: "2026-10-01T09:10:00Z", seconds: 600),
            BillingRun(startedAt: "2026-10-01T09:20:00Z", endedAt: "2026-10-01T09:21:00Z", seconds: 60),
            BillingRun(startedAt: "2026-10-01T09:31:00Z", endedAt: end, seconds: 1740)
        ])
    }
    /// Two short idles further apart than the input lag are two absences.
    func testShortIdlesFurtherApartThanTheLagStayBilled() {
        let runs = BillingDerivation.appRuns(spanStart: start, spanEnd: end,
            idle: [idle("2026-10-01T09:10:00Z", "2026-10-01T09:20:00Z"),
                   idle("2026-10-01T09:21:31Z", "2026-10-01T09:31:31Z")], cutoffSeconds: 900, now: now)
        XCTAssertEqual(runs.map(\.seconds), [3600])
    }
    private func span(ended: String) -> BillingAppSpanRow {
        BillingAppSpanRow(id: "S", bundleId: "b", appName: "A", windowTitle: "", workingPath: "",
                          repoRoot: "", branch: "", startedAt: start, endedAt: ended, tz: "UTC")
    }
    /// Review F15: the idle row for a span's tail lands up to the input lag
    /// late, backdated. A span younger than that stays pending, so the late
    /// row still cuts it; an older one is settled.
    func testAClosedSpanYoungerThanTheInputLagStaysPending() {
        XCTAssertTrue(BillingStore.staysPending(span(ended: ""), idle: [], cutoffSeconds: 900, now: now))
        XCTAssertTrue(BillingStore.staysPending(span(ended: end), idle: [], cutoffSeconds: 900,
                                                now: "2026-10-01T10:01:00Z"), "60 s old")
        XCTAssertFalse(BillingStore.staysPending(span(ended: end), idle: [], cutoffSeconds: 900,
                                                 now: "2026-10-01T10:01:31Z"), "91 s old")
    }
    /// Review F46: an open idle row keeps a closed span pending only until it
    /// has run past the cutoff and the lag; after that the output is fixed,
    /// however long the row stays open (a screen lock never closes it).
    func testAnOpenIdlePastTheCutoffNoLongerHoldsTheSpanPending() {
        let open = [idle("2026-10-01T09:50:00Z", "")]
        XCTAssertTrue(BillingStore.staysPending(span(ended: end), idle: open, cutoffSeconds: 900,
                                                now: "2026-10-01T10:06:00Z"), "16 min idle: under cutoff + lag")
        XCTAssertFalse(BillingStore.staysPending(span(ended: end), idle: open, cutoffSeconds: 900,
                                                 now: "2026-10-01T10:06:30Z"), "16.5 min idle: cut for good")
        XCTAssertFalse(BillingStore.staysPending(span(ended: end), idle: open, cutoffSeconds: 900, now: now))
    }
    func testSpanRowSessionIdMatchesActivitySpanSession() {
        let row = BillingAppSpanRow(id: "X1", bundleId: "b", appName: "A", windowTitle: "", workingPath: "",
                                    repoRoot: "", branch: "", startedAt: start, endedAt: "", tz: "UTC")
        XCTAssertEqual(row.sessionId, ActivitySpanSession.sessionId(spanId: "X1"))
        XCTAssertEqual(ActivitySpanSession.spanId(sessionId: row.sessionId), "X1")
    }
}
