import XCTest
import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// Thread-safe collector for `onStatusChange` broadcasts in tests.
private final class StatusCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [(id: String, status: String)] = []
    var calls: [(id: String, status: String)] { lock.withLock { stored } }
    func record(_ id: String, _ status: SessionStatus) {
        lock.withLock { stored.append((id, status.rawValue)) }
    }
}

/// LivenessService reconciles session status against live `claude` processes: a
/// session is active while its process exists, ended when it doesn't — idle time
/// is irrelevant. Process enumeration is injected (`liveProcesses`)
/// so the logic runs without real processes. Directories are real temp dirs
/// resolved through `canonicalPath`, mirroring production (the daemon matches the
/// canonical cwd a live `claude` reports against the stored session cwd).
final class LivenessServiceTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    private var createdDirs: [String] = []

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
        for dir in createdDirs { try? FileManager.default.removeItem(atPath: dir) }
        createdDirs = []
    }

    /// A real temp directory, returned in canonical form (as a live claude's cwd
    /// and a /Users project cwd both are in production).
    private func makeProjectDir() throws -> String {
        let dir = NSTemporaryDirectory() + "lt-proj-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        createdDirs.append(dir)
        return ProcessLiveness.canonicalPath(dir)
    }

    /// `at` is the event's time, which becomes the session's `last_activity_at`;
    /// pass it where a test depends on which session is the more recent.
    private func seedSession(_ id: String, cwd: String, at date: Date = Date()) throws {
        let hook: [String: Any] = [
            "session_id": id, "cwd": cwd, "model": "sonnet", "pid": 0, "term_program": "TestRunner"
        ]
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try database.ingestEvent(eventType: "SessionStart", timestamp: fmt.string(from: date), hookData: hook)
    }

    private func status(_ id: String) throws -> String? {
        try database.fetchSession(sessionId: id)?.status
    }

    /// The pid standing in for the interactive shell that launched a CLI. Any pid
    /// that is neither 1 nor one of the `claude` processes will do: those two are
    /// what mark a process as a helper rather than a session.
    private static let shellPid: pid_t = 900

    /// Processes with no session file, `count` per directory — what an older CLI
    /// looks like, and so what exercises the directory fallback.
    private func runLiveness(liveCounts: [String: Int]) throws {
        var pid: pid_t = 1000
        var processes: [LivenessService.LiveClaudeProcess] = []
        for (directory, count) in liveCounts {
            for _ in 0..<count {
                pid += 1
                processes.append(.init(pid: pid, parentPid: Self.shellPid, cwd: directory, sessionId: nil))
            }
        }
        try runLiveness(processes: processes)
    }

    @discardableResult
    private func runLiveness(processes: [LivenessService.LiveClaudeProcess]) throws -> StatusCollector {
        let collector = StatusCollector()
        LivenessService(
            database: database, liveProcesses: { processes }, onStatusChange: { collector.record($0, $1) }
        ).reconcile()
        return collector
    }

    func testSessionWithLiveClaudeStaysActive() throws {
        let dir = try makeProjectDir()
        try seedSession("alive", cwd: dir)
        try runLiveness(liveCounts: [dir: 1])
        XCTAssertEqual(try status("alive"), "active", "a live claude in its dir → active")
    }

    func testSessionEndedWhenNoLiveClaude() throws {
        let dir = try makeProjectDir()
        try seedSession("gone", cwd: dir)
        try runLiveness(liveCounts: [try makeProjectDir(): 1])  // claude lives elsewhere
        XCTAssertEqual(try status("gone"), "ended", "no live claude in its dir → destroyed")
    }

    func testNoLiveClaudesEndsEverything() throws {
        let dir = try makeProjectDir()
        try seedSession("a", cwd: dir)
        try runLiveness(liveCounts: [:])
        XCTAssertEqual(try status("a"), "ended")
    }

    func testEndedSessionResurrectedWhenClaudeAlive() throws {
        // The key behavior: a session that already ended is brought back the moment
        // a live claude is found in its dir — alive ⇔ process exists, time-agnostic.
        let dir = try makeProjectDir()
        try seedSession("revived", cwd: dir)
        database.updateSessionStatus(.ended, sessionId: "revived")
        XCTAssertEqual(try status("revived"), "ended", "precondition: ended")

        try runLiveness(liveCounts: [dir: 1])
        XCTAssertEqual(try status("revived"), "active", "resurrected because a claude lives there")
    }

    func testCapPerCwdByLiveCount() throws {
        // Three sessions in one dir, one live claude: exactly one is active.
        let dir = try makeProjectDir()
        try seedSession("s1", cwd: dir)
        try seedSession("s2", cwd: dir)
        try seedSession("s3", cwd: dir)
        try runLiveness(liveCounts: [dir: 1])

        let statuses = try ["s1", "s2", "s3"].map { try status($0) }
        XCTAssertEqual(statuses.filter { $0 == "active" }.count, 1, "one live claude → one active")
        XCTAssertEqual(statuses.filter { $0 == "ended" }.count, 2, "the rest destroyed")
    }

    func testSymlinkedCwdCanonicalizedAtIngestMatchesLiveClaude() throws {
        // The hook reports a symlinked $PWD (e.g. /tmp/x), but libproc reports the
        // physical path. Ingest canonicalizes the stored cwd so the live claude
        // (keyed by its canonical cwd) matches — otherwise the session is wrongly ended.
        let real = try makeProjectDir()
        let link = NSTemporaryDirectory() + "lt-link-\(UUID().uuidString)"
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: real)
        createdDirs.append(link)
        try seedSession("sym", cwd: link)
        try runLiveness(liveCounts: [real: 1])
        XCTAssertEqual(try status("sym"), "active", "symlinked cwd resolved at ingest → matches live claude")
    }

    func testOnStatusChangeBroadcastsTransitions() throws {
        let dir = try makeProjectDir()
        try seedSession("dead", cwd: dir)
        let collector = try runLiveness(processes: [])
        XCTAssertEqual(collector.calls.count, 1, "exactly one transition broadcast")
        XCTAssertEqual(collector.calls.first?.id, "dead")
        XCTAssertEqual(collector.calls.first?.status, "ended")
    }

    func testEnumerationFailureDoesNotEndSessions() throws {
        // nil from liveProcesses = process enumeration failed; a bad scan must NOT
        // wipe every live session (it would self-"correct" but flap + broadcast).
        let dir = try makeProjectDir()
        try seedSession("keep", cwd: dir)
        LivenessService(database: database, liveProcesses: { nil }, onStatusChange: { _, _ in }).reconcile()
        XCTAssertEqual(try status("keep"), "active", "enumeration failure must not end live sessions")
    }

    func testCandidateLookupFailureDoesNotEndSessions() throws {
        // A database that can't answer a *directory's* lookup is the same kind of
        // silence as one that can't be asked at all: swallowed per-directory it
        // reads as "no sessions live under there", and the tick ends every one.
        // An unmigrated database makes every `SELECT … FROM sessions` throw.
        let path = NSTemporaryDirectory() + "liveness-nodb-\(UUID().uuidString).db"
        let unmigrated = try DaemonDatabase(
            path: path, deferMigrations: true, migrations: SessionSchema.migrations
        )
        defer { TestDaemonDatabase.remove(path: path) }
        let process = LivenessService.LiveClaudeProcess(
            pid: 1001, parentPid: Self.shellPid, cwd: "/tmp/anywhere", sessionId: nil
        )

        XCTAssertNil(
            LivenessService.liveSessionIds(processes: [process], database: unmigrated),
            "a lookup the database couldn't answer must skip the tick, not read as 'no sessions'"
        )
    }

    // MARK: - Which session a live directory owns

    /// A subdirectory of the session's own directory, created on disk and canonical.
    private func makeSubdir(of parent: String, named name: String) throws -> String {
        let dir = parent + "/" + name
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return ProcessLiveness.canonicalPath(dir)
    }

    func testSessionBelowTheLiveDirectoryStaysActive() throws {
        // A live `claude` reports the directory it was launched in; the session row
        // records the hook *shell's* $PWD, which moves the first time the agent runs
        // something from a subdirectory. Equality matching ended the session, the next
        // hook resurrected it, and the row blinked in and out of the window.
        let launched = try makeProjectDir()
        let moved = try makeSubdir(of: launched, named: "packages/app")
        try seedSession("wandered", cwd: moved)

        try runLiveness(liveCounts: [launched: 1])

        XCTAssertEqual(try status("wandered"), "active",
                       "a session below the live claude's directory is that claude's")
    }

    func testWorktreeSessionDoesNotTakeTheProjectRootsSlot() throws {
        // The flicker: the root's candidate query spans its whole subtree, so the
        // root's single slot went to whichever subtree session was most recently
        // active — resurrecting a dead worktree session while ending the live one
        // whose cwd *is* the root. Each directory must claim only the sessions it is
        // the deepest live directory for.
        let root = try makeProjectDir()
        let worktree = try makeSubdir(of: root, named: ".claude/worktrees/feature")

        try seedSession("at-root", cwd: root)
        try seedSession("in-worktree", cwd: worktree)
        // The worktree session is the more recently active of the two, which is what
        // used to win it the root's slot.
        database.updateSessionStatus(.ended, sessionId: "in-worktree")

        try runLiveness(liveCounts: [root: 1])

        XCTAssertEqual(try status("at-root"), "active",
                       "the session actually sitting in the live directory keeps its slot")
        XCTAssertEqual(try status("in-worktree"), "ended",
                       "no live claude in the worktree → its session is not resurrected")
    }

    func testDeepestLiveDirectoryOwnsItsOwnSession() throws {
        // Both directories host a live claude. The worktree is the deeper of the two,
        // so it owns its own session and the root is left with the one that is really
        // its own — neither directory's slot is spent on the other's session.
        let root = try makeProjectDir()
        let worktree = try makeSubdir(of: root, named: ".claude/worktrees/feature")
        try seedSession("at-root", cwd: root)
        try seedSession("in-worktree", cwd: worktree)

        try runLiveness(liveCounts: [root: 1, worktree: 1])

        XCTAssertEqual(try status("at-root"), "active")
        XCTAssertEqual(try status("in-worktree"), "active")
    }

    func testSiblingDirectoryIsNotTreatedAsASubdirectory() throws {
        // Containment is compared on whole path components: `/a/bc` is not under
        // `/a/b`, even though its path has that prefix.
        let parent = try makeProjectDir()
        let live = try makeSubdir(of: parent, named: "b")
        let sibling = try makeSubdir(of: parent, named: "bc")
        try seedSession("sibling", cwd: sibling)

        try runLiveness(liveCounts: [live: 1])

        XCTAssertEqual(try status("sibling"), "ended",
                       "a name-prefix sibling is not below the live directory")
    }

    // MARK: - A process's own session file

    func testSessionFileKeepsAMovedSessionOverTheOneItsProcessLeftBehind() throws {
        // The whippet vsc-plugins flicker. One terminal ran a session at the worktree
        // root, then a newer one that `cd`-ed into a submodule. The process still
        // reports the root, where the old session sits at depth 0, so the directory
        // rule gave the old session the slot and ended the live one — which its next
        // hook resurrected, over and over.
        let root = try makeProjectDir()
        let submodule = try makeSubdir(of: root, named: "external/agenticdevelopertoolkit")
        let now = Date()
        try seedSession("superseded", cwd: root, at: now.addingTimeInterval(-86_400))
        try seedSession("current", cwd: submodule, at: now)

        try runLiveness(processes: [.init(pid: 54_753, parentPid: 1, cwd: root, sessionId: "current")])

        XCTAssertEqual(try status("current"), "active", "the session the process names is live wherever it moved")
        XCTAssertEqual(try status("superseded"), "ended", "the session the process left behind is not")
    }

    func testSessionFileKeepsAnEnteredWorktreeSessionOverANewerGhostAtTheRoot() throws {
        // The whippet file-browser flicker. The session ran `EnterWorktree`, so its
        // cwd is the worktree, but its process was launched at the project root — where
        // a session from a terminal closed long ago was more recently active.
        let root = try makeProjectDir()
        let worktree = try makeSubdir(of: root, named: ".claude/worktrees/file-browser")
        let now = Date()
        try seedSession("entered-worktree", cwd: worktree, at: now.addingTimeInterval(-600))
        try seedSession("ghost", cwd: root, at: now)

        try runLiveness(processes: [.init(pid: 95_249, parentPid: 1, cwd: root, sessionId: "entered-worktree")])

        XCTAssertEqual(try status("entered-worktree"), "active")
        XCTAssertEqual(try status("ghost"), "ended", "a named process leaves no slot for the directory to hand out")
    }

    func testHelperProcessesOfALiveClaudeClaimNothing() throws {
        // A background agent runs as a daemon launched from the home directory plus a
        // pty host beside the session; neither writes a session file. Counted by
        // directory, the daemon resurrected whatever dead session was newest there.
        let home = try makeProjectDir()
        let project = try makeSubdir(of: home, named: "project")
        try seedSession("real", cwd: project)
        try seedSession("dead-under-home", cwd: try makeSubdir(of: home, named: "elsewhere"))

        try runLiveness(processes: [
            .init(pid: 100, parentPid: 1, cwd: project, sessionId: "real"),
            .init(pid: 101, parentPid: 100, cwd: home, sessionId: nil),       // its daemon
            .init(pid: 102, parentPid: 101, cwd: project, sessionId: nil)     // the daemon's pty host
        ])

        XCTAssertEqual(try status("real"), "active")
        XCTAssertEqual(try status("dead-under-home"), "ended", "a helper process is not a session")
    }

    func testUnnamedProcessDoesNotClaimTheSessionANamedProcessOwns() throws {
        // Two processes in one directory, only one with a session file. The other
        // falls back to the directory — and must pick among the sessions still
        // unaccounted for, not take the newest one, which the named process owns.
        let dir = try makeProjectDir()
        let now = Date()
        try seedSession("older", cwd: dir, at: now.addingTimeInterval(-60))
        try seedSession("newer", cwd: dir, at: now)

        try runLiveness(processes: [
            .init(pid: 200, parentPid: 1, cwd: dir, sessionId: "newer"),
            .init(pid: 201, parentPid: Self.shellPid, cwd: dir, sessionId: nil)
        ])

        XCTAssertEqual(try status("newer"), "active")
        XCTAssertEqual(try status("older"), "active", "the unnamed process accounts for the other session")
    }

    func testOrphanedHelperClaimsNothing() throws {
        // The permanent version of testHelperProcessesOfALiveClaudeClaimNothing: the
        // `claude` that spawned the helper exits, launchd adopts the orphan, and
        // nothing ever reaps it. Matching only on a parent that is still a live
        // `claude` let it back in and it resurrected the dead session in its
        // directory on every tick, forever.
        let home = try makeProjectDir()
        let project = try makeSubdir(of: home, named: "project")
        try seedSession("real", cwd: project)
        try seedSession("dead-under-home", cwd: try makeSubdir(of: home, named: "elsewhere"))

        try runLiveness(processes: [
            .init(pid: 100, parentPid: Self.shellPid, cwd: project, sessionId: "real"),
            .init(pid: 101, parentPid: 1, cwd: home, sessionId: nil)  // reparented to launchd
        ])

        XCTAssertEqual(try status("real"), "active")
        XCTAssertEqual(try status("dead-under-home"), "ended", "an orphaned helper is still not a session")
    }

    func testProcessWithNoWorkingDirectoryClaimsNothing() throws {
        // The kernel refuses a cwd for a process whose directory was deleted, and for
        // one this daemon may not inspect. An empty path "contains" every session on
        // the machine, so counted it would resurrect all of them at once.
        let dir = try makeProjectDir()
        try seedSession("dead", cwd: dir)
        database.updateSessionStatus(.ended, sessionId: "dead")

        try runLiveness(processes: [
            .init(pid: 300, parentPid: Self.shellPid, cwd: "", sessionId: nil)
        ])

        XCTAssertEqual(try status("dead"), "ended", "a process with no cwd matches nothing")
    }

    func testSessionFileNamingAnUningestedSessionBroadcastsNothing() throws {
        // The daemon drops its own headless runs at ingest, so their processes name
        // sessions with no row. Promoting one would broadcast a status for a session
        // the app has never seen, on every tick.
        let collector = try runLiveness(processes: [
            .init(pid: 300, parentPid: 1, cwd: try makeProjectDir(), sessionId: "never-ingested")
        ])

        XCTAssertTrue(collector.calls.isEmpty, "got \(collector.calls)")
    }

    func testSessionFileIsReadOnlyForItsOwnPid() throws {
        let file = Data(#"{"pid":4242,"sessionId":"abc","cwd":"/x","kind":"interactive"}"#.utf8)
        XCTAssertEqual(ProcessLiveness.sessionId(fromSessionFile: file, pid: 4242), "abc")
        XCTAssertNil(ProcessLiveness.sessionId(fromSessionFile: file, pid: 4243),
                     "a file left by a dead process whose pid was reused names someone else's session")
        XCTAssertNil(ProcessLiveness.sessionId(fromSessionFile: Data(#"{"pid":4242,"sessionId":""}"#.utf8), pid: 4242))
        XCTAssertNil(ProcessLiveness.sessionId(fromSessionFile: Data("not json".utf8), pid: 4242))
    }

    func testSessionFileIsFoundUnderTheProcessesConfigDirectory() throws {
        let configDir = try makeProjectDir()
        try FileManager.default.createDirectory(atPath: configDir + "/sessions", withIntermediateDirectories: true)
        try Data(#"{"pid":777,"sessionId":"from-config-dir"}"#.utf8)
            .write(to: URL(fileURLWithPath: configDir + "/sessions/777.json"))

        XCTAssertEqual(
            ProcessLiveness.currentSessionId(ofPid: 777, environment: ["CLAUDE_CONFIG_DIR": configDir]),
            "from-config-dir"
        )
    }

    func testLiveProcessEnumerationSucceedsWithCanonicalDirectories() throws {
        // Enumeration runs against the real process table: it must succeed, and every
        // process it reports carries a canonical directory.
        let processes = try XCTUnwrap(ProcessLiveness.liveClaudeProcesses())
        for process in processes {
            XCTAssertEqual(process.cwd, ProcessLiveness.canonicalPath(process.cwd))
        }
    }
}
