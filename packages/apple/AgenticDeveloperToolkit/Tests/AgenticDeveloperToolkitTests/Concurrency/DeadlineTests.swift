import XCTest
@testable import AgenticDeveloperToolkit

final class DeadlineTests: XCTestCase {

    // MARK: - withDeadline

    func testAPromptOperationWins() async {
        let value = await withDeadline(.seconds(5), fallback: { "late" }) { "prompt" }
        XCTAssertEqual(value, "prompt")
    }

    func testAnOverrunningOperationYieldsTheFallbackAtTheDeadline() async {
        let started = Date()
        let value = await withDeadline(.milliseconds(200), fallback: { "late" }) {
            try? await Task.sleep(for: .seconds(60))
            return "prompt"
        }
        XCTAssertEqual(value, "late")
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }

    // MARK: - Task.finished(within:)

    func testATaskThatFinishesInTimeIsFinishedAndLeftAlone() async {
        let task = Task { 42 }

        let finished = await task.finished(within: .seconds(5))

        XCTAssertTrue(finished)
        XCTAssertFalse(task.isCancelled)
        let value = await task.value
        XCTAssertEqual(value, 42)
    }

    /// The whole point: this comes back well inside the task's own running
    /// time, and the task has been told to stop.
    func testATaskThatOverrunsIsUnfinishedAtTheDeadlineAndCancelled() async {
        let task = Task { try await Task.sleep(for: .seconds(60)) }
        let started = Date()

        let finished = await task.finished(within: .milliseconds(200))

        XCTAssertFalse(finished)
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
        XCTAssertTrue(task.isCancelled)
        // A sleep honours the cancellation, so the task ends now rather than
        // in a minute — the deadline did not just abandon it.
        do {
            try await task.value
            XCTFail("the cancelled sleep should have thrown")
        } catch is CancellationError {
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    /// A task that ignores cancellation is the case the deadline exists for;
    /// it must still answer, without waiting for the task.
    func testATaskThatIgnoresCancellationDoesNotHoldTheDeadline() async {
        let release = Release()
        let task = Task { await release.held() }
        let started = Date()

        let finished = await task.finished(within: .milliseconds(200))

        XCTAssertFalse(finished)
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
        release.now()
        await task.value
    }

    /// A continuation nothing resumes until `now()`, which no cancellation
    /// can reach — the shape of a thread parked in a kernel wait.
    private final class Release: @unchecked Sendable {
        private let lock = NSLock()
        private var waiting: CheckedContinuation<Void, Never>?
        private var released = false

        func held() async {
            await withCheckedContinuation { continuation in
                lock.lock()
                if released {
                    lock.unlock()
                    continuation.resume()
                } else {
                    waiting = continuation
                    lock.unlock()
                }
            }
        }

        func now() {
            lock.lock()
            released = true
            let waiting = self.waiting
            self.waiting = nil
            lock.unlock()
            waiting?.resume()
        }
    }
}
