import XCTest
@testable import AgenticToolkitActivity

/// I-3: `AppFocusTrigger`, `WindowLifecycleContextTrigger` and
/// `UsageCollector` observe one window source under three independent
/// opt-ins, so neither one's `stop()` may end the others' observation and
/// none of them may take the single `onEvent`/`onTitleChange` slot from the
/// others.
@MainActor
final class SharedWindowLifecycleSourceTests: XCTestCase {
    func testStartsTheBaseSourceOnlyOnce() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let first = shared.makeClient()
        let second = shared.makeClient()

        first.start()
        second.start()

        XCTAssertEqual(base.startCount, 1)
        XCTAssertEqual(shared.startCount, 2)
        XCTAssertTrue(shared.isObserving)
    }

    func testKeepsObservingUntilTheLastConsumerStops() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let first = shared.makeClient()
        let second = shared.makeClient()
        first.start()
        second.start()

        first.stop()
        XCTAssertEqual(base.stopCount, 0, "one consumer stopping must not end the other's observation")
        XCTAssertTrue(shared.isObserving)
        XCTAssertEqual(shared.startCount, 1)

        second.stop()
        XCTAssertEqual(base.stopCount, 1)
        XCTAssertFalse(shared.isObserving)
        XCTAssertEqual(shared.startCount, 0)
    }

    func testAClientsRepeatedStartAndStopAreIdempotent() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let client = shared.makeClient()

        client.stop()
        XCTAssertEqual(base.stopCount, 0, "a stop before any start must not reach the base")

        client.start()
        client.start()
        XCTAssertEqual(base.startCount, 1)
        XCTAssertEqual(shared.startCount, 1, "a double start must count as one running client")

        client.stop()
        client.stop()
        XCTAssertEqual(base.stopCount, 1)
        XCTAssertFalse(shared.isObserving)
    }

    func testRestartingAfterEveryClientStoppedStartsTheBaseAgain() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let client = shared.makeClient()

        client.start()
        client.stop()
        client.start()

        XCTAssertEqual(base.startCount, 2)
        XCTAssertEqual(base.stopCount, 1)
        XCTAssertTrue(shared.isObserving)
    }

    func testEveryStartedClientGetsBothCallbacks() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let first = shared.makeClient()
        let second = shared.makeClient()
        var firstEvents = 0, firstTitles = 0
        var secondEvents = 0, secondTitles = 0
        first.onEvent = { _, _, _, _ in firstEvents += 1 }
        first.onTitleChange = { firstTitles += 1 }
        second.onEvent = { _, _, _, _ in secondEvents += 1 }
        second.onTitleChange = { secondTitles += 1 }
        first.start()
        second.start()

        base.emitTitleChange()

        XCTAssertEqual(firstEvents, 1)
        XCTAssertEqual(firstTitles, 1)
        XCTAssertEqual(secondEvents, 1, "the second client's callback must not have been overwritten")
        XCTAssertEqual(secondTitles, 1)
    }

    func testAStoppedClientReceivesNothingWhileOthersStillDo() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let stopped = shared.makeClient()
        let running = shared.makeClient()
        var stoppedEvents = 0, runningEvents = 0
        stopped.onEvent = { _, _, _, _ in stoppedEvents += 1 }
        running.onEvent = { _, _, _, _ in runningEvents += 1 }
        stopped.start()
        running.start()
        stopped.stop()

        base.emit(.created, AppInfo(bundleID: "a", name: "A", pid: 1), 7, "t")

        XCTAssertEqual(stoppedEvents, 0)
        XCTAssertEqual(runningEvents, 1)
        XCTAssertTrue(shared.isObserving)
    }

    /// A consumer that is deallocated without stopping must not strand the
    /// observation on — the hub derives "is anyone running" from the clients
    /// that are still alive rather than from a counter.
    func testAReleasedClientStopsCountingAsARunner() {
        let base = FakeWindowSource()
        let shared = SharedWindowLifecycleSource(base)
        let survivor = shared.makeClient()
        survivor.start()

        var released: (any WindowLifecycleSource)? = shared.makeClient()
        released?.start()
        XCTAssertEqual(shared.startCount, 2)
        released = nil

        // Any reconcile re-derives the live set; stopping the survivor is one.
        survivor.stop()
        XCTAssertFalse(shared.isObserving)
        XCTAssertEqual(base.stopCount, 1)
        XCTAssertEqual(shared.startCount, 0)
    }
}
