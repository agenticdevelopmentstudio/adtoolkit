#if os(macOS)
import Foundation
import os
import AgenticToolkitCore

/// Turns macOS context triggers (focus, input, session, lifecycle) into
/// stored work-activity spans and idle intervals: allowlist -> path resolver
/// -> span builder -> `ActivityPersistence`, plus a heartbeat while the user
/// is present. Every store call runs on `writeQueue`, never the main actor.
@MainActor
public final class WorkActivityRecorder {
    public struct Triggers {
        public var focus: any ContextTrigger
        public var input: any ContextTrigger
        public var session: any ContextTrigger
        public var lifecycle: any ContextTrigger
        /// The focus reader, when it can be told which apps to read windows
        /// of. The recorder points it at its allowlist, so an app it would
        /// throw away is never read.
        public var windowReads: FrontmostFocusAdapter?

        public init(focus: any ContextTrigger, input: any ContextTrigger,
                    session: any ContextTrigger, lifecycle: any ContextTrigger,
                    windowReads: FrontmostFocusAdapter? = nil) {
            self.focus = focus
            self.input = input
            self.session = session
            self.lifecycle = lifecycle
            self.windowReads = windowReads
        }

        /// The production set. `readsWindows: false` without the AX grant.
        /// `onAccessibilityRevoked` fires once, on the main actor, when the
        /// grant is found withdrawn mid-run — see `FrontmostFocusAdapter`.
        @MainActor public static func live(
            readsWindows: Bool, onAccessibilityRevoked: (@MainActor () -> Void)? = nil
        ) -> Triggers {
            let adapter = FrontmostFocusAdapter(readsWindows: readsWindows)
            adapter.onAccessibilityRevoked = onAccessibilityRevoked
            // The recorder reads neither the document's metadata nor the
            // executable path, so neither is paid for on each focus change.
            return Triggers(focus: AppFocusTrigger(source: adapter, metadata: NoDocumentMetadata(),
                                                   executablePath: { _ in nil }),
                     input: InputActivityTrigger(interval: 30, idleThreshold: 60),
                     session: SessionTrigger(),
                     lifecycle: AppLifecycleTrigger(),
                     windowReads: adapter)
        }
    }

    /// Answers no metadata without touching the filesystem.
    struct NoDocumentMetadata: DocumentMetadataReading {
        func metadata(forPath path: String) -> DocumentMetadata? { nil }
    }

    private let triggers: Triggers
    private var allowlist: AppAllowlist
    private let resolver: WorkingPathResolver
    private let store: any ActivityPersistence
    private let writeQueue: DispatchQueue
    private let heartbeatInterval: TimeInterval
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    private let onWriteFailure: @Sendable (Error) -> Void
    private let log = Logger(subsystem: "com.agentic-cookbook.toolkit", category: "work-activity")

    private var builder = ActivitySpanBuilder()
    private var current: ActivitySpanDTO?
    /// The open span's title changed since it was last written. A retitle is
    /// held in memory and written with the next heartbeat or the close, not on
    /// every change: a title that animates (a terminal spinner) would
    /// otherwise be an UPDATE per frame for a span whose repo never moved.
    private var titleUnwritten = false
    private var lastFocus: AppFocusDetail?
    private var inputActive = true
    /// When input last resumed this run. The next idle closes any interval
    /// still open at that moment before opening its own: a close that failed
    /// to land would otherwise leave one idle open forever, and every span
    /// after it would wait on it to derive.
    private var lastResumedAt: String?
    /// An idle row this run opened and has not closed. The input trigger's
    /// first tick reports the absence `start()` already recorded; splitting
    /// the row there would cut one absence into two, each of which can fall
    /// under a billing cutoff that the whole absence crosses.
    private var idleOpen = false
    private var running = false
    /// Not main-actor isolated only so `deinit` can invalidate it; every other
    /// access is on the main actor.
    nonisolated(unsafe) private var heartbeatTimer: Timer?

    /// - Parameter writeQueue: MUST be serial. Writes must land in the order
    ///   they were issued, and `drainWrites()` only waits for all of them on a serial queue.
    public init(triggers: Triggers, allowlist: AppAllowlist, resolver: WorkingPathResolver,
                store: any ActivityPersistence,
                writeQueue: DispatchQueue = DispatchQueue(label: "work-activity-writes"),
                heartbeatInterval: TimeInterval = 60, now: @escaping () -> Date = Date.init,
                timeZone: @escaping () -> TimeZone = { .current },
                onWriteFailure: @escaping @Sendable (Error) -> Void = { _ in }) {
        self.triggers = triggers
        self.allowlist = allowlist
        self.resolver = resolver
        self.store = store
        self.writeQueue = writeQueue
        self.heartbeatInterval = heartbeatInterval
        self.now = now
        self.timeZone = timeZone
        self.onWriteFailure = onWriteFailure
    }

    deinit { heartbeatTimer?.invalidate() }

    /// Whether the heartbeat timer is live (test seam).
    var isHeartbeatScheduled: Bool { heartbeatTimer?.isValid ?? false }

    public var currentSpan: ActivitySpanDTO? { current }

    /// Starts each trigger; a throwing one is logged and skipped.
    public func start() {
        guard !running else { return }
        running = true
        // Presence as it is now, not assumed: a restart while the user is away
        // must not heartbeat the span as if they were here until the first
        // input tick (up to its interval later) says otherwise.
        let presence = triggers.input as? any PresenceSampling
        inputActive = presence?.samplePresence() ?? true
        lastResumedAt = nil
        idleOpen = false
        filterWindowReads()
        // Started mid-absence (a restart while the user is away): the idle
        // row starts at the last input, so the absence the stop or crash
        // split stays one, with no billable gap at the restart. A no-op when
        // a row is still open.
        if !inputActive, let silence = presence?.sampleSilence() {
            let from = UTCTimestamp.string(from: now().addingTimeInterval(-silence))
            write { try $0.openIdleInterval(from: from) }
            idleOpen = true
        }
        let wired: [any ContextTrigger] = [triggers.focus, triggers.input, triggers.session, triggers.lifecycle]
        for trigger in wired {
            trigger.onEvent = { [weak self] detail, date in
                MainActor.assumeIsolated { self?.handle(detail, at: date) }
            }
            do {
                try trigger.start()
            } catch {
                log.error("work-activity trigger \(String(describing: trigger.kind), privacy: .public) failed to start: \(String(describing: error), privacy: .public)")
            }
        }
        heartbeatTimer?.invalidate()
        let timer = Timer(timeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.heartbeat() }
        }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    /// Closes the open span at `now()`, stops the triggers, cancels the heartbeat.
    public func stop() {
        guard running else { return }
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        for trigger in [triggers.focus, triggers.input, triggers.session, triggers.lifecycle] {
            trigger.stop()
            trigger.onEvent = nil
        }
        let stoppedAt = now()
        apply(builder.focus(nil, at: stoppedAt))
        if !inputActive {
            let until = UTCTimestamp.string(from: stoppedAt)
            write { try $0.closeIdleInterval(until: until) }
        }
        inputActive = true
        idleOpen = false
        builder = ActivitySpanBuilder()
        lastFocus = nil
        running = false
    }

    /// Replaces the allowlist and re-evaluates the current focus.
    public func update(allowlist: AppAllowlist) {
        self.allowlist = allowlist
        filterWindowReads()
        if running, let lastFocus { handleFocus(lastFocus, at: now(), remember: false) }
        // An app just allowed was last read app-only; read its window now.
        if running { triggers.windowReads?.poll() }
    }

    /// Test seam: feeds an event as if a trigger emitted it.
    func handle(_ detail: ContextEventDetail, at date: Date) {
        switch detail {
        case .appFocus(let focus):
            handleFocus(focus, at: date, remember: true)
        case .appLifecycle(let lifecycle):
            guard lifecycle.change == .terminated else { return }
            apply(builder.appTerminated(bundleId: lifecycle.bundleID, pid: lifecycle.pid, at: date))
            // The same copy only: another one sharing the bundle id is still running.
            if lastFocus?.bundleID == lifecycle.bundleID, lastFocus?.pid == lifecycle.pid { lastFocus = nil }
        case .session(let session):
            switch session.change {
            case .lock: apply(builder.suspend(.locked, at: date))
            case .unlock: apply(builder.resume(.locked, at: date))
            case .sleep: apply(builder.suspend(.asleep, at: date))
            case .wake: apply(builder.resume(.asleep, at: date))
            case .idle, .active: break   // presence is the input trigger's job
            }
        case .input(let input):
            switch input.change {
            case .inactive:
                inputActive = false
                // Already recorded: the absence is the one the row open now
                // describes, so there is nothing to close or reopen.
                guard !idleOpen else { return }
                idleOpen = true
                // A run's first reading is dated at the tick, not backdated,
                // and carries the silence it found as `idleSeconds` (a
                // witnessed transition is already dated at the last input and
                // carries none). The absence began at the last input either
                // way, so the row opens there — as `start()` does for a
                // restart mid-absence — and the head of an absence that a
                // restart inside the idle threshold interrupted is not billed
                // (review N6).
                let from = UTCTimestamp.string(from: date.addingTimeInterval(-max(0, input.idleSeconds ?? 0)))
                // Anything still open ended when input last resumed (or now, if
                // it never did this run). A no-op when the last close landed.
                let staleUntil = min(lastResumedAt ?? from, from)
                write { try $0.closeIdleInterval(until: staleUntil) }
                write { try $0.openIdleInterval(from: from) }
            case .active:
                inputActive = true
                idleOpen = false
                let until = UTCTimestamp.string(from: date)
                lastResumedAt = until
                write { try $0.closeIdleInterval(until: until) }
            case .sample: break
            }
        default:
            break
        }
    }

    /// Test seam: one heartbeat tick.
    func heartbeat() {
        writeTitleIfChanged()
        guard let current, inputActive else { return }
        let id = current.id
        let at = UTCTimestamp.string(from: now())
        write { try $0.touchActivitySpan(id: id, at: at) }
    }

    /// Blocks until every write issued so far has landed in the store. Call it
    /// after `stop()` when the process is about to exit: `stop()` only queues the
    /// close of the open span, and an exit before the queue runs loses it.
    /// Relies on `writeQueue` being serial: the empty block runs after every earlier write.
    public func drainWrites() { writeQueue.sync {} }

    // MARK: - Private

    private func handleFocus(_ focus: AppFocusDetail, at date: Date, remember: Bool) {
        if remember { lastFocus = focus }
        guard let app = allowlist.app(for: focus.bundleID) else {
            apply(builder.focus(nil, at: date))
            return
        }
        let fileURL = focus.url.flatMap { URL(string: $0)?.isFileURL == true ? $0 : nil }
        let resolved = resolver.attribution(kind: app.resolver, documentPath: focus.documentPath ?? fileURL,
                                            title: focus.windowTitle ?? "")
        let attribution = SpanAttribution(bundleId: app.bundleId, appName: app.name,
                                          windowTitle: focus.windowTitle ?? "", workingPath: resolved.path,
                                          repoRoot: resolved.repo?.root ?? "", branch: resolved.repo?.branch ?? "",
                                          pid: focus.pid)
        apply(builder.focus(attribution, at: date))
    }

    private func apply(_ commands: [SpanCommand]) {
        for command in commands {
            switch command {
            case .open(let attribution, let date):
                titleUnwritten = false
                let span = ActivitySpanDTO(bundleId: attribution.bundleId, appName: attribution.appName,
                                           windowTitle: attribution.windowTitle, workingPath: attribution.workingPath,
                                           repoRoot: attribution.repoRoot, branch: attribution.branch,
                                           startedAt: UTCTimestamp.string(from: date), tz: timeZone().identifier)
                current = span
                write { try $0.openActivitySpan(span) }
            case .close(let date):
                guard let closing = current else { continue }
                writeTitleIfChanged()
                current = nil
                let ended = UTCTimestamp.string(from: date)
                write { try $0.closeActivitySpan(id: closing.id, endedAt: ended) }
            case .retitle(let title):
                guard var span = current else { continue }
                span.windowTitle = title
                current = span
                titleUnwritten = true
            }
        }
    }

    /// Window reads only for apps this recorder keeps.
    private func filterWindowReads() {
        let allowlist = allowlist
        triggers.windowReads?.shouldReadWindows = { allowlist.app(for: $0) != nil }
    }

    private func writeTitleIfChanged() {
        guard titleUnwritten, let span = current else { return }
        titleUnwritten = false
        let id = span.id
        let title = span.windowTitle
        write { try $0.retitleActivitySpan(id: id, title: title) }
    }

    private func write(_ operation: @escaping @Sendable (any ActivityPersistence) throws -> Void) {
        let store = store
        let report = onWriteFailure
        writeQueue.async {
            do { try operation(store) } catch { report(error) }
        }
    }
}
#endif
