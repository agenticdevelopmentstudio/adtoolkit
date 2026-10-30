import Combine
import Foundation
import AgenticToolkitCore

/// A Claude Code session as the session daemon last saw it: just what the
/// Stop detector reads.
public struct AdkdSessionActivity: Sendable, Equatable {
    public var sessionID: String
    public var directory: String
    /// The raw hook event name (`Stop`, `PreToolUse`, …).
    public var lastEventType: String
    public var lastActivityAt: String

    public init(sessionID: String, directory: String, lastEventType: String, lastActivityAt: String) {
        self.sessionID = sessionID
        self.directory = directory
        self.lastEventType = lastEventType
        self.lastActivityAt = lastActivityAt
    }
}

/// Where ``AdkdStopEventDetector`` reads the daemon's sessions from.
public protocol AdkdSessionActivitySource: Sendable {
    /// Recently active sessions, or nil when the daemon could not be read.
    func recentSessions() async -> [AdkdSessionActivity]?
}

/// The daemon's `/sessions`, through the same service the Sessions window
/// reads (pointed at adkd in the Kitchen).
public struct DaemonSessionActivitySource: AdkdSessionActivitySource {

    private let service: any StenographerDaemonService
    private let sinceHours: Int

    public init(service: any StenographerDaemonService, sinceHours: Int = 1) {
        self.service = service
        self.sinceHours = sinceHours
    }

    public func recentSessions() async -> [AdkdSessionActivity]? {
        guard let dtos = await service.sessions(status: nil, project: nil, sinceHours: sinceHours,
                                                includeCounts: false) else { return nil }
        return dtos.map {
            AdkdSessionActivity(sessionID: $0.sessionId, directory: $0.cwd, lastEventType: $0.lastEventType,
                                lastActivityAt: $0.lastActivityAt)
        }
    }
}

/// Calls a session idle when a Claude Code session running in its directory
/// ends a turn: the daemon's latest hook event for it is `Stop`.
///
/// Exact where the quiet-period detector guesses — Claude Code prints at its
/// idle prompt, so silence is a poor signal there — but only for Claude Code,
/// and only while the daemon is up. Polls every `interval` seconds. A Stop
/// already on record when a session is first polled is the past, not news;
/// each later Stop (a new session, or a new `lastActivityAt`) is one idle.
/// Exits come from the terminal, as for any detector.
@MainActor
public final class AdkdStopEventDetector: PartnerSessionEventDetecting {

    public var onIdle: ((UUID) -> Void)?
    public var onExit: ((UUID) -> Void)?

    private let source: any AdkdSessionActivitySource
    private let scheduler: any TimerScheduling
    private let interval: TimeInterval
    private var watched: [UUID: Watch] = [:]
    private var pollTimer: AnyCancellable?
    private var polling = false

    private final class Watch {
        let directory: String
        /// Nil until the first poll after watching has taken its baseline.
        var reportedStops: Set<String>?
        var exitSubscription: AnyCancellable?

        init(directory: String) { self.directory = directory }
    }

    public init(source: any AdkdSessionActivitySource, interval: TimeInterval = 5,
                scheduler: any TimerScheduling = DispatchTimerScheduler()) {
        self.source = source
        self.interval = interval
        self.scheduler = scheduler
    }

    public func watch(_ session: PartnerSession) {
        unwatch(id: session.id)
        let id = session.id
        let watch = Watch(directory: Self.normalized(session.directory))
        watch.exitSubscription = session.terminal.onTermination { [weak self] in self?.exited(id: id) }
        watched[id] = watch
        schedulePoll()
    }

    public func unwatch(id: UUID) {
        guard let watch = watched.removeValue(forKey: id) else { return }
        watch.exitSubscription?.cancel()
        if watched.isEmpty { pollTimer = nil }
    }

    /// Reads the daemon once and reports every new Stop. The timer calls it;
    /// so can a test.
    public func poll() async {
        guard !polling, !watched.isEmpty else { return }
        polling = true
        defer { polling = false }
        guard let rows = await source.recentSessions() else { return }
        let stops = rows.filter { $0.lastEventType == HookEventType.stop.rawValue }
        for (id, watch) in watched {
            let keys = Set(stops.filter { Self.normalized($0.directory) == watch.directory }
                .map { "\($0.sessionID)@\($0.lastActivityAt)" })
            guard let reported = watch.reportedStops else {
                watch.reportedStops = keys
                continue
            }
            let fresh = keys.subtracting(reported)
            watch.reportedStops = reported.union(fresh)
            if !fresh.isEmpty { onIdle?(id) }
        }
    }

    private func schedulePoll() {
        guard pollTimer == nil, !watched.isEmpty else { return }
        pollTimer = scheduler.schedule(after: interval) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.poll()
                self.pollTimer = nil
                self.schedulePoll()
            }
        }
    }

    private func exited(id: UUID) {
        guard watched[id] != nil else { return }
        onExit?(id)
    }

    private static func normalized(_ path: String) -> String {
        (path as NSString).standardizingPath
    }
}
