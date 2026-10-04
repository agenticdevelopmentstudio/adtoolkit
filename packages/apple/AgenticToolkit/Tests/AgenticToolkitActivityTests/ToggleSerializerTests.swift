import XCTest
@testable import AgenticToolkitActivity

/// Thread-safe append-only recorder, mirroring `ReplyOnceTests`' `Answers`
/// but generic so it can hold whatever a given test needs to observe.
private final class Recorder<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Value] = []
    func record(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        values.append(value)
    }
    var all: [Value] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}

/// Returns `true` to exactly one caller (the first), `false` to every caller
/// after — used to gate the first of several concurrent `apply` invocations
/// without capturing a raw `var` in a `@Sendable` closure.
private final class OnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false
    func takeFirst() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if fired { return false }
        fired = true
        return true
    }
}

/// An async-friendly one-shot gate: `wait()` suspends until `release()` is
/// called (or returns immediately if `release()` already ran) — used to hold
/// an `apply` closure "in flight" without blocking a thread, since
/// `DispatchSemaphore.wait()` is unavailable from `async` contexts.
private final class AsyncGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isReleased = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            if isReleased {
                lock.unlock()
                continuation.resume()
                return
            }
            self.continuation = continuation
            lock.unlock()
        }
    }

    func release() {
        lock.lock()
        isReleased = true
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume()
    }
}

final class ToggleSerializerTests: XCTestCase {
    func testSingleRequestIsAppliedAndReturnsItsResult() {
        let serializer = ToggleSerializer()
        let done = expectation(description: "onResult")
        let received = Recorder<Bool>()

        serializer.request("power", true, onResult: { value in
            received.record(value)
            done.fulfill()
        }) { value in
            value
        }

        wait(for: [done], timeout: 5)
        XCTAssertEqual(received.all, [true])
    }

    /// While the first apply is in flight, two more requests arrive for the
    /// same key. Only the latest of those should ever be applied — not
    /// queued FIFO — so the applied sequence must be exactly the in-flight
    /// value followed by the final value, never the intermediate one.
    func testLatestWinsAppliesOnlyTheNewestQueuedValue() {
        let serializer = ToggleSerializer()
        let applied = Recorder<Bool>()
        let started = DispatchSemaphore(value: 0)
        let release = AsyncGate()
        let secondApplyDone = expectation(description: "second apply completed")

        serializer.request("key", true) { value in
            started.signal()
            await release.wait()
            applied.record(value)
            return value
        }

        started.wait()

        // Arrives first while the initial apply is blocked: must be
        // superseded before it is ever applied — its own apply must never
        // run, so it must never record into `applied`.
        serializer.request("key", true, apply: { value in
            applied.record(value)
            return value
        })
        // Arrives last: this is the only one of the two that should
        // survive, and it must run its OWN apply closure to record — not
        // request #1's, and not request #2's.
        serializer.request("key", false, apply: { value in
            applied.record(value)
            secondApplyDone.fulfill()
            return value
        })

        release.release()

        wait(for: [secondApplyDone], timeout: 5)
        XCTAssertEqual(
            applied.all, [true, false],
            "expected exactly two applies — the in-flight one, then only the latest queued value")
    }

    /// A request is one coherent unit — value, `apply`, and `onResult`
    /// together. While the driving call's apply is in flight, a second
    /// request for the same key arrives with its own, distinct `apply`
    /// closure. Once the driving call's apply completes, the driver's next
    /// loop iteration must run the SECOND request's own closure — never
    /// reuse the driving call's — because the second request is what's
    /// actually pending by then.
    func testNewestRequestsApplyClosureRunsNotTheDrivingCalls() {
        let serializer = ToggleSerializer()
        let started = DispatchSemaphore(value: 0)
        let release = AsyncGate()
        let isFirstApply = OnceFlag()
        let firstApplyCalled = Recorder<Bool>()
        let secondApplyCalled = Recorder<Bool>()
        let done = expectation(description: "second request's own apply ran")

        serializer.request("key", true) { value in
            if isFirstApply.takeFirst() {
                firstApplyCalled.record(true)
                started.signal()
                await release.wait()
                return value
            }
            // If this branch ever runs, the driver reused the driving call's
            // closure for a later request instead of that request's own.
            return value
        }

        started.wait()

        serializer.request("key", false, onResult: { _ in done.fulfill() }) { value in
            secondApplyCalled.record(true)
            return value
        }

        release.release()

        wait(for: [done], timeout: 5)
        XCTAssertEqual(firstApplyCalled.all, [true], "the driving call's own closure runs once, for its own value")
        XCTAssertEqual(
            secondApplyCalled.all, [true],
            "the newest request's own apply closure must be the one that runs for its own value")
    }

    /// The documented contract: a superseded request's `onResult` is never
    /// invoked at all (not even with a "failure" value) — pinned here so a
    /// future change to that contract has to face the decision explicitly.
    func testSupersededRequestsOnResultIsNeverInvoked() {
        let serializer = ToggleSerializer()
        let started = DispatchSemaphore(value: 0)
        let release = AsyncGate()
        let isFirstApply = OnceFlag()
        let supersededCalled = Recorder<Bool>()
        let finalReceived = Recorder<Bool>()
        let finalDone = expectation(description: "final onResult")

        serializer.request("key", true, onResult: { _ in }) { value in
            if isFirstApply.takeFirst() {
                started.signal()
                await release.wait()
            }
            return value
        }

        started.wait()

        // Superseded before it is ever applied: its onResult must never fire.
        serializer.request("key", true, onResult: { supersededCalled.record($0) }) { $0 }

        // Supersedes the request above; its onResult must fire.
        serializer.request("key", false, onResult: { value in
            finalReceived.record(value)
            finalDone.fulfill()
        }) { $0 }

        release.release()

        wait(for: [finalDone], timeout: 5)
        XCTAssertEqual(finalReceived.all, [false])
        XCTAssertTrue(supersededCalled.all.isEmpty, "a superseded request's onResult must never be invoked")
    }

    /// One key being driven toward convergence must not block or serialize
    /// another key — each key gets its own independent driver.
    func testDifferentKeysConvergeIndependently() {
        let serializer = ToggleSerializer()
        let keyAStarted = DispatchSemaphore(value: 0)
        let keyARelease = AsyncGate()
        let keyADone = expectation(description: "key A applied")
        let keyBDone = expectation(description: "key B applied while key A still in flight")

        serializer.request("keyA", true, onResult: { _ in keyADone.fulfill() }) { value in
            keyAStarted.signal()
            await keyARelease.wait()
            return value
        }

        keyAStarted.wait() // key A's apply is now blocked in flight

        serializer.request("keyB", true, onResult: { _ in keyBDone.fulfill() }) { value in value }

        // Key B must converge promptly even though key A's apply is
        // deliberately still blocked — if the two keys shared one driver
        // this would time out.
        wait(for: [keyBDone], timeout: 3)

        keyARelease.release()
        wait(for: [keyADone], timeout: 5)
    }

    /// After a key's driver loop finds nothing left and exits, it must
    /// release the key — a later, independent request for that same key
    /// must still be picked up and applied, not silently wedged.
    func testDriverReleasesTheKeyAfterQuiescingSoALaterRequestStillApplies() {
        let serializer = ToggleSerializer()
        let firstDone = expectation(description: "first request applied")
        let secondDone = expectation(description: "second request applied")
        let firstResult = Recorder<Bool>()
        let secondResult = Recorder<Bool>()

        serializer.request("power", true, onResult: { value in
            firstResult.record(value)
            firstDone.fulfill()
        }) { $0 }

        wait(for: [firstDone], timeout: 5)

        serializer.request("power", false, onResult: { value in
            secondResult.record(value)
            secondDone.fulfill()
        }) { $0 }

        wait(for: [secondDone], timeout: 5)

        XCTAssertEqual(firstResult.all, [true])
        XCTAssertEqual(secondResult.all, [false])
    }

    /// Many concurrent `request` calls for one key must all converge, and
    /// the value that is actually applied last must equal the value of
    /// whichever call was truly the last to record its desired value —
    /// never an earlier, superseded one.
    ///
    /// `submitLock` wraps "record the submitted value, then call `request`"
    /// as one atomic unit per thread, so `recorder`'s append order is
    /// guaranteed to match the order `ToggleSerializer` itself observed the
    /// writes in. Each request's `onResult` is wrapped in `ReplyOnce` so a
    /// superseded (dropped) request still resolves — via its `deinit`
    /// fallback — letting the test wait for every one of the 200 requests to
    /// settle, not just the ones that were genuinely applied.
    func testManyConcurrentRequestsForOneKeyConvergeToTheLastOne() {
        let serializer = ToggleSerializer()
        let recorder = Recorder<Bool>()
        let applied = Recorder<Bool>()
        let submitLock = NSLock()
        let group = DispatchGroup()
        let iterations = 200

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            let value = Bool.random()
            group.enter()
            submitLock.lock()
            recorder.record(value)
            let reply = ReplyOnce(fallback: false) { result in
                applied.record(result)
                group.leave()
            }
            serializer.request("many", value, onResult: { reply($0) }) { $0 }
            submitLock.unlock()
        }

        let waitResult = group.wait(timeout: .now() + 10)
        XCTAssertEqual(waitResult, .success, "all 200 requests should settle (applied or dropped) within the timeout")
        XCTAssertEqual(applied.all.last, recorder.all.last, "the truly last-submitted value must be the one that ends up applied")
    }
}
