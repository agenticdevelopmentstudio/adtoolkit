import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitCore

final class ActivityPersistenceContractTests: XCTestCase {
    func testInMemoryStoreMeetsTheContract() throws {
        XCTAssertEqual(try ActivityPersistenceContract.runAll { InMemoryActivityStore() }, [])
    }

    func testRecoveredEndRules() {
        XCTAssertEqual(ActivityRecovery.recoveredEnd(startedAt: "2026-10-01T09:00:00Z",
                                                     lastSeenAt: "2026-10-01T09:02:00Z", openIdleFrom: []),
                       "2026-10-01T09:02:00Z")
        XCTAssertEqual(ActivityRecovery.recoveredEnd(startedAt: "2026-10-01T09:00:00Z",
                                                     lastSeenAt: "", openIdleFrom: []),
                       "2026-10-01T09:00:00Z")
        XCTAssertEqual(ActivityRecovery.recoveredEnd(startedAt: "2026-10-01T09:00:00Z",
                                                     lastSeenAt: "2026-10-01T09:02:00Z",
                                                     openIdleFrom: ["2026-10-01T09:01:00Z"]),
                       "2026-10-01T09:01:00Z")
        XCTAssertEqual(ActivityRecovery.recoveredEnd(startedAt: "2026-10-01T09:00:00Z",
                                                     lastSeenAt: "2026-10-01T09:02:00Z",
                                                     openIdleFrom: ["2026-10-01T08:00:00Z"]),
                       "2026-10-01T09:02:00Z", "an idle interval from before the span is not this span's")
    }

    private func closedSpan(_ id: String, start: String, end: String) -> ActivitySpanDTO {
        ActivitySpanDTO(id: id, bundleId: "b", appName: "A", startedAt: start, endedAt: end, tz: "UTC")
    }

    func testInMemoryPruneRemovesSpansEndedBeforeCutoff() throws {
        let store = InMemoryActivityStore()
        store.spans = [closedSpan("old", start: "2026-09-01T09:00:00Z", end: "2026-09-01T10:00:00Z"),
                       closedSpan("new", start: "2026-10-01T09:00:00Z", end: "2026-10-01T10:00:00Z")]
        let removed = try store.pruneActivity(endedBefore: "2026-09-15T00:00:00Z")
        XCTAssertEqual(removed, 1)
        XCTAssertEqual(store.spans.map(\.id), ["new"])
    }

    func testInMemoryPruneHonoursPrunable() throws {
        let store = InMemoryActivityStore()
        store.prunable = { _ in false }
        store.spans = [closedSpan("old", start: "2026-09-01T09:00:00Z", end: "2026-09-01T10:00:00Z")]
        XCTAssertEqual(try store.pruneActivity(endedBefore: "2026-09-15T00:00:00Z"), 0)
        XCTAssertEqual(store.spans.map(\.id), ["old"])
    }

    func testInMemoryPruneNeverRemovesOpenSpans() throws {
        let store = InMemoryActivityStore()
        store.spans = [ActivitySpanDTO(id: "open", bundleId: "b", appName: "A",
                                       startedAt: "2026-09-01T09:00:00Z", tz: "UTC")]
        XCTAssertEqual(try store.pruneActivity(endedBefore: "2099-01-01T00:00:00Z"), 0)
        XCTAssertEqual(store.spans.map(\.id), ["open"])
    }

    func testInMemoryPruneRemovesOnlyClosedOldIdleIntervals() throws {
        let store = InMemoryActivityStore()
        store.idle = [(from: "2026-09-01T09:00:00Z", until: "2026-09-01T09:30:00Z"),
                      (from: "2026-10-01T09:00:00Z", until: "")]
        XCTAssertEqual(try store.pruneActivity(endedBefore: "2026-09-15T00:00:00Z"), 1)
        XCTAssertEqual(store.idle.count, 1)
    }

    func testInMemoryPruneKeepsIdleTimeAKeptSpanStillOverlaps() throws {
        let store = InMemoryActivityStore()
        store.prunable = { $0.id == "derived" }
        store.spans = [closedSpan("derived", start: "2026-09-01T09:00:00Z", end: "2026-09-01T10:00:00Z"),
                       closedSpan("pending", start: "2026-09-01T11:00:00Z", end: "2026-09-01T12:00:00Z")]
        store.idle = [(from: "2026-09-01T09:15:00Z", until: "2026-09-01T09:30:00Z"),
                      (from: "2026-09-01T11:15:00Z", until: "2026-09-01T11:30:00Z")]
        XCTAssertEqual(try store.pruneActivity(endedBefore: "2026-09-15T00:00:00Z"), 2)
        XCTAssertEqual(store.spans.map(\.id), ["pending"])
        XCTAssertEqual(store.idle.map(\.from), ["2026-09-01T11:15:00Z"])
    }
}
