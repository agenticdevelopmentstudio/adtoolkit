import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// The Sessions-window list source's time-filter plumbing: the poll fetches
/// with the current hours window, and `setSinceHours` re-fetches immediately
/// with the new one (instead of waiting out the poll interval). Uses the
/// injectable fetcher — no daemon involved.
final class SessionListSourceFilterTests: XCTestCase {

    /// Thread-safe recorder for the hours values the source requested.
    private final class HoursRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [Int] = []
        func record(_ hours: Int) { lock.withLock { values.append(hours) } }
        var all: [Int] { lock.withLock { values } }
    }

    private func session(id: String) -> SessionWatcher.SessionWatcherSession {
        SessionWatcher.SessionWatcherSession(
            sessionId: id, cwd: "/tmp/\(id)", model: "test", startedAt: "", lastActivityAt: "",
            lastTool: "", status: .active, gitBranch: "", summary: "", pid: 1,
            termProgram: "Test", projectRoot: "", termSessionId: ""
        )
    }

    func testPollUsesInitialWindowAndSetSinceHoursRefetches() async throws {
        let recorder = HoursRecorder()
        let sessions = [session(id: "a")]
        let source = StenographerSessionListSource(
            pollInterval: 60,  // long — only the initial poll + the explicit refetch fire
            sinceHours: 24,
            fetcher: { hours in
                recorder.record(hours)
                // Return a different result per window so the change propagates.
                return hours == 6 ? [] : sessions
            }
        )

        let firstChange = expectation(description: "initial poll populated the cache")
        let secondChange = expectation(description: "setSinceHours re-fetched + changed the cache")
        let changeCount = HoursRecorder()  // reuse as a counter
        source.startObserving {
            changeCount.record(1)
            if changeCount.all.count == 1 { firstChange.fulfill() }
            if changeCount.all.count == 2 { secondChange.fulfill() }
        }

        await fulfillment(of: [firstChange], timeout: 5)
        XCTAssertEqual(recorder.all, [24], "initial poll uses the configured window")
        let populated = try await source.fetchSessions()
        XCTAssertEqual(populated.map(\.sessionId), ["a"])

        source.setSinceHours(6)
        await fulfillment(of: [secondChange], timeout: 5)
        XCTAssertEqual(recorder.all, [24, 6], "setSinceHours re-fetches immediately with the new window")
        let filtered = try await source.fetchSessions()
        XCTAssertTrue(filtered.isEmpty, "the 6h window's (empty) result replaced the cache")

        source.stopObserving()
    }

    /// Re-observing displaces the running poll, and the displaced one has to be
    /// cancelled or it keeps hitting the daemon every few seconds for the life of the
    /// process — a window closed and reopened enough times polls in a chorus.
    func testReObservingLeavesNoPollingBehind() async throws {
        let recorder = HoursRecorder()
        let source = StenographerSessionListSource(
            pollInterval: 0.05, sinceHours: 24,
            fetcher: { hours in
                recorder.record(hours)
                return []
            }
        )
        source.startObserving { }
        source.startObserving { }   // displaces the first
        try await Task.sleep(nanoseconds: 200_000_000)
        source.stopObserving()

        try await Task.sleep(nanoseconds: 100_000_000)  // let anything in flight land
        let settled = recorder.all.count
        try await Task.sleep(nanoseconds: 400_000_000)  // ~8 poll intervals
        XCTAssertEqual(recorder.all.count, settled, "no poll may outlive stopObserving()")
    }

    func testSettingSameHoursDoesNotRefetch() async throws {
        let recorder = HoursRecorder()
        let fixed = [session(id: "x")]
        let source = StenographerSessionListSource(
            pollInterval: 60, sinceHours: 24,
            fetcher: { hours in
                recorder.record(hours)
                return fixed
            }
        )
        let polled = expectation(description: "initial poll")
        source.startObserving { polled.fulfill() }
        await fulfillment(of: [polled], timeout: 5)

        source.setSinceHours(24)   // unchanged — must be a no-op
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(recorder.all, [24], "same value must not trigger a refetch")

        source.stopObserving()
    }
}
