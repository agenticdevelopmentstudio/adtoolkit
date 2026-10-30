import Combine
import Foundation

/// Calls a session idle once its terminal has printed nothing for `settle()`
/// seconds after printing something.
///
/// The fallback detector: it knows nothing about what runs in the terminal,
/// so it works for any program, at the price of waiting out the settle. One
/// idle per burst of output — a terminal that stays quiet after an idle is not
/// reported again.
@MainActor
public final class QuietPeriodDetector: PartnerSessionEventDetecting {

    public var onIdle: ((UUID) -> Void)?
    public var onExit: ((UUID) -> Void)?

    private let settle: () -> TimeInterval
    private let scheduler: any TimerScheduling
    private var watched: [UUID: Watch] = [:]

    private final class Watch {
        var hadActivity = false
        var timer: AnyCancellable?
        var subscriptions: Set<AnyCancellable> = []
    }

    /// - Parameter settle: Read at every burst, so a settings change applies
    ///   from the next one.
    public init(settle: @escaping () -> TimeInterval, scheduler: any TimerScheduling = DispatchTimerScheduler()) {
        self.settle = settle
        self.scheduler = scheduler
    }

    public func watch(_ session: PartnerSession) {
        unwatch(id: session.id)
        let id = session.id
        let watch = Watch()
        watched[id] = watch
        session.terminal.outputActivity
            .sink { [weak self] in MainActor.assumeIsolated { self?.activity(id: id) } }
            .store(in: &watch.subscriptions)
        session.terminal.onTermination { [weak self] in self?.exited(id: id) }
            .store(in: &watch.subscriptions)
    }

    public func unwatch(id: UUID) {
        guard let watch = watched.removeValue(forKey: id) else { return }
        watch.timer?.cancel()
        watch.subscriptions.removeAll()
    }

    private func activity(id: UUID) {
        guard let watch = watched[id] else { return }
        watch.hadActivity = true
        watch.timer = scheduler.schedule(after: settle()) { [weak self] in self?.settled(id: id) }
    }

    private func settled(id: UUID) {
        guard let watch = watched[id] else { return }
        watch.timer = nil
        guard watch.hadActivity else { return }
        watch.hadActivity = false
        onIdle?(id)
    }

    private func exited(id: UUID) {
        guard let watch = watched[id] else { return }
        watch.timer?.cancel()
        watch.timer = nil
        watch.hadActivity = false
        onExit?(id)
    }
}
