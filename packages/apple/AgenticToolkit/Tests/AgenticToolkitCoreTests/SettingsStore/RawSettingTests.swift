import XCTest
import OSLog
@testable import AgenticToolkitCore

final class RawSettingTests: XCTestCase {

    func testBoolReadsEverySpellingAndFallsBackOnGarbage() {
        for raw in ["1", "true", " YES ", "on"] {
            XCTAssertTrue(RawSetting.bool(raw, default: false), raw)
        }
        for raw in ["0", "False", "no", "OFF"] {
            XCTAssertFalse(RawSetting.bool(raw, default: true), raw)
        }
        XCTAssertTrue(RawSetting.bool(nil, default: true))
        XCTAssertFalse(RawSetting.bool("maybe", default: false))
    }

    func testIntClampsIntoRangeAndFallsBackWhenAbsent() {
        XCTAssertEqual(RawSetting.int(" 30 ", default: 15, range: 1...240), 30)
        XCTAssertEqual(RawSetting.int("0", default: 15, range: 1...240), 1)
        XCTAssertEqual(RawSetting.int("9999", default: 15, range: 1...240), 240)
        XCTAssertEqual(RawSetting.int("abc", default: 15, range: 1...240), 15)
        XCTAssertEqual(RawSetting.int(nil, default: 15, range: 1...240), 15)
    }

    func testStringTrimsAndFallsBackWhenEmpty() {
        XCTAssertEqual(RawSetting.string(" day ", default: "session"), "day")
        XCTAssertEqual(RawSetting.string("   ", default: "session"), "session")
        XCTAssertEqual(RawSetting.string(nil, default: "session"), "session")
    }
}

@MainActor
final class SettingsSnapshotPushTests: XCTestCase {

    private actor Received {
        var bodies: [Data] = []
        var failuresLeft: Int
        init(failures: Int) { failuresLeft = failures }
        func take(_ body: Data) -> Bool {
            if failuresLeft > 0 {
                failuresLeft -= 1
                return false
            }
            bodies.append(body)
            return true
        }
    }

    private let logger = Logger(subsystem: "AgenticToolkitCoreTests", category: "SettingsSnapshotPush")

    func testPushesOnStartAndOnEveryReconnect() async {
        let received = Received(failures: 0)
        var reconnect: (@Sendable () -> Void)?
        var value = 1
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0],
            snapshot: { SettingsSnapshotPush.encodeSorted(["value": value]) },
            send: { await received.take($0) },
            registerReconnect: { reconnect = $0 }
        )

        push.start(makeObservers: { _ in [] })
        await push.awaitPendingPush()
        XCTAssertTrue(push.isObserving)
        var bodies = await received.bodies
        XCTAssertEqual(bodies, [Data(#"{"value":1}"#.utf8)])

        value = 2
        reconnect?()
        let deadline = Date().addingTimeInterval(5)
        while await received.bodies.count < 2, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        bodies = await received.bodies
        XCTAssertEqual(bodies.last, Data(#"{"value":2}"#.utf8))
    }

    func testRetriesABoundedNumberOfTimes() async {
        let received = Received(failures: 2)
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0, 1_000_000, 1_000_000],
            snapshot: { Data("{}".utf8) },
            send: { await received.take($0) },
            registerReconnect: { _ in }
        )
        push.push()
        await push.awaitPendingPush()
        let bodies = await received.bodies
        XCTAssertEqual(bodies.count, 1, "the third attempt lands")
    }

    func testAStoppedPushIgnoresReconnects() async throws {
        let received = Received(failures: 0)
        var reconnect: (@Sendable () -> Void)?
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0],
            snapshot: { Data("{}".utf8) },
            send: { await received.take($0) },
            registerReconnect: { reconnect = $0 }
        )
        push.start(makeObservers: { _ in [] })
        await push.awaitPendingPush()
        push.stop()
        reconnect?()
        try await Task.sleep(for: .milliseconds(50))
        let bodies = await received.bodies
        XCTAssertEqual(bodies.count, 1)
    }

    /// Counts sends; every one fails, and — like DaemonKit's XPCClient against
    /// a missing Mach service — each failed send's next connection fires the
    /// reconnect handler before the failure comes back.
    private final class DroppingReceiver: @unchecked Sendable {
        private let lock = NSLock()
        private var sendCount = 0
        var reconnect: (@Sendable () -> Void)?
        var sends: Int { lock.withLock { sendCount } }
        func take() async -> Bool {
            lock.withLock { sendCount += 1 }
            reconnect?()
            try? await Task.sleep(for: .milliseconds(20))
            return false
        }
    }

    /// Review F11: a reconnect fired by the push's own failing attempts must not
    /// restart it, or the bounded retry never gives up and the push loops for as
    /// long as the receiver is gone.
    func testAReconnectDuringAFailingPushDoesNotRestartIt() async throws {
        let receiver = DroppingReceiver()
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0, 1_000_000, 1_000_000],
            reconnectDelay: { _ in 60_000_000_000 },
            snapshot: { Data("{}".utf8) },
            send: { _ in await receiver.take() },
            registerReconnect: { receiver.reconnect = $0 }
        )
        push.start(makeObservers: { _ in [] })
        try await Task.sleep(for: .milliseconds(600))
        let sends = receiver.sends
        let failures = push.consecutiveFailures
        push.stop()
        XCTAssertEqual(sends, 3, "one bounded push of three attempts, then it gives up")
        XCTAssertEqual(failures, 1)
    }

    /// After a failed push a reconnect does not push at once: the backed-off
    /// retry is already waiting, so the reconnect is ignored. After a success
    /// a reconnect pushes at once.
    func testAReconnectWaitsOutTheBackoffAfterAFailureButNotAfterASuccess() async throws {
        let receiver = Received(failures: 1)
        let delays = DelayLog()
        var reconnect: (@Sendable () -> Void)?
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0],
            reconnectDelay: { failures in delays.append(failures); return 40_000_000 },
            snapshot: { Data("{}".utf8) },
            send: { await receiver.take($0) },
            registerReconnect: { reconnect = $0 }
        )
        push.start(makeObservers: { _ in [] })
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertEqual(push.consecutiveFailures, 1)
        reconnect?()
        try await Task.sleep(for: .milliseconds(10))
        var bodies = await receiver.bodies
        XCTAssertEqual(bodies.count, 0, "the reconnect did not jump the backoff")
        await settle(push)
        XCTAssertEqual(push.consecutiveFailures, 0, "the backed-off retry landed")
        XCTAssertEqual(delays.values, [1])

        reconnect?()
        await settle(push)
        XCTAssertEqual(delays.values, [1], "after a success a reconnect pushes at once")
        bodies = await receiver.bodies
        XCTAssertEqual(bodies.count, 2)
        push.stop()
    }

    /// Review N3: a push that gives up while observing re-tries on its own,
    /// with the backoff growing per failure — no reconnect needed — and lands
    /// once the receiver is back.
    func testAnUndeliveredPushRetriesItselfWithGrowingBackoff() async throws {
        let receiver = Received(failures: 2)
        let delays = DelayLog()
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0],
            reconnectDelay: { failures in delays.append(failures); return 1_000_000 },
            snapshot: { Data("{}".utf8) },
            send: { await receiver.take($0) },
            registerReconnect: { _ in }   // no reconnect ever fires
        )
        push.start(makeObservers: { _ in [] })
        let deadline = Date().addingTimeInterval(5)
        while await receiver.bodies.isEmpty, Date() < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        await settle(push)
        let bodies = await receiver.bodies
        XCTAssertEqual(bodies.count, 1, "the third, self-scheduled push lands")
        XCTAssertEqual(delays.values, [1, 2], "each retry waited for one more failure than the last")
        XCTAssertEqual(push.consecutiveFailures, 0)
        push.stop()
    }

    /// Review N3: `stop()` cancels a pending self-retry.
    func testStopCancelsTheSelfRetry() async throws {
        let receiver = Received(failures: 1)
        let push = SettingsSnapshotPush(
            label: "Test", logger: logger, backoffs: [0],
            reconnectDelay: { _ in 30_000_000 },
            snapshot: { Data("{}".utf8) },
            send: { await receiver.take($0) },
            registerReconnect: { _ in }
        )
        push.start(makeObservers: { _ in [] })
        try await Task.sleep(for: .milliseconds(10))
        push.stop()
        try await Task.sleep(for: .milliseconds(80))
        let bodies = await receiver.bodies
        XCTAssertEqual(bodies.count, 0, "the retry was cancelled with the push")
    }

    func testTheDefaultReconnectDelayDoublesToACap() {
        let delay = SettingsSnapshotPush.defaultReconnectDelay
        XCTAssertEqual((1...8).map { delay($0) / 1_000_000_000 }, [1, 2, 4, 8, 16, 30, 30, 30])
    }

    private final class DelayLog: @unchecked Sendable {
        private let lock = NSLock()
        private var log: [Int] = []
        var values: [Int] { lock.withLock { log } }
        func append(_ value: Int) { lock.withLock { log.append(value) } }
    }

    /// Lets the reconnect hop onto the main actor, then awaits what it started.
    private func settle(_ push: SettingsSnapshotPush) async {
        for _ in 0..<5 { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(10))
        await push.awaitPendingPush()
    }

    func testEncodesWithSortedKeys() {
        let body = SettingsSnapshotPush.encodeSorted(["b": "2", "a": "1"])
        XCTAssertEqual(body, Data(#"{"a":"1","b":"2"}"#.utf8))
    }
}
