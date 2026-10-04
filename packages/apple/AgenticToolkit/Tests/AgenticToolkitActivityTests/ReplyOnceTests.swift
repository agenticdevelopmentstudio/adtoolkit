import XCTest
@testable import AgenticToolkitActivity

private final class Answers: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Int] = []
    func record(_ value: Int) {
        lock.lock()
        defer { lock.unlock() }
        values.append(value)
    }
    var all: [Int] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}

final class ReplyOnceTests: XCTestCase {
    func testDeliversTheAnswer() {
        let answers = Answers()
        let reply = ReplyOnce(fallback: -1) { answers.record($0) }
        reply(7)
        XCTAssertEqual(answers.all, [7])
    }

    func testIgnoresEverySubsequentAnswer() {
        // Answering an XPC reply block twice traps in libxpc, so "ignore" here
        // is the difference between a dropped duplicate and a dead daemon.
        let answers = Answers()
        let reply = ReplyOnce(fallback: -1) { answers.record($0) }
        reply(7)
        reply(8)
        reply(9)
        XCTAssertEqual(answers.all, [7])
    }

    func testAnswersWithTheFallbackWhenReleasedUnanswered() {
        // The dropped-reply case: a closure captures the reply, returns early,
        // and its captures are released. Without this the peer waits forever.
        let answers = Answers()
        do {
            _ = ReplyOnce(fallback: -1) { answers.record($0) }
        }
        XCTAssertEqual(answers.all, [-1])
    }

    func testDoesNotSendTheFallbackAfterAnAnswer() {
        let answers = Answers()
        do {
            let reply = ReplyOnce(fallback: -1) { answers.record($0) }
            reply(7)
        }
        XCTAssertEqual(answers.all, [7], "the answer already went out; the fallback would be a second reply")
    }

    func testDeliversExactlyOnceUnderConcurrentAnswers() {
        let answers = Answers()
        let reply = ReplyOnce(fallback: -1) { answers.record($0) }
        DispatchQueue.concurrentPerform(iterations: 64) { i in reply(i) }
        XCTAssertEqual(answers.all.count, 1, "got \(answers.all)")
    }
}
