import Combine
import Foundation

/// Runs a body once after a delay, on the main actor. The seam the session
/// detectors keep their clocks behind, so a test fires a settle or a poll on
/// demand instead of waiting it out.
@MainActor
public protocol TimerScheduling {
    /// Runs `body` after `seconds`, unless the returned value is cancelled or
    /// released first.
    func schedule(after seconds: TimeInterval, _ body: @escaping @MainActor () -> Void) -> AnyCancellable
}

/// The real clock: a cancellable work item on the main queue.
@MainActor
public struct DispatchTimerScheduler: TimerScheduling {

    public init() {}

    public func schedule(after seconds: TimeInterval, _ body: @escaping @MainActor () -> Void) -> AnyCancellable {
        let item = DispatchWorkItem {
            MainActor.assumeIsolated { body() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
        return AnyCancellable { item.cancel() }
    }
}

/// Tells the partner sessions registry when a session's terminal has gone
/// quiet (the agent in it finished a turn) and when its shell has exited.
///
/// Each callback carries the ``PartnerSession/id``. A detector reports what it
/// sees; deduplicating between detectors is ``CombinedSessionEventDetector``'s
/// job.
@MainActor
public protocol PartnerSessionEventDetecting: AnyObject {
    var onIdle: ((UUID) -> Void)? { get set }
    var onExit: ((UUID) -> Void)? { get set }
    func watch(_ session: PartnerSession)
    func unwatch(id: UUID)
}

extension TerminalSession {

    /// Fires once, the first time this terminal's shell is seen terminated —
    /// including when it already has been.
    func onTermination(_ body: @escaping @MainActor () -> Void) -> AnyCancellable {
        $state
            .filter { $0 == .terminated }
            .first()
            .sink { _ in MainActor.assumeIsolated { body() } }
    }
}
