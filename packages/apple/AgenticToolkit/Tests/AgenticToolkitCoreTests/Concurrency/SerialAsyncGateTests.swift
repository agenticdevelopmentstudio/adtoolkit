import XCTest
@testable import AgenticToolkitCore

/// Unit tests for the one-at-a-time gate the credential evaluation runs behind.
///
/// The case worth pinning is the one an actor does **not** cover: a body that
/// suspends. Actors are reentrant, so an `actor` method holding an `await` lets
/// the next call in at the suspension point — and a credential evaluation is
/// nothing but suspensions, since it refreshes over the network. Every test here
/// therefore suspends inside the body; a version of these that only did
/// synchronous work would pass against an implementation that serializes nothing.
final class SerialAsyncGateTests: XCTestCase {

    func testJobsHandedOverAtOnceStillRunOneAtATime() async {
        let gate = SerialAsyncGate()
        let witness = OverlapWitness()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    await gate.run {
                        witness.enter()
                        try? await Task.sleep(nanoseconds: 1_000_000)
                        witness.leave()
                    }
                }
            }
        }

        XCTAssertEqual(witness.peak, 1)
        XCTAssertEqual(witness.finished, 8)
    }

    func testEveryCallerGetsItsOwnBodysAnswer() async {
        // The gate hands each arrival the value its own body produced, not the
        // one the job ahead of it produced — the chaining is on the waiting,
        // never on the result.
        let gate = SerialAsyncGate()
        let answers = await withTaskGroup(of: Int.self) { group -> [Int] in
            for value in 0..<8 {
                group.addTask {
                    await gate.run {
                        try? await Task.sleep(nanoseconds: 1_000_000)
                        return value
                    }
                }
            }
            var collected: [Int] = []
            for await answer in group { collected.append(answer) }
            return collected.sorted()
        }

        XCTAssertEqual(answers, Array(0..<8))
    }

    func testAJobArrivingAfterTheGateWentQuietStillRuns() async {
        // The tail is a finished task by then. Waiting on one that has already
        // completed has to return rather than hang, or the gate would serialize
        // itself into a stop the first time it drained.
        let gate = SerialAsyncGate()
        let first = await gate.run { 1 }
        try? await Task.sleep(nanoseconds: 2_000_000)
        let second = await gate.run { 2 }

        XCTAssertEqual([first, second], [1, 2])
    }

    func testAJobThatRunsPastTheTimeoutStopsHoldingTheGate() async {
        // The stuck body honours cancellation, so it leaves as soon as the
        // gate gives up on it: its caller is answered, and the job behind it
        // runs, both within a moment of the timeout rather than a minute.
        let gate = SerialAsyncGate(timeout: 0.2)
        let started = Date()

        async let stuck: Bool = gate.run {
            do {
                try await Task.sleep(for: .seconds(60))
                return true
            } catch {
                return false
            }
        }
        try? await Task.sleep(for: .milliseconds(20))
        let next = await gate.run { "ran" }
        let stuckAnswer = await stuck

        XCTAssertEqual(next, "ran")
        XCTAssertFalse(stuckAnswer, "the overrunning job should have been cancelled")
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }

    func testAJobThatIgnoresCancellationIsLeftBehindAfterTheGrace() async {
        // A body that never resumes cannot be cancelled into leaving. The gate
        // waits out the timeout and a short grace, then moves on without it;
        // the next job runs even though the first is still parked.
        let gate = SerialAsyncGate(timeout: 0.2)
        let started = Date()
        let parked = NeverResumes()

        let stuck = Task { await gate.run { await parked.wait() } }
        try? await Task.sleep(for: .milliseconds(20))
        let next = await gate.run { "ran" }

        XCTAssertEqual(next, "ran")
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
        parked.release()
        _ = await stuck.value
    }

    /// A suspension that only ends when told to, cancellation or not.
    private final class NeverResumes: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<Void, Never>?
        private var released = false

        func wait() async {
            await withCheckedContinuation { continuation in
                lock.lock()
                if released {
                    lock.unlock()
                    continuation.resume()
                } else {
                    self.continuation = continuation
                    lock.unlock()
                }
            }
        }

        func release() {
            lock.lock()
            released = true
            let continuation = self.continuation
            self.continuation = nil
            lock.unlock()
            continuation?.resume()
        }
    }

    /// Counts how many bodies were inside the gate at once, across the
    /// concurrency domains the gate hands work between.
    private final class OverlapWitness: @unchecked Sendable {
        private let lock = NSLock()
        private var current = 0
        private var highest = 0
        private var completed = 0

        var peak: Int {
            lock.lock(); defer { lock.unlock() }
            return highest
        }

        var finished: Int {
            lock.lock(); defer { lock.unlock() }
            return completed
        }

        func enter() {
            lock.lock()
            current += 1
            highest = max(highest, current)
            lock.unlock()
        }

        func leave() {
            lock.lock()
            current -= 1
            completed += 1
            lock.unlock()
        }
    }
}
