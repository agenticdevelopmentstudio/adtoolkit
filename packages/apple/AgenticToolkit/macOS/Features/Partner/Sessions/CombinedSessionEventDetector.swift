import Combine
import Foundation

/// Two detectors as one: whichever reports a session idle first wins, and the
/// other's report of the same turn is dropped.
///
/// At most one idle per burst of terminal output: forwarding an idle disarms
/// the session, and output re-arms it — except output within `rearmGrace` of
/// the idle, which is the program settling at its prompt (Claude Code prints a
/// few bytes there after its Stop) rather than new work. At most one exit per
/// session.
@MainActor
public final class CombinedSessionEventDetector: PartnerSessionEventDetecting {

    public var onIdle: ((UUID) -> Void)?
    public var onExit: ((UUID) -> Void)?

    public let primary: any PartnerSessionEventDetecting
    public let fallback: any PartnerSessionEventDetecting

    private let rearmGrace: TimeInterval
    private let now: () -> Date
    private var watched: [UUID: Watch] = [:]

    private final class Watch {
        var armed = false
        var lastIdle: Date?
        var exited = false
        var activity: AnyCancellable?
    }

    public init(primary: any PartnerSessionEventDetecting, fallback: any PartnerSessionEventDetecting,
                rearmGrace: TimeInterval = 2, now: @escaping () -> Date = Date.init) {
        self.primary = primary
        self.fallback = fallback
        self.rearmGrace = rearmGrace
        self.now = now
        for detector in [primary, fallback] {
            detector.onIdle = { [weak self] id in self?.idle(id: id) }
            detector.onExit = { [weak self] id in self?.exit(id: id) }
        }
    }

    public func watch(_ session: PartnerSession) {
        unwatch(id: session.id)
        let id = session.id
        let watch = Watch()
        // Subscribed before the detectors, so output re-arms this before
        // either of them sees it.
        watch.activity = session.terminal.outputActivity
            .sink { [weak self] in MainActor.assumeIsolated { self?.activity(id: id) } }
        watched[id] = watch
        primary.watch(session)
        fallback.watch(session)
    }

    public func unwatch(id: UUID) {
        primary.unwatch(id: id)
        fallback.unwatch(id: id)
        watched.removeValue(forKey: id)?.activity?.cancel()
    }

    private func activity(id: UUID) {
        guard let watch = watched[id], !watch.armed else { return }
        if let lastIdle = watch.lastIdle, now().timeIntervalSince(lastIdle) < rearmGrace { return }
        watch.armed = true
    }

    private func idle(id: UUID) {
        guard let watch = watched[id], watch.armed, !watch.exited else { return }
        watch.armed = false
        watch.lastIdle = now()
        onIdle?(id)
    }

    private func exit(id: UUID) {
        guard let watch = watched[id], !watch.exited else { return }
        watch.exited = true
        watch.armed = false
        onExit?(id)
    }
}
