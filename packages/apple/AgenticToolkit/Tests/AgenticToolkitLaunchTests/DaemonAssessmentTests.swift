import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitLaunch

private final class Answers: @unchecked Sendable {
    private let lock = NSLock()
    private var remaining: [String?]
    init(_ answers: [String?]) { remaining = answers }
    func next() -> String? { lock.withLock { remaining.isEmpty ? nil : remaining.removeFirst() } }
}

/// Answers `launchctl print` from a list of statuses in order (the last repeats)
/// and every `bootstrap` with a fixed status. Test-only.
private final class ScriptedCommands: CommandRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var printStatuses: [Int32]
    private let bootstrapStatus: Int32
    private var recorded: [[String]] = []
    init(printStatuses: [Int32], bootstrapStatus: Int32) {
        self.printStatuses = printStatuses
        self.bootstrapStatus = bootstrapStatus
    }
    var calls: [[String]] { lock.withLock { recorded } }
    func run(_ argv: [String]) async -> (status: Int32, output: String) {
        lock.withLock {
            recorded.append(argv)
            switch argv[1] {
            case "print": return (printStatuses.count > 1 ? printStatuses.removeFirst() : printStatuses[0], "")
            case "bootstrap": return (bootstrapStatus, "already loaded")
            default: return (0, "")
            }
        }
    }
}

/// A clock only `advance` moves, so no test depends on real time. The base is
/// read once; only differences from it matter. Lock-guarded; test-only.
private final class FakeClock: @unchecked Sendable {
    private let lock = NSLock()
    private let base = ContinuousClock.now
    private var elapsed = Duration.zero
    func now() -> ContinuousClock.Instant { lock.withLock { base + elapsed } }
    func advance(_ span: Duration) { lock.withLock { elapsed += span } }
}

/// A one-way flag set from one task and read from another. Lock-guarded; test-only.
private final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    var isSet: Bool { lock.withLock { value } }
    func set() { lock.withLock { value = true } }
}

/// Like `Answers`, but a nil entry means "daemon silent"; exhausted is silent too.
private final class OptionalAnswers: @unchecked Sendable {
    private let lock = NSLock()
    private var remaining: [String?]
    init(_ answers: [String?]) { remaining = answers }
    func next() -> String? { lock.withLock { remaining.isEmpty ? nil : remaining.removeFirst() } }
}

final class DaemonAssessmentTests: XCTestCase {
    private var home: URL!
    private let label = "com.example.daemon"
    private let legacyLabel = "com.example.old-daemon"
    private let port = 22999

    override func setUpWithError() throws {
        home = FileManager.default.temporaryDirectory.appendingPathComponent("das-\(UUID())")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: home)
    }

    private var target: DaemonTarget {
        DaemonTarget(name: "Example", label: label, plistURL: home.appendingPathComponent("d.plist"),
                     httpPort: port, stopMarkerURL: home.appendingPathComponent("stopped"),
                     supersededLabels: [legacyLabel])
    }

    // MARK: Daemon

    private func daemon(answers: [String?], registered: Bool = true, stopped: Bool = false) -> DaemonAssessment {
        let queue = OptionalAnswers(answers)
        return DaemonAssessment(target: target, bundleVersion: "1.0.174.0", health: { queue.next() },
                                commands: RecordingCommands(), isRegistered: { registered },
                                stoppedDeliberately: { stopped })
    }

    func testDaemonQueuedWhenAnsweringDifferentVersion() async {
        let jobs = await daemon(answers: ["1.0.173.0"]).assess()
        XCTAssertEqual(jobs.map(\.id), ["daemon-restart"])
    }

    func testDaemonNothingWhenVersionMatches() async {
        let jobs = await daemon(answers: ["1.0.174.0"]).assess()
        XCTAssertTrue(jobs.isEmpty)
    }

    func testDaemonQueuedWhenSilent() async {
        let jobs = await daemon(answers: []).assess()
        XCTAssertEqual(jobs.map(\.id), ["daemon-restart"])
    }

    func testDaemonQueuedWhenNotRegistered() async {
        let jobs = await daemon(answers: ["1.0.174.0"], registered: false).assess()
        XCTAssertEqual(jobs.map(\.id), ["daemon-restart"])
    }

    func testDaemonRespectsDeliberateStop() async {
        let jobs = await daemon(answers: [], registered: false, stopped: true).assess()
        XCTAssertTrue(jobs.isEmpty)
    }

    /// The two probes are independent, so `assess` sends both at once: the
    /// registration check here only sees the health probe start if it runs
    /// beside it.
    func testDaemonProbesRegistrationAndHealthConcurrently() async {
        let healthStarted = Flag()
        let sawHealth = Flag()
        let assessment = DaemonAssessment(
            target: target,
            bundleVersion: "1.0.174.0",
            health: { healthStarted.set(); return "1.0.174.0" },
            commands: RecordingCommands(),
            isRegistered: {
                for _ in 0..<2000 where !healthStarted.isSet { try? await Task.sleep(for: .milliseconds(1)) }
                if healthStarted.isSet { sawHealth.set() }
                return true
            },
            stoppedDeliberately: { false })
        let jobs = await assessment.assess()
        XCTAssertTrue(jobs.isEmpty)
        XCTAssertTrue(sawHealth.isSet, "the health probe waited for the registration check")
    }

    func testDaemonNothingForUnversionedBundle() async {
        let jobs = await DaemonAssessment(target: target, bundleVersion: "", health: { nil },
                                          commands: RecordingCommands(), isRegistered: { false },
                                          stoppedDeliberately: { false }).assess()
        XCTAssertTrue(jobs.isEmpty)
    }

    // MARK: Daemon job

    private var launchctlTarget: String { "gui/\(getuid())/\(label)" }

    private func daemonJob(commands: any CommandRunning, answers: [String?], grace: Duration = .seconds(5),
                           timeout: Duration = .seconds(5)) -> DaemonRestartJob {
        let queue = OptionalAnswers(answers)
        let clock = FakeClock()
        return DaemonRestartJob(target: target, bundleVersion: "1.0.174.0", health: { queue.next() },
                                commands: commands, grace: grace, pollInterval: .seconds(1), timeout: timeout,
                                sleep: { clock.advance($0) }, now: { clock.now() })
    }

    private var legacyTarget: String { "gui/\(getuid())/\(legacyLabel)" }

    private var lsofArgv: [String] { ["/usr/sbin/lsof", "-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-t"] }

    /// A recorder where the legacy label is already gone, launchd reports our
    /// job as pid 4242, and `lsof` answers `listening` for the port.
    private func commandsWithLegacyGone(listening: String = "4242\n") -> RecordingCommands {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print \(legacyTarget)"] = (113, "")
        commands.responses["/bin/launchctl print \(launchctlTarget)"] = (0, "{\n\tstate = running\n\tpid = 4242\n}\n")
        commands.responses[lsofArgv.joined(separator: " ")] = (0, listening)
        return commands
    }

    private func persistentlyDifferent() -> [String?] { Array(repeating: "1.0.173.0", count: 20) }

    @MainActor private func runDaemon(_ job: DaemonRestartJob,
                                      notes: ProgressMessages = ProgressMessages()) async throws {
        try await job.run(context: StartupJobContext(privileged: RecordingPrivileged(),
                                                     progress: { notes.append($0) }))
    }

    @MainActor func testDaemonJobLoadedAndMatchingDoesNothingMore() async throws {
        let commands = RecordingCommands()
        try await runDaemon(daemonJob(commands: commands, answers: ["1.0.174.0"]))
        XCTAssertEqual(commands.calls, [["/bin/launchctl", "print", launchctlTarget]])
    }

    @MainActor func testDaemonJobWaitsOutAStartingDaemonWithoutKickstart() async throws {
        let commands = RecordingCommands()
        try await runDaemon(daemonJob(commands: commands, answers: [nil, nil, "1.0.174.0"]))
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
    }

    @MainActor func testDaemonJobSilentAfterGraceWithAProcessSucceedsWithNoteAndNoKickstart() async throws {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print \(launchctlTarget)"] = (0, "{\n\tpid = 77\n}\n")
        let notes = ProgressMessages()
        try await runDaemon(daemonJob(commands: commands, answers: []), notes: notes)
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
        XCTAssertEqual(notes.items.count, 1)
        XCTAssertTrue(notes.items[0].contains("still starting"))
    }

    /// A loaded job whose process exited cleanly (`KeepAlive {Crashed}` never
    /// relaunches it) is started, not reported as "still starting".
    @MainActor func testDaemonJobStartsALoadedJobWithNoProcess() async throws {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print \(launchctlTarget)"] = (0, "{\n\tstate = not running\n}\n")
        let notes = ProgressMessages()
        let silentThroughGrace = [String?](repeating: nil, count: 6)
        try await runDaemon(daemonJob(commands: commands, answers: silentThroughGrace + ["1.0.174.0"],
                                      timeout: .seconds(10)), notes: notes)
        XCTAssertEqual(commands.calls, [["/bin/launchctl", "print", launchctlTarget],
                                        ["/bin/launchctl", "print", launchctlTarget],
                                        ["/bin/launchctl", "kickstart", launchctlTarget]])
        XCTAssertTrue(notes.items.isEmpty)
    }

    @MainActor func testDaemonJobThrowsWhenAStartedJobNeverAnswers() async {
        let commands = RecordingCommands()
        let job = daemonJob(commands: commands, answers: [], timeout: .seconds(3))
        do {
            try await runDaemon(job)
            XCTFail("expected a throw")
        } catch let error as LaunchJobError {
            XCTAssertTrue(error.localizedDescription.contains("daemon /health"))
            XCTAssertTrue(commands.calls.contains(["/bin/launchctl", "kickstart", launchctlTarget]))
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    @MainActor func testDaemonJobAfterBootstrapWaitsOutAnOldProcessThatAnswersOnce() async throws {
        // An old process shutting down answers once, goes silent, then the new daemon matches.
        let commands = commandsWithLegacyGone()
        commands.respond(to: ["/bin/launchctl", "print", launchctlTarget], inOrder: [(113, "")])
        let notes = ProgressMessages()
        try await runDaemon(daemonJob(commands: commands, answers: ["1.0.173.0", nil, "1.0.174.0"]), notes: notes)
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
        XCTAssertTrue(notes.items.isEmpty)
    }

    /// Without a bootstrap this run, the first different answer is the old,
    /// still-running daemon beside an updated bundle: no grace is waited out.
    @MainActor func testDaemonJobKillsOnTheFirstDifferentAnswerWhenItDidNotBootstrap() async throws {
        let commands = commandsWithLegacyGone()
        let answers = Answers(["1.0.173.0", "1.0.174.0"])
        let clock = FakeClock()
        let job = DaemonRestartJob(target: target, bundleVersion: "1.0.174.0", health: { answers.next() },
                                   // swiftlint:disable:next line_length
                                   commands: commands, grace: .seconds(15), pollInterval: .seconds(1), timeout: .seconds(5),
                                   sleep: { clock.advance($0) }, now: { clock.now() })
        try await runDaemon(job)
        XCTAssertEqual(commands.calls, [["/bin/launchctl", "print", launchctlTarget],
                                        ["/bin/launchctl", "print", legacyTarget],
                                        ["/bin/launchctl", "print", launchctlTarget],
                                        lsofArgv,
                                        ["/bin/launchctl", "kickstart", "-k", launchctlTarget]])
        XCTAssertLessThan(clock.now() - ContinuousClock.now, .seconds(15), "the grace was waited out")
    }

    @MainActor func testDaemonJobNeverKillsADaemonItBootstrappedThisRun() async throws {
        let commands = commandsWithLegacyGone()
        commands.respond(to: ["/bin/launchctl", "print", launchctlTarget], inOrder: [(113, "")])
        let notes = ProgressMessages()
        try await runDaemon(daemonJob(commands: commands, answers: persistentlyDifferent()), notes: notes)
        XCTAssertTrue(commands.calls.contains { $0.contains("bootstrap") })
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
        XCTAssertEqual(notes.items.count, 1)
        XCTAssertTrue(notes.items[0].contains("just started"))
    }

    @MainActor func testDaemonJobNeverKillsWhenAnotherProcessHoldsThePort() async throws {
        let commands = commandsWithLegacyGone(listening: "999\n")
        let notes = ProgressMessages()
        try await runDaemon(daemonJob(commands: commands, answers: persistentlyDifferent()), notes: notes)
        XCTAssertTrue(commands.calls.contains(lsofArgv))
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
        XCTAssertEqual(notes.items.count, 1)
        XCTAssertTrue(notes.items[0].contains("outside launchd"))
    }

    @MainActor func testDaemonJobKillsWhenLaunchdPidIsTheListeningPid() async throws {
        let commands = commandsWithLegacyGone(listening: "4242\n")
        try await runDaemon(daemonJob(commands: commands, answers: persistentlyDifferent() + ["1.0.174.0"],
                                      grace: .seconds(5), timeout: .seconds(30)))
        XCTAssertEqual(commands.calls.last, ["/bin/launchctl", "kickstart", "-k", launchctlTarget])
    }

    @MainActor func testDaemonJobNeverKillsWhenLsofOutputDoesNotParse() async throws {
        for listening in ["", "not-a-pid\n", "4242\n999\n"] {
            let commands = commandsWithLegacyGone(listening: listening)
            let notes = ProgressMessages()
            try await runDaemon(daemonJob(commands: commands, answers: persistentlyDifferent()), notes: notes)
            XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") }, "lsof said \(listening)")
            XCTAssertEqual(notes.items.count, 1, "lsof said \(listening)")
        }
    }

    @MainActor func testDaemonJobSkipsKickstartWhileTheLegacyLabelIsStillLoaded() async throws {
        let commands = RecordingCommands()
        let notes = ProgressMessages()
        try await runDaemon(daemonJob(commands: commands, answers: persistentlyDifferent()), notes: notes)
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
        XCTAssertEqual(notes.items.count, 1)
        XCTAssertTrue(notes.items[0].contains("previous daemon"))
    }

    @MainActor func testDaemonJobThrowsWhenTheVersionNeverArrivesAfterKickstart() async {
        let job = daemonJob(commands: commandsWithLegacyGone(),
                            answers: Array(repeating: "1.0.173.0", count: 40), timeout: .seconds(3))
        do {
            try await runDaemon(job)
            XCTFail("expected a throw")
        } catch let error as LaunchJobError {
            XCTAssertTrue(error.localizedDescription.contains("daemon /health"))
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    @MainActor func testDaemonJobBootstrapsWhenNotLoaded() async throws {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print \(launchctlTarget)"] = (113, "")
        let job = daemonJob(commands: commands, answers: ["1.0.174.0"])
        try await runDaemon(job)
        XCTAssertEqual(commands.calls.last, ["/bin/launchctl", "bootstrap", "gui/\(getuid())",
                                             home.appendingPathComponent("d.plist").path])
    }

    @MainActor func testDaemonJobAlreadyBootstrappedByTheLaunchAgentJobSucceeds() async throws {
        // First print: not loaded. Bootstrap loses the race (37). The follow-up print finds it loaded.
        let commands = ScriptedCommands(printStatuses: [113, 0], bootstrapStatus: 37)
        try await runDaemon(daemonJob(commands: commands, answers: ["1.0.174.0"]))
        XCTAssertFalse(commands.calls.contains { $0.contains("kickstart") })
        XCTAssertEqual(commands.calls.map { $0[1] }, ["print", "bootstrap", "print"])
    }

    @MainActor func testDaemonJobThrowsWhenBootstrapFailsAndJobStaysUnloaded() async {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print \(launchctlTarget)"] = (113, "")
        commands.responses["/bin/launchctl bootstrap gui/\(getuid()) \(home.appendingPathComponent("d.plist").path)"]
            = (5, "denied")
        do {
            try await runDaemon(daemonJob(commands: commands, answers: []))
            XCTFail("expected a throw")
        } catch let error as LaunchJobError {
            XCTAssertTrue(error.localizedDescription.contains("launchctl bootstrap"))
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

}
