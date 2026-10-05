import Foundation
import OSLog

/// Mirrors a group of settings into another process: on any change, at
/// startup, and on every reconnect, the whole idempotent snapshot is sent.
///
/// A full snapshot rather than a delta, so a receiver that was down for one of
/// the changes is corrected by the next push rather than staying
/// half-configured. A newer push supersedes one still retrying, so a stale body
/// can never land after a fresh one. The reconnect handler is registered once
/// per instance, and is inert while the push is stopped.
///
/// **A reconnect never restarts a push in flight, and backs off after
/// failures.** While the receiver's service is missing, every failed attempt
/// drops the connection and the next attempt's new connection fires the
/// reconnect handler; restarting the push there would cancel the bounded retry
/// before it gives up, forever (review F11). So a reconnect while a push is
/// running is ignored — that push already carries the current snapshot — and a
/// reconnect after consecutive failed pushes waits ``reconnectDelay``, which
/// grows with each failure. A change still pushes at once: the user asked.
///
/// What the snapshot holds, how it is encoded and how it travels are the
/// caller's; the engine — observe, snapshot, supersede, bounded retry,
/// re-push on reconnect — is this one copy.
@MainActor
public final class SettingsSnapshotPush {

    /// Builds the body to send, or nil when it can't be built (logged, not sent).
    public typealias Snapshot = @MainActor () -> Data?
    /// Sends one body; true when the receiver took it.
    public typealias Send = @Sendable (Data) async -> Bool
    /// Registers a handler to run on every reconnect.
    public typealias RegisterReconnect = (@escaping @Sendable () -> Void) -> Void
    /// Nanoseconds a reconnect waits before pushing, given how many pushes in a
    /// row have failed (always at least 1 when asked).
    public typealias ReconnectDelay = @Sendable (_ consecutiveFailures: Int) -> UInt64

    private let label: String
    private let logger: Logger
    private let snapshot: Snapshot
    private let sendBody: Send
    private let registerReconnect: RegisterReconnect
    private let backoffs: [UInt64]
    private let reconnectDelay: ReconnectDelay

    private var observers: [AnyObject] = []
    private var observing = false
    private var reconnectInstalled = false
    private var pushTask: Task<Void, Never>?
    /// Bumped by every push, so a superseded push's ending is ignored.
    private var generation = 0
    private var inFlight = false
    private var failures = 0
    private var delayedReconnect: Task<Void, Never>?

    /// - Parameters:
    ///   - label: names the channel in log lines ("Billing prefs").
    ///   - backoffs: nanoseconds to wait before each attempt; the default
    ///     tries at once, then after 0.5 s and 1.5 s.
    ///   - reconnectDelay: how long a reconnect after failed pushes waits; the
    ///     default doubles from 1 s to a 30 s cap.
    public init(
        label: String,
        logger: Logger,
        backoffs: [UInt64] = BoundedPush.defaultBackoffs,
        reconnectDelay: @escaping ReconnectDelay = SettingsSnapshotPush.defaultReconnectDelay,
        snapshot: @escaping Snapshot,
        send: @escaping Send,
        registerReconnect: @escaping RegisterReconnect
    ) {
        self.label = label
        self.logger = logger
        self.backoffs = backoffs
        self.reconnectDelay = reconnectDelay
        self.snapshot = snapshot
        self.sendBody = send
        self.registerReconnect = registerReconnect
    }

    /// 1 s after one failed push, doubling per further failure, capped at 30 s.
    public static let defaultReconnectDelay: ReconnectDelay = { failures in
        let seconds = min(30, 1 << min(max(failures - 1, 0), 5))
        return UInt64(seconds) * 1_000_000_000
    }

    /// Pushes in a row that ended without the receiver taking the body.
    public var consecutiveFailures: Int { failures }

    /// Whether the push is observing its settings.
    public var isObserving: Bool { observing }

    /// Observes `settings`, pushes the snapshot now, and re-pushes it on every
    /// reconnect. A repeat call while observing is ignored.
    public func start<Value: Codable & Sendable>(observing settings: [UserSetting<Value>]) {
        start(observers: settings.map { setting in
            UserSettingObserver(setting) { [weak self] _ in self?.push() }
        })
    }

    /// ``start(observing:)`` for settings of mixed types: `makeObservers` is
    /// handed the change handler and returns whatever observers it built,
    /// which this push keeps alive until ``stop()``.
    public func start(makeObservers: (_ onChange: @escaping @MainActor () -> Void) -> [AnyObject]) {
        start(observers: makeObservers { [weak self] in self?.push() })
    }

    private func start(observers built: [AnyObject]) {
        guard !observing else {
            logger.warning("\(self.label, privacy: .public) push started more than once; ignoring the repeat")
            return
        }
        observing = true
        observers = built
        // Observers fire only on change, and the receiver may have restarted.
        push()
        guard !reconnectInstalled else { return }
        reconnectInstalled = true
        registerReconnect { [weak self] in
            Task { @MainActor in self?.reconnected() }
        }
    }

    /// Stops observing and cancels a push still retrying. The reconnect
    /// handler stays registered but does nothing until the next ``start``.
    public func stop() {
        observing = false
        observers = []
        cancelPending()
    }

    /// Sends the current snapshot, superseding any push still retrying.
    public func push() {
        guard let body = snapshot() else {
            logger.error("Failed to build the \(self.label, privacy: .public) snapshot")
            return
        }
        cancelPending()
        generation += 1
        let mine = generation
        inFlight = true
        let label = label, logger = logger, backoffs = backoffs, send = sendBody
        pushTask = Task { [weak self] in
            let delivered = await BoundedPush.send(label: label, logger: logger, backoffs: backoffs) {
                await send(body)
            }
            self?.finished(generation: mine, delivered: delivered)
        }
    }

    /// Awaits the most recent push, including one a reconnect is waiting to
    /// make — for tests.
    public func awaitPendingPush() async {
        await delayedReconnect?.value
        await pushTask?.value
    }

    // MARK: - Reconnect policy

    private func reconnected() {
        guard observing else { return }
        // The running push carries the current snapshot; restarting it would
        // cancel its bounded retry before it can give up (review F11).
        guard !inFlight, delayedReconnect == nil else { return }
        guard failures > 0 else {
            push()
            return
        }
        let delay = reconnectDelay(failures)
        let (name, failed, waitMs) = (label, failures, delay / 1_000_000)
        logger.info("\(name, privacy: .public) push: reconnect after \(failed) failure(s); waiting \(waitMs) ms")
        delayedReconnect = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, let self else { return }
            self.delayedReconnect = nil
            guard self.observing else { return }
            self.push()
        }
    }

    private func finished(generation finishedGeneration: Int, delivered: Bool) {
        // A superseded push says nothing about the receiver's current state.
        guard finishedGeneration == generation else { return }
        inFlight = false
        failures = delivered ? 0 : failures + 1
    }

    private func cancelPending() {
        pushTask?.cancel()
        pushTask = nil
        inFlight = false
        delayedReconnect?.cancel()
        delayedReconnect = nil
    }

    /// `values` as sorted-key JSON, the byte-stable form a snapshot is sent in.
    public static func encodeSorted(_ values: some Encodable) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(values)
    }
}

/// A push retried a bounded number of times: try, then back off and retry,
/// stopping at once if a newer push cancelled this one. A dropped push leaves
/// the receiver on its last-known state until the next change re-pushes, so the
/// retry is deliberately bounded rather than infinite.
public enum BoundedPush {

    /// At once, then after 0.5 s, then after 1.5 s.
    public static let defaultBackoffs: [UInt64] = [0, 500_000_000, 1_500_000_000]

    /// - Parameters:
    ///   - label: names the channel in log lines.
    ///   - call: performs one push; true on success, false on a transport failure.
    /// - Returns: true when an attempt landed; false when every attempt failed
    ///   or a newer push cancelled this one.
    @discardableResult
    public static func send(
        label: String,
        logger: Logger,
        backoffs: [UInt64] = defaultBackoffs,
        call: @Sendable () async -> Bool
    ) async -> Bool {
        for (attempt, delay) in backoffs.enumerated() {
            if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
            // Superseded: the stale body must not land after the newer one.
            if Task.isCancelled { return false }
            if await call() { return true }
            logger.warning("\(label, privacy: .public) push attempt \(attempt + 1) of \(backoffs.count) failed")
        }
        logger.error(
            "\(label, privacy: .public) push failed after \(backoffs.count) attempts; receiver keeps its prior state"
        )
        return false
    }
}
