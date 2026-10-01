import Foundation
import Synchronization

/// Universal Control's session on this Mac, and above all whether it is
/// throwing input away.
///
/// The failure it watches for: this Mac decides the source Mac is no longer
/// nearby and tears its side of the session down, but the source never hears
/// of it and goes on sending its keyboard and mouse here. This Mac drops every
/// event ("no virtual service; dropping events") and the source does not take
/// them back, so neither Mac responds until the devices reconnect — switching
/// their channel is what recovers it. Only the Mac doing the dropping logs
/// anything, so this is seen on the Mac being controlled, not the one whose
/// keyboard it is.
///
/// Critical while drops are arriving, a warning while any are within
/// `UniversalControlSessionState.recentWindow`, and otherwise who is connected
/// and whose input drives this Mac.
public final class UniversalControlMonitor: SystemMonitor {

    /// Drops this recent mean input is being lost now.
    public static let stalledWindow: TimeInterval = 10

    public let id: String
    public let title: String

    private let feed: any UniversalControlSessionSource
    private let processes: @Sendable () -> [ProcessSample]
    private let now: @Sendable () -> Date
    private let state = Mutex(UniversalControlSessionState())

    public init(
        id: String = "universal-control",
        title: String = "Universal Control",
        feed: any UniversalControlSessionSource = UniversalControlSessionFeed(),
        processes: @escaping @Sendable () -> [ProcessSample] = ProcessTable.snapshot,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.id = id
        self.title = title
        self.feed = feed
        self.processes = processes
        self.now = now
    }

    public func sample() -> MonitorReading {
        feed.start { [weak self] entry in
            self?.state.withLock { $0.apply(entry) }
        }
        let now = now()
        let session = state.withLock { state in
            state.prune(now: now)
            return state
        }

        let agentRunning = processes().contains { ProcessMatcher.universalControl.matches($0, openFiles: { _ in [] }) }
        guard agentRunning else {
            return MonitorReading(id: id, title: title, level: .normal, value: "Off",
                                  detail: "Universal Control is not running")
        }

        let stalls = session.stalls
        if let stall = stalls.last, now.timeIntervalSince(stall.end) <= Self.stalledWindow {
            return MonitorReading(
                id: id,
                title: title,
                level: .critical,
                value: "Dropping input",
                detail: "From \(name(session.previousSource, in: session)) for \(Self.seconds(stall.duration))"
                    + " · switch the keyboard or mouse channel to recover"
            )
        }
        if let stall = stalls.last {
            let noun = stalls.count == 1 ? "stall" : "stalls"
            return MonitorReading(
                id: id,
                title: title,
                level: .warning,
                value: "\(stalls.count) input \(noun)",
                detail: "Last at \(stall.start.formatted(date: .omitted, time: .shortened))"
                    + " for \(Self.seconds(stall.duration))"
                    + " · input from \(name(session.previousSource, in: session)) was dropped"
            )
        }
        if !session.hasSessionState {
            if let failure = feed.failure { return .unavailable(id: id, title: title, detail: failure) }
            // Until the history read lands, or for an hour with no session.
            return MonitorReading(id: id, title: title, level: .normal, value: "Running",
                                  detail: "No session logged in the last hour")
        }

        let connected = session.connectedDevices
        guard !connected.isEmpty else {
            return MonitorReading(id: id, title: title, level: .normal, value: "Idle",
                                  detail: "No other Mac connected")
        }
        let noun = connected.count == 1 ? "Mac" : "Macs"
        let input = session.currentSource.map { "input from \(name($0, in: session))" } ?? "no input shared"
        return MonitorReading(id: id, title: title, level: .normal, value: "Connected",
                              detail: "\(connected.count) \(noun) · \(input)")
    }

    /// "this Mac" for the local id, the id itself otherwise.
    private func name(_ device: String?, in session: UniversalControlSessionState) -> String {
        guard let device else { return "another Mac" }
        return device == session.localDevice ? "this Mac" : device
    }

    private static func seconds(_ interval: TimeInterval) -> String {
        "\(max(1, Int(interval.rounded())))s"
    }
}
