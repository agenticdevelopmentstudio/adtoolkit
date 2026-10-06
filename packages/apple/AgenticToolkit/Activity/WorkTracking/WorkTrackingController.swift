// AgenticToolkitCore is macOS-only, so this is too (review F29).
#if os(macOS)
import Foundation
import OSLog
import AgenticToolkitCore

/// The storage a `WorkTrackingController` runs against: the activity tables,
/// the work-tracking settings, and the repo roots the host already knows.
/// The host conforms its database; every rule stays here (review F14).
public protocol WorkTrackingPersistence: ActivityPersistence, WorkTrackingSettingsStore {
    /// Project roots the host knows from its own records, for the title
    /// fallback: roots it bills, and roots of sessions active at or after
    /// `cutoff` (ISO-8601 UTC). Blank roots are left out; order is free.
    func knownRepoRoots(activeSince cutoff: String) throws -> [String]
}

/// The owner of app-activity tracking: loads and saves the work-tracking
/// preferences, applies the Accessibility policy, runs the
/// `WorkActivityRecorder`, and reports status.
///
/// **Accessibility is never polled.** Asking for the AX state from a process
/// without the grant stalls tccd and can freeze the whole machine, so the
/// check runs only:
/// - when the user turns tracking on (`apply` going stored off → on);
/// - on an explicit `recheckAccessibility()`.
/// Every other path — `start()`, a recovered preference read, a recovering
/// `apply` — trusts the stored answer, a stored `.granted` included (review
/// N1: a grant can be gone by the next launch, after a re-sign or a revoke
/// while the daemon was down, and asking then is exactly the freeze).
///
/// A stored grant is trusted only under the code signature it was recorded
/// under (review D1): TCC keys a grant to the designated requirement, so a
/// re-signed build — the usual way a grant goes stale — starts app-only and
/// makes no AX call at all; `recheckAccessibility()` restores window reads.
/// A grant revoked in System Settings while the daemon was down, under the
/// same signature, cannot be told apart without an AX call of some kind. It
/// is learned from the first window read's `kAXErrorAPIDisabled`
/// (`accessibilityRevoked()`): one bounded read, after which the focus
/// adapter makes no AX call again.
@MainActor
public final class WorkTrackingController {
    public typealias AccessibilityCheck = @MainActor () async -> WorkTrackingAccessibility
    public typealias WriteFailureHandler = @Sendable (Error) -> Void
    /// Called when a window read finds the Accessibility grant withdrawn.
    public typealias AccessibilityRevokedHandler = @MainActor () -> Void
    /// Builds a recorder. `onWriteFailure` is the controller's failure counter;
    /// a factory must hand it to the recorder or failures never reach `status()`.
    /// `onAccessibilityRevoked` likewise goes to the focus adapter
    /// (`Triggers.live(readsWindows:onAccessibilityRevoked:)`).
    public typealias MakeRecorder = @MainActor (_ readsWindows: Bool, _ prefs: WorkTrackingPreferences,
                                                _ onWriteFailure: @escaping WriteFailureHandler,
                                                _ onAccessibilityRevoked: @escaping AccessibilityRevokedHandler)
        -> WorkActivityRecorder
    /// Reads the stored preferences. Injectable so a test can make it fail.
    public typealias LoadPrefs = (any WorkTrackingPersistence) throws -> WorkTrackingPreferences
    /// Seconds to wait before retry `attempt` (1-based) of a failed preference read.
    public typealias RetryDelay = @Sendable (_ attempt: Int) -> TimeInterval

    /// How long `knownRoots()` serves a cached answer before re-querying.
    public nonisolated static let knownRootsTTL: TimeInterval = 5 * 60
    /// How far back `knownRoots()` looks for session project roots.
    public nonisolated static let knownRootsSessionDays = 30

    /// The production check: the toolkit gate's non-prompting status read.
    public static let liveCheck: AccessibilityCheck = {
        switch await MacPermissionGate().status(.accessibility) {
        case .granted: return .granted
        case .denied: return .denied
        // Unreachable for AX: the grant is a yes/no answer, so the checker
        // never reports `.undetermined`. Mapped only for exhaustiveness.
        case .undetermined: return .unknown
        }
    }

    /// 1, 2, 4 … seconds, capped at a minute: a read failure at start is
    /// transient (a busy database), so it is retried until it answers.
    public nonisolated static let defaultRetryDelay: RetryDelay = { attempt in
        min(60, pow(2, Double(max(0, attempt - 1))))
    }

    public nonisolated let database: any WorkTrackingPersistence
    private let checkAccessibility: AccessibilityCheck
    /// This build's designated requirement, read once: the signature a
    /// stored grant must have been recorded under to be trusted.
    private let signer: String?
    private let makeRecorder: MakeRecorder?
    private let loadPrefs: LoadPrefs
    private let retryDelay: RetryDelay
    private nonisolated let now: @Sendable () -> Date
    private nonisolated let rootsCache = KnownRootsCache()

    /// The preferences currently applied (always normalized).
    public private(set) var preferences = WorkTrackingPreferences.default
    private var accessibility: WorkTrackingAccessibility = .unknown
    private var recorder: WorkActivityRecorder?
    private var writeFailures = 0
    private var lastError: String?
    /// Why the stored preferences could not be read, while they cannot.
    private var prefsLoadFailure: String?
    private var started = false
    private var stopped = false
    /// `start()` could not read the stored preferences, so whether tracking
    /// was on is unknown. A retry keeps reading them (review F22); an `apply`
    /// that lands first resolves it instead.
    private var storedStateUnknown = false
    private var retryTask: Task<Void, Never>?

    public init(database: any WorkTrackingPersistence,
                checkAccessibility: @escaping AccessibilityCheck = WorkTrackingController.liveCheck,
                makeRecorder: MakeRecorder? = nil,
                loadPrefs: @escaping LoadPrefs = { try WorkTrackingPrefs.load($0) },
                retryDelay: @escaping RetryDelay = WorkTrackingController.defaultRetryDelay,
                now: @escaping @Sendable () -> Date = Date.init,
                signer: () -> String? = OwnCodeSignature.designatedRequirement) {
        self.database = database
        self.checkAccessibility = checkAccessibility
        self.signer = signer()
        self.makeRecorder = makeRecorder
        self.loadPrefs = loadPrefs
        self.retryDelay = retryDelay
        self.now = now
    }

    /// Host start: recovers open spans, then starts the recorder if enabled.
    /// Never checks AX: the stored answer decides window reads. A failed
    /// preference read is reported in `status().lastError` and retried with
    /// backoff — never taken to mean "tracking is off".
    public func start() async {
        guard !started, !stopped else { return }
        started = true
        do {
            let recovered = try database.recoverActivity(now: UTCTimestamp.string(from: now()))
            if recovered > 0 { Self.logger.info("work tracking: recovered \(recovered) open span(s)") }
        } catch {
            Self.logFailure("recovery", error)
        }

        accessibility = storedAccessibility()
        let prefs: WorkTrackingPreferences
        do {
            prefs = try loadPrefs(database)
        } catch {
            notePrefsLoadFailure(error)
            storedStateUnknown = true
            scheduleRetry(attempt: 1)
            return
        }
        preferences = prefs
        guard prefs.enabled else { return }
        startTrustingTheStoredAnswer()
    }

    /// Stops the recorder and blocks until its close writes have landed, so a
    /// host exiting right after this loses nothing.
    public func stop() {
        stopped = true
        retryTask?.cancel()
        retryTask = nil
        guard let running = recorder else { return }
        recorder = nil
        running.stop()
        running.drainWrites()
    }

    /// Saves, then starts/stops/updates the recorder. Only turning tracking ON
    /// (stored off → on) checks AX, and never after `stop()`.
    public func apply(_ prefs: WorkTrackingPreferences) async throws -> WorkTrackingStatus {
        let normal = prefs.normalized()
        // "Turning on" is judged against what is STORED, never against whether a
        // recorder exists: before `start()` has run, while it awaits its own check,
        // or after `stop()`, there is no recorder even though tracking is on.
        // While `start()` could not read it, a fresh read may answer; if it
        // still fails, whether this is a turn-on is unknown (nil).
        let recovering = storedStateUnknown
        let wasEnabled: Bool? = recovering ? (try? loadPrefs(database))?.enabled : try loadPrefs(database).enabled
        try WorkTrackingPrefs.save(normal, database)
        if recovering { recovered() }
        preferences = normal
        guard !stopped else { return status() }

        if !normal.enabled {
            recorder?.stop()
            recorder = nil
        } else if let recorder {
            recorder.update(allowlist: AppAllowlist(preferences: normal))
        } else if wasEnabled == false {
            let answer = await checkAccessibility()
            storeAccessibility(answer)
            // Re-read after the await: a stop or another `apply` may have run meanwhile.
            if !stopped, preferences.enabled, recorder == nil { startRecorder() }
        } else if recovering {
            // `start()` gave up, so nothing else builds the recorder. Not known
            // to be a turn-on, so the stored answer decides: a stored denial
            // is never re-asked (review F22).
            startTrustingTheStoredAnswer()
        }
        // Otherwise it was already on with no recorder yet: the pending `start()`
        // builds it from `preferences`, so no check here.
        return status()
    }

    /// The explicit, user-driven check. Restarts the recorder if the answer changed.
    public func recheckAccessibility() async -> WorkTrackingStatus {
        let before = accessibility
        let answer = await checkAccessibility()
        storeAccessibility(answer)
        if (before == .granted) != (answer == .granted), recorder != nil, !stopped {
            restartRecorder()
        }
        return status()
    }

    /// A window read found the grant gone mid-run. The adapter has already
    /// stopped every AX call; this records the denial and restarts the
    /// recorder app-only. It deliberately does NOT ask for the AX state:
    /// the read just answered, and asking without the grant stalls tccd.
    public func accessibilityRevoked() {
        guard accessibility != .denied else { return }
        storeAccessibility(.denied)
        Self.logger.notice("work tracking: Accessibility withdrawn; window reads off")
        if recorder != nil, !stopped { restartRecorder() }
    }

    public func status() -> WorkTrackingStatus {
        WorkTrackingStatus(enabled: preferences.enabled, accessibility: accessibility,
                           currentSpan: recorder?.currentSpan, writeFailures: writeFailures,
                           lastError: prefsLoadFailure ?? lastError)
    }

    /// Known repo roots for the title fallback, from the host's records of the
    /// last `knownRootsSessionDays` days. Cached, refreshed at most every
    /// `knownRootsTTL`; a failed read is retried on the next call.
    public nonisolated func knownRoots() -> [String] {
        let date = now()
        return rootsCache.value(ttl: Self.knownRootsTTL, now: date) { [database] in
            do {
                let cutoff = UTCTimestamp.string(daysAgo: Self.knownRootsSessionDays, from: date)
                return try database.knownRepoRoots(activeSince: cutoff).filter { !$0.isEmpty }
            } catch {
                Self.logFailure("known roots query", error)
                return nil
            }
        }
    }

    /// The recorder reported a failed store write.
    public func noteWriteFailure(_ error: Error) {
        writeFailures += 1
        lastError = String(describing: error)
    }

    // MARK: - Private

    /// The start policy: the stored answer is trusted as is — AX is never
    /// asked here, not even to confirm a stored grant (review N1). A grant
    /// recorded under another signature was already read as `.unknown`
    /// (review D1); one revoked under this signature surfaces as the window
    /// read's `kAXErrorAPIDisabled`, which lands in `accessibilityRevoked()`
    /// without asking either.
    private func startTrustingTheStoredAnswer() {
        guard !stopped, preferences.enabled, recorder == nil else { return }
        startRecorder()
    }

    private func scheduleRetry(attempt: Int) {
        let delay = retryDelay(attempt)
        retryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, delay) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.retryLoadingPrefs(attempt: attempt)
        }
    }

    private func retryLoadingPrefs(attempt: Int) async {
        guard storedStateUnknown, !stopped else { return }
        let prefs: WorkTrackingPreferences
        do {
            prefs = try loadPrefs(database)
        } catch {
            notePrefsLoadFailure(error)
            scheduleRetry(attempt: attempt + 1)
            return
        }
        recovered()
        preferences = prefs
        Self.logger.info("work tracking: preferences read after \(attempt) retr(ies)")
        guard prefs.enabled else { return }
        startTrustingTheStoredAnswer()
    }

    private func notePrefsLoadFailure(_ error: Error) {
        Self.logFailure("loading preferences", error)
        prefsLoadFailure = "loading preferences: \(String(describing: error))"
    }

    private func recovered() {
        storedStateUnknown = false
        prefsLoadFailure = nil
        retryTask?.cancel()
        retryTask = nil
    }

    /// Stops the running recorder, waits for its close writes to land, then
    /// starts a new one. Drained first so the old recorder's span and idle
    /// closes reach the store before the new one opens its own.
    private func restartRecorder() {
        if let running = recorder {
            recorder = nil
            running.stop()
            running.drainWrites()
        }
        startRecorder()
    }

    private func startRecorder() {
        let readsWindows = accessibility == .granted
        let onWriteFailure = writeFailureHandler()
        // Deferred a turn: the adapter calls this from inside its own focus
        // read, which must not tear down the recorder that is mid-handling it.
        let onRevoked: AccessibilityRevokedHandler = { [weak self] in
            Task { @MainActor in self?.accessibilityRevoked() }
        }
        let built = makeRecorder?(readsWindows, preferences, onWriteFailure, onRevoked)
            ?? defaultRecorder(readsWindows: readsWindows, onWriteFailure: onWriteFailure,
                               onAccessibilityRevoked: onRevoked)
        recorder = built
        built.start()
        let reads = readsWindows ? "on" : "off"
        Self.logger.info("work tracking: recorder started (window reads \(reads, privacy: .public))")
    }

    /// Called on the recorder's write queue: logs there, counts on the main actor.
    private func writeFailureHandler() -> WriteFailureHandler {
        { [weak self] error in
            Self.logFailure("store write", error)
            Task { @MainActor in self?.noteWriteFailure(error) }
        }
    }

    private func defaultRecorder(readsWindows: Bool, onWriteFailure: @escaping WriteFailureHandler,
                                 onAccessibilityRevoked: @escaping AccessibilityRevokedHandler)
        -> WorkActivityRecorder {
        WorkActivityRecorder(
            triggers: .live(readsWindows: readsWindows, onAccessibilityRevoked: onAccessibilityRevoked),
            allowlist: AppAllowlist(preferences: preferences),
            resolver: WorkingPathResolver(knownRoots: { [weak self] in self?.knownRoots() ?? [] }),
            store: database,
            onWriteFailure: onWriteFailure)
    }

    private func storedAccessibility() -> WorkTrackingAccessibility {
        do {
            return try WorkTrackingPrefs.trustedAccessibility(database, signer: signer)
        } catch {
            Self.logFailure("reading the AX answer", error)
            return .unknown
        }
    }

    private func storeAccessibility(_ answer: WorkTrackingAccessibility) {
        accessibility = answer
        do {
            try WorkTrackingPrefs.setLastAccessibility(answer, signer: signer, database)
        } catch {
            Self.logFailure("storing the AX answer", error)
        }
    }

    private nonisolated static let logger = Logger(subsystem: "com.agentic-cookbook.toolkit",
                                                   category: "work-tracking")

    private nonisolated static func logFailure(_ what: String, _ error: Error) {
        logger.error("work tracking: \(what, privacy: .public) failed: \(String(describing: error), privacy: .public)")
    }
}

/// A time-boxed cache behind an `NSLock`, read off the main actor by the
/// recorder's path resolver.
public final class KnownRootsCache: @unchecked Sendable {
    private let lock = NSLock()
    private var roots: [String] = []
    private var fetchedAt: Date?

    public init() {}

    /// The cached roots while younger than `ttl`; otherwise `fetch()`'s answer.
    /// A failed fetch (`nil`) serves the previous roots and is retried on the
    /// next call — only a fetch that answered starts the TTL (review F26).
    ///
    /// `fetch` runs synchronously, under the lock. Its caller is the recorder's
    /// path resolver, which runs on the main actor, so a refresh is a blocking
    /// read on the main actor. Accepted: it happens at most once per `ttl`
    /// while reads succeed, and the query is small.
    public func value(ttl: TimeInterval, now: Date = Date(), fetch: () -> [String]?) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        if let fetchedAt, now.timeIntervalSince(fetchedAt) < ttl { return roots }
        if let fresh = fetch() {
            roots = fresh
            fetchedAt = now
        }
        return roots
    }
}
#endif
