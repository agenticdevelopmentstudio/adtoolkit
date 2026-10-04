#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitCore

/// `InMemoryActivityStore` is final, so a failing store wraps one.
private final class FailingOpenStore: ActivityPersistence, @unchecked Sendable {
    let inner = InMemoryActivityStore()
    func openActivitySpan(_ span: ActivitySpanDTO) throws { throw NSError(domain: "t", code: 1) }
    func closeActivitySpan(id: String, endedAt: String) throws { try inner.closeActivitySpan(id: id, endedAt: endedAt) }
    func retitleActivitySpan(id: String, title: String) throws { try inner.retitleActivitySpan(id: id, title: title) }
    func touchActivitySpan(id: String, at: String) throws { try inner.touchActivitySpan(id: id, at: at) }
    func openIdleInterval(from: String) throws { try inner.openIdleInterval(from: from) }
    func closeIdleInterval(until: String) throws { try inner.closeIdleInterval(until: until) }
    func recoverActivity(now: String) throws -> Int { try inner.recoverActivity(now: now) }
    func pruneActivity(endedBefore before: String) throws -> Int { try inner.pruneActivity(endedBefore: before) }
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        try inner.activitySpans(since: since, limit: limit)
    }
    func openActivitySpans() throws -> [ActivitySpanDTO] { try inner.openActivitySpans() }
}

/// Closes land late, as a slow disk would make them.
private final class SlowCloseStore: ActivityPersistence, @unchecked Sendable {
    let inner = InMemoryActivityStore()
    func openActivitySpan(_ span: ActivitySpanDTO) throws { try inner.openActivitySpan(span) }
    func closeActivitySpan(id: String, endedAt: String) throws {
        Thread.sleep(forTimeInterval: 0.2)
        try inner.closeActivitySpan(id: id, endedAt: endedAt)
    }
    func retitleActivitySpan(id: String, title: String) throws { try inner.retitleActivitySpan(id: id, title: title) }
    func touchActivitySpan(id: String, at: String) throws { try inner.touchActivitySpan(id: id, at: at) }
    func openIdleInterval(from: String) throws { try inner.openIdleInterval(from: from) }
    func closeIdleInterval(until: String) throws { try inner.closeIdleInterval(until: until) }
    func recoverActivity(now: String) throws -> Int { try inner.recoverActivity(now: now) }
    func pruneActivity(endedBefore before: String) throws -> Int { try inner.pruneActivity(endedBefore: before) }
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        try inner.activitySpans(since: since, limit: limit)
    }
    func openActivitySpans() throws -> [ActivitySpanDTO] { try inner.openActivitySpans() }
}

/// The first idle close is lost, as a failed write would lose it.
private final class FailingFirstIdleCloseStore: ActivityPersistence, @unchecked Sendable {
    let inner = InMemoryActivityStore()
    private let lock = NSLock()
    private var failed = false
    func openActivitySpan(_ span: ActivitySpanDTO) throws { try inner.openActivitySpan(span) }
    func closeActivitySpan(id: String, endedAt: String) throws { try inner.closeActivitySpan(id: id, endedAt: endedAt) }
    func retitleActivitySpan(id: String, title: String) throws { try inner.retitleActivitySpan(id: id, title: title) }
    func touchActivitySpan(id: String, at: String) throws { try inner.touchActivitySpan(id: id, at: at) }
    func openIdleInterval(from: String) throws { try inner.openIdleInterval(from: from) }
    func closeIdleInterval(until: String) throws {
        let fail = lock.withLock { () -> Bool in
            // Only a close that would close something counts as "the" close.
            guard !failed, inner.idle.contains(where: { $0.until.isEmpty }) else { return false }
            failed = true
            return true
        }
        if fail { throw NSError(domain: "t", code: 3) }
        try inner.closeIdleInterval(until: until)
    }
    func recoverActivity(now: String) throws -> Int { try inner.recoverActivity(now: now) }
    func pruneActivity(endedBefore before: String) throws -> Int { try inner.pruneActivity(endedBefore: before) }
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        try inner.activitySpans(since: since, limit: limit)
    }
    func openActivitySpans() throws -> [ActivitySpanDTO] { try inner.openActivitySpans() }
}

/// An input trigger that can be asked whether the user is present now.
private final class SamplingInputTrigger: ContextTrigger, PresenceSampling {
    let kind: ContextEventKind = .input
    let requiredPermission: ContextPermission = .none
    var onEvent: ((ContextEventDetail, Date) -> Void)?
    var present: Bool?
    init(present: Bool?) { self.present = present }
    func start() throws {}
    func stop() {}
    func samplePresence() -> Bool? { present }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.withLock { value += 1 } }
    var count: Int { lock.withLock { value } }
}

@MainActor
final class WorkActivityRecorderTests: XCTestCase {
    var store: InMemoryActivityStore!
    var recorder: WorkActivityRecorder!
    var clock = Date(timeIntervalSince1970: 1_790_000_000)

    private static func triggers() -> WorkActivityRecorder.Triggers {
        .init(focus: FakeContextTrigger(kind: .appFocus), input: FakeContextTrigger(kind: .input),
              session: FakeContextTrigger(kind: .session), lifecycle: FakeContextTrigger(kind: .appLifecycle))
    }

    override func setUp() async throws {
        store = InMemoryActivityStore()
        let locator = RepoLocator(fileSystem: .init(kind: { $0 == "/r/.git" ? .directory : .missing },
                                                    read: { $0 == "/r/.git/HEAD" ? "ref: refs/heads/main\n" : nil }))
        recorder = WorkActivityRecorder(
            triggers: Self.triggers(),
            allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(locator: locator, knownRoots: { [] }),
            store: store, now: { [unowned self] in self.clock }, timeZone: { TimeZone(identifier: "UTC")! })
    }

    private static func focusDetail(_ bundle: String, path: String?, title: String = "w") -> ContextEventDetail {
        .appFocus(AppFocusDetail(bundleID: bundle, appName: bundle, pid: 1, executablePath: nil,
                                 windowID: nil, windowTitle: title, documentPath: path,
                                 documentSize: nil, documentModifiedAt: nil, documentType: nil, url: nil))
    }

    private static func input(_ change: InputChange, idle: Double? = nil) -> ContextEventDetail {
        .input(InputDetail(change: change, idleSeconds: idle, secondsSinceKey: nil, secondsSinceMouseMove: nil,
                           secondsSinceClick: nil, secondsSinceScroll: nil, keyCountDelta: nil,
                           mouseCountDelta: nil, intervalMs: nil))
    }

    private func focus(_ bundle: String, path: String?, title: String = "w", at offset: TimeInterval) {
        recorder.handle(Self.focusDetail(bundle, path: path, title: title), at: clock.addingTimeInterval(offset))
        recorder.drainWrites()
    }

    func testAllowedFocusOpensASpanWithRepo() {
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertEqual(store.spans.first?.repoRoot, "/r")
        XCTAssertEqual(store.spans.first?.branch, "main")
        XCTAssertEqual(store.spans.first?.tz, TimeZone(identifier: "UTC")!.identifier)
        XCTAssertEqual(recorder.currentSpan?.id, store.spans.first?.id)
    }

    func testNonAllowedAppIsNeverStored() {
        focus("com.apple.Safari", path: "/r/a.html", at: 0)
        XCTAssertTrue(store.spans.isEmpty)
    }

    func testSwitchingToSafariClosesTheSpan() {
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        focus("com.apple.Safari", path: nil, at: 120)
        XCTAssertFalse(store.spans[0].isOpen)
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertNil(recorder.currentSpan)
    }

    func testNewTitleOnSameKeyRetitles() {
        focus("com.apple.dt.Xcode", path: "/r/a.swift", title: "a", at: 0)
        focus("com.apple.dt.Xcode", path: "/r/b.swift", title: "b", at: 30)
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertEqual(store.spans[0].windowTitle, "b")
    }

    func testLockClosesAndUnlockReopens() {
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        recorder.handle(.session(SessionDetail(change: .lock)), at: clock.addingTimeInterval(100))
        recorder.handle(.session(SessionDetail(change: .unlock)), at: clock.addingTimeInterval(200))
        recorder.drainWrites()
        XCTAssertEqual(store.spans.count, 2)
        XCTAssertFalse(store.spans[0].isOpen)
        XCTAssertTrue(store.spans[1].isOpen)
    }

    func testTerminationClosesTheSpan() {
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        recorder.handle(.appLifecycle(AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                                                         appName: "Xcode", pid: 1)),
                        at: clock.addingTimeInterval(60))
        recorder.drainWrites()
        XCTAssertFalse(store.spans[0].isOpen)
    }

    func testIdleIntervalsAreWritten() {
        recorder.handle(Self.input(.inactive), at: clock)
        recorder.handle(Self.input(.active, idle: 300), at: clock.addingTimeInterval(300))
        recorder.drainWrites()
        XCTAssertEqual(store.idle.count, 1)
        XCTAssertFalse(store.idle[0].until.isEmpty)
    }

    func testHeartbeatOnlyWhileInputIsActive() {
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        clock.addTimeInterval(60); recorder.heartbeat(); recorder.drainWrites()
        XCTAssertFalse(store.spans[0].lastSeenAt.isEmpty)
        let seen = store.spans[0].lastSeenAt
        recorder.handle(Self.input(.inactive), at: clock)
        clock.addTimeInterval(60); recorder.heartbeat(); recorder.drainWrites()
        XCTAssertEqual(store.spans[0].lastSeenAt, seen)
    }

    func testStartSeedsPresenceFromTheInputTriggerNotAssumingIt() {
        let rec = WorkActivityRecorder(
            triggers: .init(focus: FakeContextTrigger(kind: .appFocus), input: SamplingInputTrigger(present: false),
                            session: FakeContextTrigger(kind: .session),
                            lifecycle: FakeContextTrigger(kind: .appLifecycle)),
            allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(knownRoots: { [] }),
            store: store, now: { [unowned self] in self.clock })
        rec.start()
        defer { rec.stop() }
        rec.handle(Self.focusDetail("com.apple.dt.Xcode", path: nil), at: clock)
        clock.addTimeInterval(60); rec.heartbeat(); rec.drainWrites()
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertEqual(store.spans[0].lastSeenAt, "", "started while the user was away: no heartbeat")
    }

    func testAStuckOpenIdleIsClosedWhenTheNextIdleOpens() {
        let failing = FailingFirstIdleCloseStore()
        let rec = WorkActivityRecorder(
            triggers: Self.triggers(), allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(knownRoots: { [] }), store: failing,
            now: { [unowned self] in self.clock })
        rec.handle(Self.input(.inactive), at: clock)
        rec.handle(Self.input(.active), at: clock.addingTimeInterval(300))   // this close is lost
        rec.handle(Self.input(.inactive), at: clock.addingTimeInterval(600))
        rec.drainWrites()
        let idle = failing.inner.idle
        XCTAssertEqual(idle.count, 2, "the next idle opens instead of waiting on the stuck one")
        XCTAssertEqual(idle[0].until, UTCTimestamp.string(from: clock.addingTimeInterval(300)),
                       "the stuck idle ends when input resumed")
        XCTAssertEqual(idle[1].from, UTCTimestamp.string(from: clock.addingTimeInterval(600)))
        XCTAssertEqual(idle[1].until, "")
    }

    func testUpdatingAllowlistReevaluatesCurrentFocus() {
        recorder.start()
        defer { recorder.stop() }
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        clock.addTimeInterval(120)
        recorder.update(allowlist: AppAllowlist(preferences: WorkTrackingPreferences(
            enabled: true, addedBundleIds: [], removedBundleIds: ["com.apple.dt.Xcode"], retentionDays: 90)))
        recorder.drainWrites()
        XCTAssertFalse(store.spans[0].isOpen)
        XCTAssertNil(recorder.currentSpan)
    }

    func testWriteFailureIsReportedNotThrown() {
        let failures = Counter()
        let failing = WorkActivityRecorder(
            triggers: Self.triggers(),
            allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(knownRoots: { [] }), store: FailingOpenStore(),
            onWriteFailure: { _ in failures.increment() })
        failing.handle(Self.focusDetail("com.apple.dt.Xcode", path: nil, title: ""), at: Date())
        failing.drainWrites()
        XCTAssertEqual(failures.count, 1)
    }

    func testStopClosesTheOpenSpan() {
        recorder.start()
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        clock.addTimeInterval(90)
        recorder.stop(); recorder.drainWrites()
        XCTAssertFalse(store.spans[0].isOpen)
    }

    /// Shutdown calls `stop()` then `drainWrites()`; the close must have landed
    /// when the drain returns, however slow the store.
    func testDrainAfterStopWaitsForTheClose() throws {
        let slow = SlowCloseStore()
        let start = clock
        let slowRecorder = WorkActivityRecorder(
            triggers: Self.triggers(), allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(knownRoots: { [] }), store: slow,
            now: { start.addingTimeInterval(90) }, timeZone: { TimeZone(identifier: "UTC")! })
        slowRecorder.start()
        slowRecorder.handle(Self.focusDetail("com.apple.dt.Xcode", path: nil, title: "t"), at: start)
        slowRecorder.stop()
        slowRecorder.drainWrites()
        let spans = try slow.openActivitySpans()
        XCTAssertEqual(spans.count, 0, "the close landed before drainWrites returned")
        XCTAssertEqual(slow.inner.spans.count, 1)
        XCTAssertFalse(slow.inner.spans[0].isOpen)
    }

    func testTerminateThenUpdateWritesNothing() {
        recorder.start()
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        recorder.handle(.appLifecycle(AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                                                         appName: "Xcode", pid: 1)), at: clock.addingTimeInterval(60))
        recorder.drainWrites()
        recorder.update(allowlist: AppAllowlist(preferences: .default))
        recorder.drainWrites()
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertFalse(store.spans[0].isOpen)
        XCTAssertNil(recorder.currentSpan)
        recorder.stop()
    }

    func testStopThenUpdateWritesNothing() {
        recorder.start()
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        clock.addTimeInterval(90)
        recorder.stop(); recorder.drainWrites()
        recorder.update(allowlist: AppAllowlist(preferences: .default))
        recorder.drainWrites()
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertFalse(store.spans[0].isOpen)
        XCTAssertNil(recorder.currentSpan)
    }

    func testStopClosesIdleAndRestartHeartbeats() {
        recorder.start()
        recorder.handle(Self.input(.inactive), at: clock)
        clock.addTimeInterval(120)
        recorder.stop(); recorder.drainWrites()
        XCTAssertFalse(store.idle[0].until.isEmpty)
        recorder.start()
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        clock.addTimeInterval(60); recorder.heartbeat(); recorder.drainWrites()
        XCTAssertFalse(store.spans[0].lastSeenAt.isEmpty)
        recorder.stop()
    }

    func testUpdateAddingFrontmostAppOpensSpan() {
        recorder.start()
        focus("com.example.NewIDE", path: "/r/a.swift", at: 0)
        XCTAssertTrue(store.spans.isEmpty)
        recorder.update(allowlist: AppAllowlist(preferences: WorkTrackingPreferences(
            enabled: true, addedBundleIds: ["com.example.NewIDE"], removedBundleIds: [], retentionDays: 90)))
        recorder.drainWrites()
        XCTAssertEqual(store.spans.count, 1)
        XCTAssertEqual(store.spans[0].bundleId, "com.example.NewIDE")
        XCTAssertEqual(store.spans[0].repoRoot, "/r")
        recorder.stop()
    }

    func testStopCancelsHeartbeat() {
        XCTAssertFalse(recorder.isHeartbeatScheduled)
        recorder.start()
        XCTAssertTrue(recorder.isHeartbeatScheduled)
        focus("com.apple.dt.Xcode", path: "/r/a.swift", at: 0)
        clock.addTimeInterval(90)
        recorder.stop(); recorder.drainWrites()
        XCTAssertFalse(recorder.isHeartbeatScheduled)
        clock.addTimeInterval(60); recorder.heartbeat(); recorder.drainWrites()
        XCTAssertTrue(store.spans[0].lastSeenAt.isEmpty)
    }

    func testStartTwiceStartsTriggersOnce() {
        let focusTrigger = FakeContextTrigger(kind: .appFocus)
        let rec = WorkActivityRecorder(
            triggers: .init(focus: focusTrigger, input: FakeContextTrigger(kind: .input),
                            session: FakeContextTrigger(kind: .session),
                            lifecycle: FakeContextTrigger(kind: .appLifecycle)),
            allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(knownRoots: { [] }), store: store)
        rec.start(); rec.start()
        XCTAssertEqual(focusTrigger.startCount, 1)
        rec.stop()
    }

    func testStartSkipsAThrowingTrigger() {
        let bad = FakeContextTrigger(kind: .input)
        bad.startError = NSError(domain: "t", code: 2)
        let good = FakeContextTrigger(kind: .session)
        let rec = WorkActivityRecorder(
            triggers: .init(focus: FakeContextTrigger(kind: .appFocus), input: bad, session: good,
                            lifecycle: FakeContextTrigger(kind: .appLifecycle)),
            allowlist: AppAllowlist(preferences: .default),
            resolver: WorkingPathResolver(knownRoots: { [] }), store: store)
        rec.start()
        XCTAssertEqual(good.startCount, 1)
        rec.stop()
        XCTAssertEqual(good.stopCount, 1)
    }
}
#endif
