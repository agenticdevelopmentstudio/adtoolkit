import Foundation
import AgenticToolkitCore

/// Queues the daemon job when the daemon is not registered or is not answering
/// with the bundle's version. Assessment is cheap and runs before any job, so
/// it can be stale by the time the job runs (the launch-agent job may have
/// bootstrapped a new daemon in between): ``DaemonRestartJob`` re-checks.
/// A daemon the user stopped on purpose stays stopped.
public struct DaemonAssessment: PreparationJob {
    public let target: DaemonTarget
    public let bundleVersion: String
    /// The running daemon's version, nil when it does not answer.
    public let health: @Sendable () async -> String?
    public let isRegistered: @Sendable () async -> Bool
    public let stoppedDeliberately: @Sendable () -> Bool
    public let commands: any CommandRunning
    /// How long the job waits for a registered daemon that is still starting.
    public var grace: Duration

    /// `isRegistered` defaults to asking launchd about `target.label`;
    /// `stoppedDeliberately` to the marker at `target.stopMarkerURL`. A caller
    /// whose marker can move passes its own, resolved when asked.
    public init(target: DaemonTarget, bundleVersion: String, health: @escaping @Sendable () async -> String?,
                commands: any CommandRunning, isRegistered: (@Sendable () async -> Bool)? = nil,
                stoppedDeliberately: (@Sendable () -> Bool)? = nil, grace: Duration = .seconds(15)) {
        self.target = target
        self.bundleVersion = bundleVersion
        self.health = health
        self.commands = commands
        self.isRegistered = isRegistered ?? {
            await commands.run([Launchctl.path, "print", Launchctl.guiTarget(target.label)]).status == 0
        }
        self.stoppedDeliberately = stoppedDeliberately ?? {
            DaemonBootstrap.wasStoppedDeliberately(at: target.stopMarkerURL)
        }
        self.grace = grace
    }

    public func assess() async -> [any StartupJob] {
        guard !bundleVersion.isEmpty, !stoppedDeliberately() else { return [] }
        // Independent probes, so the launch waits for the slower, not the sum.
        async let registered = isRegistered()
        async let answer = health()
        let running = await answer
        guard await !registered || running != bundleVersion else { return [] }
        return [DaemonRestartJob(target: target, bundleVersion: bundleVersion, health: health,
                                 commands: commands, grace: grace)]
    }
}

/// Decides at run time, from fresh evidence, and never kills a daemon that may
/// be busy (a migration of a very large database can leave `/health` silent):
/// not loaded -> bootstrap; then poll `/health` for `grace`. A match at any
/// poll is success. Still silent after the grace: a loaded job with no process
/// (it exited cleanly, which `KeepAlive {Crashed}` never relaunches) is
/// started with `kickstart` and must answer within `timeout`; one with a
/// process is still starting, so the job succeeds with a note.
///
/// A different version answering ends the grace at once when this run did not
/// bootstrap (an updated bundle beside the old, still-running daemon). After a
/// bootstrap it is polled for the whole grace, since the one just started
/// takes over once the other stops. `kickstart -k` happens only when that
/// answer is attributable to our launchd job: this run did not bootstrap
/// it (a job loaded seconds ago already runs the bundle's binary, so `-k`
/// cannot change the answer), no superseded label is still loaded, and the
/// pid launchd reports for our label is the pid listening on the port. A
/// Debug daemon run from Xcode holds the port with no label; killing the
/// launchd job then would only interrupt it (perhaps mid-migration).
/// Every skipped kickstart leaves a progress note.
public struct DaemonRestartJob: StartupJob {
    public let id = "daemon-restart"
    public var title: String { "Starting the \(target.name) daemon" }
    public let target: DaemonTarget
    public let bundleVersion: String
    public let health: @Sendable () async -> String?
    public let commands: any CommandRunning
    public var grace: Duration
    public var pollInterval: Duration
    public var timeout: Duration
    public var sleep: @Sendable (Duration) async throws -> Void
    public var now: @Sendable () -> ContinuousClock.Instant

    public init(target: DaemonTarget, bundleVersion: String, health: @escaping @Sendable () async -> String?,
                commands: any CommandRunning, grace: Duration = .seconds(15),
                pollInterval: Duration = .milliseconds(500), timeout: Duration = .seconds(60),
                sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
                now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }) {
        self.target = target
        self.bundleVersion = bundleVersion
        self.health = health
        self.commands = commands
        self.grace = grace
        self.pollInterval = pollInterval
        self.timeout = timeout
        self.sleep = sleep
        self.now = now
    }

    @MainActor public func run(context: StartupJobContext) async throws {
        let domain = Launchctl.guiDomain()
        let launchTarget = Launchctl.guiTarget(target.label)
        var bootstrapped = false
        if await commands.run([Launchctl.path, "print", launchTarget]).status != 0 {
            try await bootstrap(domain, target: launchTarget)
            bootstrapped = true
        }

        switch try await pollThroughGrace(stopOnDifferent: !bootstrapped) {
        case .matched:
            return
        case .silent:
            if !bootstrapped, await Launchctl.pid(of: launchTarget, commands: commands) == nil {
                try await start(["kickstart", launchTarget])
                return
            }
            context.progress("The daemon is still starting; it will be ready shortly.")
            return
        case .different:
            break
        }

        if bootstrapped {
            context.progress("Another \(target.name) daemon is answering; the one just started will take over "
                             + "once it stops.")
            return
        }
        for superseded in target.supersededLabels {
            let printed = await commands.run([Launchctl.path, "print", Launchctl.guiTarget(superseded)])
            guard printed.status != 0 else {
                context.progress("The previous daemon is still shutting down; the new one will take over shortly.")
                return
            }
        }
        guard let ours = await Launchctl.pid(of: launchTarget, commands: commands),
              let listening = await listeningPID(), ours == listening else {
            context.progress("A \(target.name) daemon outside launchd is answering; the installed one was left "
                             + "running.")
            return
        }
        try await start(["kickstart", "-k", launchTarget])
    }

    /// Runs `launchctl <arguments>`, then polls `/health` until it reports the
    /// bundle's version, for up to `timeout`.
    private func start(_ arguments: [String]) async throws {
        let kickstart = await commands.run([Launchctl.path] + arguments)
        guard kickstart.status == 0 else {
            throw LaunchJobError.command("launchctl kickstart", kickstart.status, kickstart.output)
        }
        let poll = DaemonPoll(interval: pollInterval, sleep: sleep, now: now)
        let version = await poll.ask(health, until: { $0.map(matches) ?? false }, deadline: now() + timeout)
        guard let version, matches(version) else {
            throw LaunchJobError.command("daemon /health", -1, "still not reporting \(bundleVersion) after \(timeout)")
        }
    }

    private enum Poll { case matched, different, silent }

    /// Polls for the whole grace (at least once); reports the last answer, or
    /// the first different one when `stopOnDifferent`.
    private func pollThroughGrace(stopOnDifferent: Bool) async throws -> Poll {
        let deadline = now() + grace
        var last = Poll.silent
        repeat {
            if let version = await health() {
                if matches(version) { return .matched }
                if stopOnDifferent { return .different }
                last = .different
            } else {
                last = .silent
            }
            try await sleep(pollInterval)
        } while now() < deadline
        return last
    }

    /// The one pid listening on the daemon's port; nil when there is none,
    /// more than one, or the output does not parse.
    private func listeningPID() async -> Int32? {
        let lsof = await commands.capture(["/usr/sbin/lsof", "-nP", "-iTCP:\(target.httpPort)", "-sTCP:LISTEN", "-t"],
                                          environment: nil)
        guard lsof.status == 0 else { return nil }
        let lines = lsof.stdout.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let pids = lines.compactMap { Int32($0) }
        guard !pids.isEmpty, pids.count == lines.count, Set(pids).count == 1 else { return nil }
        return pids[0]
    }

    private func matches(_ daemonVersion: String) -> Bool {
        daemonVersion == bundleVersion
    }

    /// "Already loaded" (the launch-agent job got there first) counts as success.
    private func bootstrap(_ domain: String, target launchTarget: String) async throws {
        let result = await commands.run([Launchctl.path, "bootstrap", domain, target.plistURL.path])
        guard result.status != 0 else { return }
        guard await commands.run([Launchctl.path, "print", launchTarget]).status == 0 else {
            throw LaunchJobError.command("launchctl bootstrap", result.status, result.output)
        }
    }
}
