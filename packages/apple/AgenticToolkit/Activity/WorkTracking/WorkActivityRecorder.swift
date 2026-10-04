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

        public init(focus: any ContextTrigger, input: any ContextTrigger,
                    session: any ContextTrigger, lifecycle: any ContextTrigger) {
            self.focus = focus
            self.input = input
            self.session = session
            self.lifecycle = lifecycle
        }

        /// The production set. `readsWindows: false` without the AX grant.
        @MainActor public static func live(readsWindows: Bool) -> Triggers {
            Triggers(focus: AppFocusTrigger(source: FrontmostFocusAdapter(readsWindows: readsWindows)),
                     input: InputActivityTrigger(interval: 30, idleThreshold: 60),
                     session: SessionTrigger(),
                     lifecycle: AppLifecycleTrigger())
        }
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
    private var lastFocus: AppFocusDetail?
    private var inputActive = true
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

    public var currentSpan: ActivitySpanDTO? { current }

    /// Starts each trigger; a throwing one is logged and skipped.
    public func start() {
        guard !running else { return }
        running = true
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
        builder = ActivitySpanBuilder()
        lastFocus = nil
        running = false
    }

    /// Replaces the allowlist and re-evaluates the current focus.
    public func update(allowlist: AppAllowlist) {
        self.allowlist = allowlist
        if running, let lastFocus { handleFocus(lastFocus, at: now(), remember: false) }
    }

    /// Test seam: feeds an event as if a trigger emitted it.
    func handle(_ detail: ContextEventDetail, at date: Date) {
        switch detail {
        case .appFocus(let focus):
            handleFocus(focus, at: date, remember: true)
        case .appLifecycle(let lifecycle):
            guard lifecycle.change == .terminated else { return }
            apply(builder.appTerminated(bundleId: lifecycle.bundleID, at: date))
            if lastFocus?.bundleID == lifecycle.bundleID { lastFocus = nil }
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
                let from = UTCTimestamp.string(from: date)
                write { try $0.openIdleInterval(from: from) }
            case .active:
                inputActive = true
                let until = UTCTimestamp.string(from: date)
                write { try $0.closeIdleInterval(until: until) }
            case .sample: break
            }
        default:
            break
        }
    }

    /// Test seam: one heartbeat tick.
    func heartbeat() {
        guard let current, inputActive else { return }
        let id = current.id
        let at = UTCTimestamp.string(from: now())
        write { try $0.touchActivitySpan(id: id, at: at) }
    }

    /// Test seam: waits for queued writes.
    /// Relies on `writeQueue` being serial: the empty block runs after every earlier write.
    func drainWrites() { writeQueue.sync {} }

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
                                          repoRoot: resolved.repo?.root ?? "", branch: resolved.repo?.branch ?? "")
        apply(builder.focus(attribution, at: date))
    }

    private func apply(_ commands: [SpanCommand]) {
        for command in commands {
            switch command {
            case .open(let attribution, let date):
                let span = ActivitySpanDTO(bundleId: attribution.bundleId, appName: attribution.appName,
                                           windowTitle: attribution.windowTitle, workingPath: attribution.workingPath,
                                           repoRoot: attribution.repoRoot, branch: attribution.branch,
                                           startedAt: UTCTimestamp.string(from: date), tz: timeZone().identifier)
                current = span
                write { try $0.openActivitySpan(span) }
            case .close(let date):
                guard let closing = current else { continue }
                current = nil
                let ended = UTCTimestamp.string(from: date)
                write { try $0.closeActivitySpan(id: closing.id, endedAt: ended) }
            case .retitle(let title):
                guard var span = current else { continue }
                span.windowTitle = title
                current = span
                let id = span.id
                write { try $0.retitleActivitySpan(id: id, title: title) }
            }
        }
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
