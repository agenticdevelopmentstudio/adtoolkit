#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitCore

/// A `WorkTrackingPersistence` in memory: the activity tables are an
/// `InMemoryActivityStore`, the settings a dictionary.
private final class MemoryWorkTrackingStore: WorkTrackingPersistence, @unchecked Sendable {
    struct Refused: Error {}
    let activity = InMemoryActivityStore()
    private let lock = NSLock()
    private var settings: [String: String] = [:]
    private var roots: [String] = []
    private var rootsError: Error?
    private var cutoffs: [String] = []

    var knownRoots: [String] {
        get { lock.withLock { roots } }
        set { lock.withLock { roots = newValue } }
    }
    var knownRootsError: Error? {
        get { lock.withLock { rootsError } }
        set { lock.withLock { rootsError = newValue } }
    }
    var askedCutoffs: [String] { lock.withLock { cutoffs } }

    func setting(for key: String) throws -> String? { lock.withLock { settings[key] } }
    func setSetting(_ key: String, _ value: String) throws { lock.withLock { settings[key] = value } }
    func transaction<T>(_ body: () throws -> T) throws -> T { try body() }

    func knownRepoRoots(activeSince cutoff: String) throws -> [String] {
        try lock.withLock {
            cutoffs.append(cutoff)
            if let rootsError { throw rootsError }
            return roots
        }
    }

    func openActivitySpan(_ span: ActivitySpanDTO) throws { try activity.openActivitySpan(span) }
    func closeActivitySpan(id: String, endedAt: String) throws { try activity.closeActivitySpan(id: id, endedAt: endedAt) }
    func retitleActivitySpan(id: String, title: String) throws { try activity.retitleActivitySpan(id: id, title: title) }
    func touchActivitySpan(id: String, at: String) throws { try activity.touchActivitySpan(id: id, at: at) }
    func openIdleInterval(from: String) throws { try activity.openIdleInterval(from: from) }
    func closeIdleInterval(until: String) throws { try activity.closeIdleInterval(until: until) }
    func recoverActivity(now: String) throws -> Int { try activity.recoverActivity(now: now) }
    func pruneActivity(endedBefore before: String) throws -> Int { try activity.pruneActivity(endedBefore: before) }
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        try activity.activitySpans(since: since, limit: limit)
    }
    func openActivitySpans() throws -> [ActivitySpanDTO] { try activity.openActivitySpans() }
}

/// Every write throws, so the recorder reports each one as a failure.
private final class ThrowingStore: ActivityPersistence, @unchecked Sendable {
    struct Refused: Error {}
    func openActivitySpan(_ span: ActivitySpanDTO) throws { throw Refused() }
    func closeActivitySpan(id: String, endedAt: String) throws { throw Refused() }
    func retitleActivitySpan(id: String, title: String) throws { throw Refused() }
    func touchActivitySpan(id: String, at seenAt: String) throws { throw Refused() }
    func openIdleInterval(from: String) throws { throw Refused() }
    func closeIdleInterval(until: String) throws { throw Refused() }
    func recoverActivity(now: String) throws -> Int { throw Refused() }
    func pruneActivity(endedBefore before: String) throws -> Int { throw Refused() }
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] { throw Refused() }
    func openActivitySpans() throws -> [ActivitySpanDTO] { throw Refused() }
}

/// Writes through, but each span close takes a while to land — so a caller
/// that does not drain the recorder sees the span still open.
private final class SlowCloseStore: ActivityPersistence, @unchecked Sendable {
    let base: any ActivityPersistence
    init(_ base: any ActivityPersistence) { self.base = base }
    func openActivitySpan(_ span: ActivitySpanDTO) throws { try base.openActivitySpan(span) }
    func closeActivitySpan(id: String, endedAt: String) throws {
        Thread.sleep(forTimeInterval: 0.3)
        try base.closeActivitySpan(id: id, endedAt: endedAt)
    }
    func retitleActivitySpan(id: String, title: String) throws { try base.retitleActivitySpan(id: id, title: title) }
    func touchActivitySpan(id: String, at seenAt: String) throws { try base.touchActivitySpan(id: id, at: seenAt) }
    func openIdleInterval(from: String) throws { try base.openIdleInterval(from: from) }
    func closeIdleInterval(until: String) throws { try base.closeIdleInterval(until: until) }
    func recoverActivity(now: String) throws -> Int { try base.recoverActivity(now: now) }
    func pruneActivity(endedBefore before: String) throws -> Int { try base.pruneActivity(endedBefore: before) }
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        try base.activitySpans(since: since, limit: limit)
    }
    func openActivitySpans() throws -> [ActivitySpanDTO] { try base.openActivitySpans() }
}

/// One recorder the controller asked the test factory for, with its fakes.
@MainActor
private struct BuiltRecorder {
    let readsWindows: Bool
    let prefs: WorkTrackingPreferences
    let focus: FakeContextTrigger
    let triggers: [FakeContextTrigger]
    let recorder: WorkActivityRecorder
    /// What the controller handed the factory for the focus adapter to call.
    let onAccessibilityRevoked: @MainActor () -> Void

    var allStarted: Bool { triggers.allSatisfy { $0.startCount == 1 } }
    var allStopped: Bool { triggers.allSatisfy { $0.stopCount == 1 } }
    var noneStopped: Bool { triggers.allSatisfy { $0.stopCount == 0 } }
}

/// The work-tracking policy (review F14: moved from the daemon). Nothing here
/// starts a live trigger or calls the live AX check.
@MainActor
final class WorkTrackingControllerTests: XCTestCase {
    private var store: MemoryWorkTrackingStore!
    /// This build's signature, as the controller under test reads it.
    static let signer = "identifier \"com.example.test\" and anchor apple generic"
    var signer: String? = WorkTrackingControllerTests.signer
    var axCalls = 0
    var axAnswer: WorkTrackingAccessibility = .granted
    /// Runs inside the AX check, before it answers: the seam for races.
    var duringAXCheck: (() async -> Void)?
    /// The store recorders write to; the controller's store unless a test swaps it.
    var recorderStore: (any ActivityPersistence)?
    /// When set, the controller's preference read throws this.
    var prefsLoadError: Error?
    var prefsLoads = 0
    /// Seconds before each preference-read retry; large keeps retries out of a test.
    var retryDelay: TimeInterval = 3600
    private var built: [BuiltRecorder] = []
    var builtReadsWindows: [Bool] { built.map(\.readsWindows) }

    override func setUp() async throws {
        store = MemoryWorkTrackingStore()
    }

    override func tearDown() async throws {
        built = []
        store = nil
    }

    private func controller(now: @escaping @Sendable () -> Date = Date.init) -> WorkTrackingController {
        let delay = retryDelay
        return WorkTrackingController(
            database: store,
            checkAccessibility: { [unowned self] in
                self.axCalls += 1
                await self.duringAXCheck?()
                return self.axAnswer
            },
            makeRecorder: { [unowned self] reads, prefs, onWriteFailure, onRevoked in
                let triggers = [ContextEventKind.appFocus, .input, .session, .appLifecycle]
                    .map { FakeContextTrigger(kind: $0) }
                let recorder = WorkActivityRecorder(
                    triggers: .init(focus: triggers[0], input: triggers[1],
                                    session: triggers[2], lifecycle: triggers[3]),
                    allowlist: AppAllowlist(preferences: prefs),
                    resolver: WorkingPathResolver(knownRoots: { [] }),
                    store: self.recorderStore ?? self.store,
                    onWriteFailure: onWriteFailure)
                self.built.append(BuiltRecorder(readsWindows: reads, prefs: prefs, focus: triggers[0],
                                                triggers: triggers, recorder: recorder,
                                                onAccessibilityRevoked: onRevoked))
                return recorder
            },
            loadPrefs: { [unowned self] database in
                self.prefsLoads += 1
                if let error = self.prefsLoadError { throw error }
                return try WorkTrackingPrefs.load(database)
            },
            retryDelay: { _ in delay },
            now: now,
            signer: { [signer] in signer })
    }

    /// Lets the controller's deferred main-actor work run.
    private func settle(until done: () -> Bool) async throws {
        for _ in 0..<200 where !done() { try await Task.sleep(nanoseconds: 5_000_000) }
    }

    private func enabledPrefs(added: [String] = []) -> WorkTrackingPreferences {
        .init(enabled: true, addedBundleIds: added, removedBundleIds: [], retentionDays: 90)
    }

    private func focusXcode(_ entry: BuiltRecorder, at date: Date) {
        let detail = AppFocusDetail(bundleID: "com.apple.dt.Xcode", appName: "Xcode", pid: 1, executablePath: nil,
                                    windowID: nil, windowTitle: "w", documentPath: nil, documentSize: nil,
                                    documentModifiedAt: nil, documentType: nil, url: nil)
        entry.focus.onEvent?(.appFocus(detail), date)
    }

    // MARK: - AX policy at start

    func testDisabledStartNeverChecksAX() async throws {
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: Self.signer, store)
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(axCalls, 0, "tracking off: AX is never asked, even after a stored grant")
        XCTAssertEqual(builtReadsWindows, [])
        XCTAssertFalse(ctl.status().enabled)
    }

    func testUngrantedStartsWithoutWindowReads() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: Self.signer, store)
        await controller().start()
        XCTAssertEqual(axCalls, 0, "a denied answer is never re-asked at start")
        XCTAssertEqual(builtReadsWindows, [false])
        XCTAssertTrue(built[0].allStarted)
    }

    func testUnknownStoredAnswerIsNeverCheckedAtStart() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(axCalls, 0, "never asked before: start must not be the first to ask")
        XCTAssertEqual(builtReadsWindows, [false])
        XCTAssertEqual(ctl.status().accessibility, .unknown)
    }

    /// Review N1: a stored grant is trusted, never re-asked — the grant may be
    /// gone (re-signed build, revoked while the daemon was down) and asking
    /// from a process without it stalls tccd and freezes the machine.
    func testGrantedLastTimeIsTrustedAtStartNeverReAsked() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: Self.signer, store)
        axAnswer = .denied
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(axCalls, 0, "start never asks for the AX state")
        XCTAssertEqual(builtReadsWindows, [true], "the stored grant decides window reads")
        XCTAssertEqual(ctl.status().accessibility, .granted)
        ctl.stop()
    }

    /// Review N1: the injected trust check is counted across a first start,
    /// a restart with `granted` stored, and the prefs-retry recovery path —
    /// zero calls on all three. A stale grant is corrected by the window
    /// read's own denial, still without asking.
    func testAXTrustIsNeverAskedOnStartRestartOrPrefsRetry() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: Self.signer, store)
        axAnswer = .denied

        let first = controller()
        await first.start()
        XCTAssertEqual(axCalls, 0, "first start")
        first.stop()

        let restarted = controller()
        await restarted.start()
        XCTAssertEqual(axCalls, 0, "restart with granted stored")
        XCTAssertEqual(builtReadsWindows, [true, true])
        restarted.stop()

        struct Broken: Error {}
        prefsLoadError = Broken()
        retryDelay = 0.01
        let retrying = controller()
        await retrying.start()
        try await settle { prefsLoads >= 2 }
        prefsLoadError = nil
        try await settle { built.count == 3 }
        XCTAssertEqual(builtReadsWindows, [true, true, true], "the retry trusts the stored grant")
        XCTAssertEqual(axCalls, 0, "prefs-retry recovery")

        // The grant was stale: the window read answers kAXErrorAPIDisabled.
        built[2].onAccessibilityRevoked()
        try await settle { built.count == 4 }
        XCTAssertEqual(builtReadsWindows, [true, true, true, false], "revoked: restarted app-only")
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(store), .denied)
        XCTAssertEqual(axCalls, 0, "the revocation never asks either")
        retrying.stop()
    }

    /// Review D1: TCC keys a grant to the designated requirement, so a grant
    /// recorded by a build signed otherwise (Apple Development → Developer
    /// ID) may be gone. It is not trusted: the recorder starts app-only, and
    /// nothing — no trust check, no window read — makes an AX call.
    func testAGrantRecordedUnderAnotherSignatureStartsAppOnlyWithoutAsking() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: "identifier \"old\"", store)
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(axCalls, 0)
        XCTAssertEqual(builtReadsWindows, [false], "an unconfirmed grant makes no window read")
        XCTAssertEqual(ctl.status().accessibility, .unknown)
        ctl.stop()
    }

    /// A grant stored before signatures were recorded, or by a build whose
    /// signature could not be read, is not known to hold either.
    func testAGrantWithNoRecordedSignatureIsNotTrusted() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try store.setSetting(WorkTrackingSettingsKeys.accessibilityLastStatus, "granted")
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(axCalls, 0)
        XCTAssertEqual(builtReadsWindows, [false])
        ctl.stop()
    }

    /// An unreadable signature of our own confirms no grant at all.
    func testAnUnreadableOwnSignatureTrustsNoGrant() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: Self.signer, store)
        signer = nil
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(axCalls, 0)
        XCTAssertEqual(builtReadsWindows, [false])
        ctl.stop()
    }

    /// The unconfirmed grant is restored by the explicit recheck, which then
    /// records it under this signature so the next start trusts it.
    func testARecheckReconfirmsAGrantUnderThisSignature() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: "identifier \"old\"", store)
        let ctl = controller()
        await ctl.start()
        _ = await ctl.recheckAccessibility()
        XCTAssertEqual(axCalls, 1)
        XCTAssertEqual(builtReadsWindows, [false, true], "the confirmed grant restarts with window reads")
        ctl.stop()

        let next = controller()
        await next.start()
        XCTAssertEqual(axCalls, 1, "the next start trusts it without asking")
        XCTAssertEqual(builtReadsWindows, [false, true, true])
        next.stop()
    }

    /// Turning tracking on records the answer under this signature.
    func testTurningOnRecordsTheAnswerUnderThisSignature() async throws {
        let ctl = controller()
        await ctl.start()
        _ = try await ctl.apply(enabledPrefs())
        XCTAssertEqual(try store.setting(for: WorkTrackingSettingsKeys.accessibilitySigner), Self.signer)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(store, signer: Self.signer), .granted)
        ctl.stop()
    }

    // MARK: - apply

    func testTurningOnChecksOnceAndTurningOffStops() async throws {
        let ctl = controller()
        await ctl.start()
        var turnedOn = WorkTrackingPreferences.default
        turnedOn.enabled = true
        let status = try await ctl.apply(turnedOn)
        XCTAssertEqual(axCalls, 1)
        XCTAssertTrue(status.enabled)
        XCTAssertEqual(status.accessibility, .granted)
        XCTAssertEqual(builtReadsWindows, [true])
        XCTAssertTrue(built[0].allStarted)
        _ = try await ctl.apply(turnedOn)   // still on: no new check, no new recorder
        XCTAssertEqual(axCalls, 1)
        XCTAssertEqual(builtReadsWindows, [true])
        XCTAssertTrue(built[0].noneStopped)
        var off = turnedOn
        off.enabled = false
        let offStatus = try await ctl.apply(off)
        XCTAssertFalse(offStatus.enabled)
        XCTAssertTrue(built[0].allStopped, "turning off stops the recorder's triggers")
        XCTAssertEqual(axCalls, 1, "turning off never checks")
        XCTAssertFalse(try WorkTrackingPrefs.load(store).enabled)
    }

    func testListOnlyApplyAfterStopNeverChecksAX() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        let ctl = controller()
        await ctl.start()
        ctl.stop()
        _ = try await ctl.apply(enabledPrefs(added: ["com.example.editor"]))
        XCTAssertEqual(axCalls, 0)
        XCTAssertEqual(builtReadsWindows, [false], "no recorder after stop")
        XCTAssertEqual(try WorkTrackingPrefs.load(store).addedBundleIds, ["com.example.editor"], "still saved")
    }

    func testListOnlyApplyBeforeStartNeverChecksAX() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        let ctl = controller()
        _ = try await ctl.apply(enabledPrefs(added: ["com.example.editor"]))
        XCTAssertEqual(axCalls, 0)
        XCTAssertEqual(builtReadsWindows, [], "the pending start builds the recorder")
        await ctl.start()
        XCTAssertEqual(axCalls, 0)
        XCTAssertEqual(builtReadsWindows, [false])
        XCTAssertEqual(built[0].prefs.addedBundleIds, ["com.example.editor"])
    }

    func testStopDuringTheTurnOnCheckBuildsNoRecorder() async throws {
        let ctl = controller()
        await ctl.start()
        duringAXCheck = { ctl.stop() }
        _ = try await ctl.apply(enabledPrefs())
        XCTAssertEqual(axCalls, 1)
        XCTAssertEqual(builtReadsWindows, [])
    }

    // MARK: - recheck

    func testRecheckRestartsWithWindowReadsWhenGranted() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: Self.signer, store)
        let ctl = controller()
        await ctl.start()
        axAnswer = .granted
        let status = await ctl.recheckAccessibility()
        XCTAssertEqual(status.accessibility, .granted)
        XCTAssertEqual(builtReadsWindows, [false, true])
        XCTAssertTrue(built[0].allStopped, "the old recorder is stopped")
        XCTAssertTrue(built[1].allStarted, "the new recorder is started")
        XCTAssertTrue(built[1].noneStopped)
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(store), .granted)
    }

    func testRecheckWithUnchangedAnswerKeepsTheRecorder() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: Self.signer, store)
        let ctl = controller()
        await ctl.start()
        axAnswer = .denied
        _ = await ctl.recheckAccessibility()
        XCTAssertEqual(axCalls, 1)
        XCTAssertEqual(builtReadsWindows, [false])
        XCTAssertTrue(built[0].noneStopped)
    }

    func testRecheckRestartDrainsTheOldRecorderFirst() async throws {
        recorderStore = SlowCloseStore(store)
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: Self.signer, store)
        let ctl = controller()
        await ctl.start()
        focusXcode(built[0], at: Date().addingTimeInterval(-120))
        built[0].recorder.drainWrites()
        XCTAssertEqual(try store.openActivitySpans().count, 1)
        axAnswer = .granted
        _ = await ctl.recheckAccessibility()
        XCTAssertEqual(builtReadsWindows, [false, true])
        // No drain here: the restart itself must have waited for the old close.
        XCTAssertEqual(try store.openActivitySpans().count, 0, "the old span's close landed before the restart")
        ctl.stop()
    }

    // MARK: - Accessibility withdrawn mid-run

    func testRevokedAccessibilityStoresDeniedAndRestartsAppOnlyWithoutAskingAX() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: Self.signer, store)
        axAnswer = .granted
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(builtReadsWindows, [true])
        let callsBefore = axCalls

        built[0].onAccessibilityRevoked()
        try await settle { builtReadsWindows.count == 2 }

        XCTAssertEqual(builtReadsWindows, [true, false], "restarted with window reads off")
        XCTAssertTrue(built[0].allStopped)
        XCTAssertTrue(built[1].allStarted)
        XCTAssertEqual(ctl.status().accessibility, .denied)
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(store), .denied)
        XCTAssertEqual(axCalls, callsBefore, "the revocation path never asks for the AX state")

        built[0].onAccessibilityRevoked()   // a late duplicate from the old adapter
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(builtReadsWindows, [true, false], "a second report restarts nothing")
        ctl.stop()
    }

    // MARK: - prefs load failure (review F22)

    func testPrefsLoadFailureAtStartLetsTheNextApplyStartTheRecorder() async throws {
        struct Broken: Error {}
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        prefsLoadError = Broken()
        let ctl = controller()
        await ctl.start()
        XCTAssertEqual(builtReadsWindows, [], "nothing readable: nothing started")
        prefsLoadError = nil
        _ = try await ctl.apply(enabledPrefs())
        XCTAssertEqual(builtReadsWindows.count, 1, "the apply starts the recorder start() never did")
        XCTAssertTrue(built[0].allStarted)
        XCTAssertEqual(axCalls, 0, "stored on → on is no turn-on, and nothing stored a grant")
        XCTAssertNil(ctl.status().lastError)
        ctl.stop()
    }

    func testPrefsLoadFailureAtStartIsReportedNotTakenAsOff() async throws {
        struct Broken: Error {}
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        prefsLoadError = Broken()
        let ctl = controller()
        await ctl.start()
        let status = ctl.status()
        XCTAssertTrue(status.lastError?.hasPrefix("loading preferences") ?? false, "\(status)")
        ctl.stop()
    }

    func testPrefsLoadFailureAtStartIsRetriedAndRecoversTrustingTheStoredGrant() async throws {
        struct Broken: Error {}
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: Self.signer, store)
        prefsLoadError = Broken()
        retryDelay = 0.01
        let ctl = controller()
        await ctl.start()
        try await settle { prefsLoads >= 3 }
        XCTAssertEqual(builtReadsWindows, [], "still failing: still nothing started")
        prefsLoadError = nil
        try await settle { !built.isEmpty }
        XCTAssertEqual(builtReadsWindows, [true], "recovered with no app push: the stored grant trusted")
        XCTAssertEqual(axCalls, 0, "the retry path never asks for the AX state (review N1)")
        XCTAssertNil(ctl.status().lastError)
        XCTAssertTrue(ctl.status().enabled)
        ctl.stop()
    }

    func testARetryNeverReAsksAStoredDenial() async throws {
        struct Broken: Error {}
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: Self.signer, store)
        prefsLoadError = Broken()
        retryDelay = 0.01
        let ctl = controller()
        await ctl.start()
        prefsLoadError = nil
        try await settle { !built.isEmpty }
        XCTAssertEqual(builtReadsWindows, [false])
        XCTAssertEqual(axCalls, 0)
        ctl.stop()
    }

    /// The app re-pushes while the stored state is still unreadable: it is
    /// not known to be a turn-on, so a stored denial is trusted, never re-asked.
    func testAnApplyWhileStillUnreadableTrustsAStoredDenial() async throws {
        struct Broken: Error {}
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: Self.signer, store)
        prefsLoadError = Broken()
        let ctl = controller()
        await ctl.start()
        _ = try await ctl.apply(enabledPrefs())
        XCTAssertEqual(axCalls, 0, "a stored denial is never re-asked")
        XCTAssertEqual(builtReadsWindows, [false])
        ctl.stop()
    }

    func testStopEndsThePrefsRetry() async throws {
        struct Broken: Error {}
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        prefsLoadError = Broken()
        retryDelay = 0.01
        let ctl = controller()
        await ctl.start()
        ctl.stop()
        let loads = prefsLoads
        prefsLoadError = nil
        try await Task.sleep(nanoseconds: 80_000_000)
        XCTAssertEqual(prefsLoads, loads, "no retry after stop")
        XCTAssertEqual(builtReadsWindows, [])
    }

    // MARK: - lifecycle

    func testStartRecoversOpenSpans() async throws {
        try store.openActivitySpan(ActivitySpanDTO(id: "s", bundleId: "x", appName: "X",
                                                   startedAt: "2026-10-01T09:00:00Z", tz: "UTC"))
        try store.touchActivitySpan(id: "s", at: "2026-10-01T09:05:00Z")
        await controller().start()
        XCTAssertEqual(try store.openActivitySpans().count, 0)
    }

    func testStopBeforeStartNeverStartsARecorder() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        let ctl = controller()
        ctl.stop()
        await ctl.start()
        XCTAssertEqual(builtReadsWindows, [])
        XCTAssertEqual(axCalls, 0)
    }

    func testStopStopsTheTriggersAndTheCloseHasLandedOnReturn() async throws {
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        let ctl = controller()
        await ctl.start()
        focusXcode(built[0], at: Date().addingTimeInterval(-120))
        XCTAssertNotNil(ctl.status().currentSpan)
        ctl.stop()
        XCTAssertTrue(built[0].allStopped)
        // No drain here: `stop()` itself must have waited for the close.
        XCTAssertEqual(try store.openActivitySpans().count, 0)
        XCTAssertEqual(try store.activitySpans(since: "2000-01-01T00:00:00Z", limit: 10).count, 1)
        XCTAssertNil(ctl.status().currentSpan)
    }

    // MARK: - prefs

    func testSaveAndApplyNormalizeThePreferences() async throws {
        let messy = WorkTrackingPreferences(enabled: true,
                                            addedBundleIds: ["com.b", "com.a", "com.b"],
                                            removedBundleIds: ["z.y", "a.b", "z.y", "a.b"],
                                            retentionDays: 1)
        let expected = WorkTrackingPreferences(enabled: true, addedBundleIds: ["com.a", "com.b"],
                                               removedBundleIds: ["a.b", "z.y"],
                                               retentionDays: WorkTrackingPreferences.retentionDaysRange.lowerBound)

        try WorkTrackingPrefs.save(messy, store)
        XCTAssertEqual(try WorkTrackingPrefs.load(store), expected, "save stores normalized values")
        XCTAssertEqual(try store.setting(for: WorkTrackingSettingsKeys.addedBundleIds), #"["com.a","com.b"]"#)

        try WorkTrackingPrefs.save(.default, store)
        let ctl = controller()
        await ctl.start()
        _ = try await ctl.apply(messy)
        XCTAssertEqual(try WorkTrackingPrefs.load(store), expected, "apply stores normalized values")
        XCTAssertEqual(ctl.preferences, expected, "apply applies normalized values")
        XCTAssertEqual(built.map(\.prefs), [expected], "the recorder is built from normalized values")
    }

    func testLoadDefaultsWhenUnset() throws {
        XCTAssertEqual(try WorkTrackingPrefs.load(store), .default)
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(store), .unknown)
    }

    // MARK: - status

    func testRecorderWriteFailuresAreCountedInStatus() async throws {
        recorderStore = ThrowingStore()
        try WorkTrackingPrefs.save(enabledPrefs(), store)
        let ctl = controller()
        await ctl.start()
        focusXcode(built[0], at: Date())
        built[0].recorder.drainWrites()
        // The handler counts on the main actor via a Task; let it run.
        for _ in 0..<200 where ctl.status().writeFailures == 0 {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTAssertEqual(ctl.status().writeFailures, 1)
        XCTAssertTrue(ctl.status().lastError?.contains("Refused") ?? false)
        ctl.stop()
    }

    // MARK: - knownRoots

    /// Review F32: the cutoff comes from the injected clock, so the window's
    /// edge does not depend on the time of day the suite runs.
    func testKnownRootsAskForTheLastThirtyDaysFromTheInjectedClock() throws {
        let fixed = Date(timeIntervalSince1970: 1_790_000_000)
        store.knownRoots = ["/repo/a", "", "/repo/b"]
        let ctl = controller(now: { fixed })
        XCTAssertEqual(ctl.knownRoots(), ["/repo/a", "/repo/b"], "blank roots left out")
        XCTAssertEqual(store.askedCutoffs, [UTCTimestamp.string(daysAgo: 30, from: fixed)])
    }

    func testKnownRootsAreCachedForTheTTL() throws {
        store.knownRoots = ["/repo/a"]
        let ctl = controller()
        _ = ctl.knownRoots()
        store.knownRoots = ["/repo/b"]
        XCTAssertEqual(ctl.knownRoots(), ["/repo/a"])
        XCTAssertEqual(store.askedCutoffs.count, 1)
    }

    /// Review F26: a failed read is retried on the next call, not served as
    /// "no roots" for the whole TTL.
    func testAFailedKnownRootsReadIsRetriedOnTheNextCall() throws {
        store.knownRootsError = MemoryWorkTrackingStore.Refused()
        let ctl = controller()
        XCTAssertEqual(ctl.knownRoots(), [])
        store.knownRootsError = nil
        store.knownRoots = ["/repo/a"]
        XCTAssertEqual(ctl.knownRoots(), ["/repo/a"])
        XCTAssertEqual(store.askedCutoffs.count, 2)
    }

    func testAFailedRefreshKeepsServingThePreviousRoots() {
        let cache = KnownRootsCache()
        let start = Date()
        XCTAssertEqual(cache.value(ttl: 10, now: start) { ["/a"] }, ["/a"])
        XCTAssertEqual(cache.value(ttl: 10, now: start.addingTimeInterval(20)) { nil }, ["/a"])
        var fetched = false
        _ = cache.value(ttl: 10, now: start.addingTimeInterval(21)) { fetched = true; return ["/b"] }
        XCTAssertTrue(fetched, "the failure did not restart the TTL")
    }
}
#endif
