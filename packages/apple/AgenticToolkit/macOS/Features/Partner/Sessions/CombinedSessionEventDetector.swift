import Combine
import Foundation

/// Two detectors as one: whichever reports a session idle first wins, and the
/// other's report of the same turn is dropped.
///
/// At most one idle per piece of work, and a piece of work starts with
/// input: forwarding an idle disarms the session, and only input to its
/// terminal — typed, pasted, or sent — arms it again. Output does not, because
/// a program can keep printing at a prompt nobody has answered (Claude Code
/// trickles bytes for minutes after a turn), and re-arming on that would let
/// the fallback report the same turn again. At most one exit per session.
@MainActor
public final class CombinedSessionEventDetector: PartnerSessionEventDetecting {

    public var onIdle: ((UUID) -> Void)?
    public var onExit: ((UUID) -> Void)?

    public let primary: any PartnerSessionEventDetecting
    public let fallback: any PartnerSessionEventDetecting

    private var watched: [UUID: Watch] = [:]

    private final class Watch {
        var armed = false
        var exited = false
        var input: AnyCancellable?
    }

    public init(primary: any PartnerSessionEventDetecting, fallback: any PartnerSessionEventDetecting) {
        self.primary = primary
        self.fallback = fallback
        for detector in [primary, fallback] {
            detector.onIdle = { [weak self] id in self?.idle(id: id) }
            detector.onExit = { [weak self] id in self?.exit(id: id) }
        }
    }

    public func watch(_ session: PartnerSession) {
        unwatch(id: session.id)
        let id = session.id
        let watch = Watch()
        watch.input = session.terminal.inputActivity
            .sink { [weak self] in MainActor.assumeIsolated { self?.inputArrived(id: id) } }
        watched[id] = watch
        primary.watch(session)
        fallback.watch(session)
    }

    public func unwatch(id: UUID) {
        primary.unwatch(id: id)
        fallback.unwatch(id: id)
        watched.removeValue(forKey: id)?.input?.cancel()
    }

    private func inputArrived(id: UUID) {
        watched[id]?.armed = true
    }

    private func idle(id: UUID) {
        guard let watch = watched[id], watch.armed, !watch.exited else { return }
        watch.armed = false
        onIdle?(id)
    }

    private func exit(id: UUID) {
        guard let watch = watched[id], !watch.exited else { return }
        watch.exited = true
        watch.armed = false
        onExit?(id)
    }
}
