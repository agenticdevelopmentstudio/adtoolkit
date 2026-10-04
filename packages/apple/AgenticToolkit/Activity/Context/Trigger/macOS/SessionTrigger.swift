#if os(macOS)
import AppKit
import Foundation

/// Screen lock/unlock and system sleep/wake, kept distinct.
///
/// A new source rather than the existing `PowerSource`/`PowerAdapter`: that
/// adapter maps both unlock and wake onto one `onResume` callback, which is the
/// right shape for re-opening a focus segment but loses a distinction the
/// context schema records.
@MainActor
public protocol SessionLockSleepSource: AnyObject {
    var onChange: ((SessionChange) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
public final class SystemSessionLockSleepSource: SessionLockSleepSource {
    public var onChange: ((SessionChange) -> Void)?
    public init() {}

    public func start() {
        // Lock/unlock are only broadcast on the *distributed* centre; sleep and
        // wake only on NSWorkspace's. Two centres, four notifications.
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(locked),
                                name: .init("com.apple.screenIsLocked"), object: nil)
        distributed.addObserver(self, selector: #selector(unlocked),
                                name: .init("com.apple.screenIsUnlocked"), object: nil)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(willSleep),
                              name: NSWorkspace.willSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(didWake),
                              name: NSWorkspace.didWakeNotification, object: nil)
    }

    public func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // These notifications are delivered on the main thread, so the selectors
    // are `nonisolated` with `MainActor.assumeIsolated` bodies — the same
    // pattern the existing PowerAdapter/FrontmostFocusAdapter use.
    @objc private nonisolated func locked()     { MainActor.assumeIsolated { self.onChange?(.lock) } }
    @objc private nonisolated func unlocked()   { MainActor.assumeIsolated { self.onChange?(.unlock) } }
    @objc private nonisolated func willSleep()  { MainActor.assumeIsolated { self.onChange?(.sleep) } }
    @objc private nonisolated func didWake()    { MainActor.assumeIsolated { self.onChange?(.wake) } }
}

/// Emits a `session` event for lock, unlock, sleep and wake.
///
/// **Not for idle.** `SessionChange` still carries `idle` and `active` — rows
/// written before this trigger stopped emitting them are still in the database
/// and still mean what they meant — but nothing produces them any more.
/// Inactivity is `InputActivityTrigger`'s subject, and only one of the two can
/// own it: `IdleAdapter`'s threshold is a hardcoded 180 seconds, so leaving it
/// wired here would have written a second, duplicate absence on a timer the
/// user cannot configure, right beside the one they can.
///
/// What is left here is the set of absences the *system* witnesses rather than
/// infers. A lock or a sleep is a deliberate act with a notification behind
/// it; silence is a measurement.
@MainActor
public final class SessionTrigger: ContextTrigger {
    public let kind: ContextEventKind = .session
    public let requiredPermission: ContextPermission = .none
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let lockSleep: any SessionLockSleepSource
    private let now: () -> Date
    private var isRunning = false

    public init(lockSleep: any SessionLockSleepSource = SystemSessionLockSleepSource(),
                now: @escaping () -> Date = { Date() }) {
        self.lockSleep = lockSleep
        self.now = now
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        lockSleep.onChange = { [weak self] change in self?.emit(change) }
        lockSleep.start()
    }

    public func stop() {
        isRunning = false
        lockSleep.onChange = nil
        lockSleep.stop()
    }

    private func emit(_ change: SessionChange) {
        guard isRunning else { return }
        onEvent?(.session(SessionDetail(change: change)), now())
    }
}
#endif
