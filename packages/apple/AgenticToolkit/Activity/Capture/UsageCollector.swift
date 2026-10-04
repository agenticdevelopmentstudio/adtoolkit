// Macos-only, like `UsageStore.swift`: it stores a `UsageStore` and drives
// the real macOS observation adapters. iOS never captures usage (c9), so
// `AgenticToolkitActivity-iOS` doesn't compile this type at all.
#if os(macOS)
import Foundation
import os

// Public: `olylod` constructs this directly (`UsageCollector(store:...)`)
// and calls `start()`/`stop()` on it from `DaemonDelegate`.
@MainActor
public final class UsageCollector {
    private let store: UsageStore
    private let tracker: FocusTracker
    private let focus: FocusSource
    private let windows: WindowLifecycleSource
    private let idle: IdleSource
    private let power: PowerSource
    private let machineID: UUID
    private let now: () -> Date
    private let makeID: () -> UUID
    private var spanID: UUID?
    private var heartbeat: Timer?
    private var isRunning = false
    private let log = Logger(subsystem: "app.olylo.olylod", category: "collector")

    public init(store: UsageStore, tracker: FocusTracker, focus: FocusSource,
         windows: WindowLifecycleSource, idle: IdleSource, power: PowerSource, machineID: UUID,
         now: @escaping () -> Date = Date.init, makeID: @escaping () -> UUID = UUID.init) {
        self.store = store; self.tracker = tracker; self.focus = focus
        self.windows = windows; self.idle = idle; self.power = power
        self.machineID = machineID; self.now = now; self.makeID = makeID
    }

    /// Runs a `UsageStore` mutation, logging (rather than swallowing) any
    /// failure. Store errors are diagnostic-only: the daemon keeps running
    /// even when a segment, window event, or heartbeat write fails.
    private func attempt(_ what: String, _ op: () throws -> Void) {
        do {
            try op()
        } catch {
            logError(what, error)
        }
    }

    /// Logs to both stderr (so it lands in the daemon's stderr.log per the
    /// LaunchAgent's StandardErrorPath) and os_log, so failures are visible
    /// without requiring `log stream`/Console access.
    private func logError(_ what: String, _ error: Error) {
        let line = "olylod: \(what) failed: \(error)\n"
        FileHandle.standardError.write(Data(line.utf8))
        log.error("\(what) failed: \(String(describing: error))")
    }

    /// Returns whether capture is now active — `false` if it bailed (e.g. a
    /// migration failure) so callers can keep external status honest.
    @discardableResult
    public func start() -> Bool {
        guard !isRunning else { return true }
        isRunning = true

        // Migrations run outside `attempt(...)`: a broken/unmigratable DB
        // must not masquerade as capturing, so failure here aborts start()
        // entirely rather than logging and continuing.
        do {
            try store.runMigrations()
        } catch {
            logError("runMigrations", error)
            isRunning = false
            return false
        }

        attempt("closeStaleSpans") { try store.closeStaleSpans() }
        let id = makeID(); spanID = id
        attempt("openSpan") { try store.openSpan(id: id, machineID: machineID, startedAt: now()) }

        focus.onFocus = { [weak self] f in self?.drive(.focus(f)) }
        idle.onIdle = { [weak self] in self?.drive(.idle) }
        idle.onActive = { [weak self] in self?.focus.poll() }
        power.onLock = { [weak self] in self?.drive(.lock) }
        power.onSleep = { [weak self] in self?.drive(.sleep) }
        power.onAppQuit = { [weak self] pid in self?.drive(.appQuit(pid: pid)) }
        power.onResume = { [weak self] in self?.focus.poll() }
        // Window lifecycle events themselves are no longer recorded here —
        // `WindowLifecycleContextTrigger` writes `context_event_window` now,
        // from its own source, under its own opt-in.
        //
        // This collector still starts a window source for one reason: the
        // title-change nudge. Switching a browser tab retitles the frontmost
        // window without activating any application, so no focus event
        // arrives and the open usage segment would keep the stale title until
        // the next app switch. Wired here rather than by the caller (I-3):
        // this closure must be live exactly while this collector is running,
        // and `windows` is this collector's own source.
        windows.onEvent = { _, _, _, _ in }
        windows.onTitleChange = { [weak self] in self?.focus.poll() }
        focus.start(); windows.start(); idle.start(); power.start()

        // The heartbeat Timer fires on the main run loop (same thread the
        // daemon uses for all observation: NSWorkspace notifications, AX
        // observer callbacks). MainActor.assumeIsolated documents and
        // enforces that assumption under strict concurrency without an
        // async hop.
        heartbeat = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let id = self.spanID else { return }
                self.attempt("heartbeatSpan") { try self.store.heartbeatSpan(id: id, at: self.now()) }
            }
        }
        return true
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false

        heartbeat?.invalidate(); heartbeat = nil
        if let closed = tracker.stop(now: now()) {
            attempt("insertSegment") { try store.insertSegment(closed) }
        }
        // Unwired as well as stopped. `stop()` asks a source to end its
        // observation, but the closures stay attached, and every one of them
        // captures `self` and writes to the store: an event already in flight
        // when `stop()` ran — an AX callback queued on the main run loop, a
        // sleep notification NSWorkspace has already dispatched — still
        // arrives afterwards. `drive` now refuses those, but a nudge closure
        // (`onActive`, `onResume`, `onTitleChange`) does not go through
        // `drive`; it calls `focus.poll()` and would restart the whole chain
        // on a collector the strategy has already released.
        focus.onFocus = nil
        idle.onIdle = nil
        idle.onActive = nil
        power.onLock = nil
        power.onSleep = nil
        power.onAppQuit = nil
        power.onResume = nil
        windows.onEvent = nil
        windows.onTitleChange = nil

        focus.stop(); windows.stop(); idle.stop(); power.stop()
        if let id = spanID {
            attempt("closeSpan") { try store.closeSpan(id: id, endedAt: now(), reason: "clean_stop") }
        }
        spanID = nil
    }

    /// Guarded by `isRunning` for the same reason `ContextCollector.record`
    /// checks its `running` set: an event that was already in flight when
    /// `stop()` ran must not reopen the tracker's segment after the span it
    /// belongs to has been closed, which would leave a segment referencing a
    /// span that ended before it.
    private func drive(_ event: FocusEvent) {
        guard isRunning else { return }
        if let closed = tracker.handle(event, now: now()) {
            attempt("insertSegment") { try store.insertSegment(closed) }
        }
    }
}
#endif
