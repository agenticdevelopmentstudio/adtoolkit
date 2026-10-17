import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// Exercises `SessionEnricher.projectRoot` against real on-disk git repositories,
/// including a submodule, to verify it resolves the top-level (non-submodule)
/// project root for a session's cwd.
final class SessionEnricherTests: XCTestCase {

    private var tempRoots: [String] = []

    override func tearDownWithError() throws {
        for path in tempRoots { try? FileManager.default.removeItem(atPath: path) }
        tempRoots.removeAll()
    }

    // MARK: - Helpers

    /// Creates a unique temp directory and tracks it for cleanup. The returned
    /// path may differ from git's output by the /var → /private/var symlink, so
    /// tests compare via git-to-git equality and last path component rather than
    /// absolute-path equality.
    private func makeTempDir(_ tag: String) throws -> String {
        let path = NSTemporaryDirectory() + "enricher-\(tag)-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        tempRoots.append(path)
        return path
    }

    /// The last path component of a directory — stable across the /var symlink.
    private func dirName(_ path: String) -> String { (path as NSString).lastPathComponent }

    @discardableResult
    private func git(_ args: [String], in dir: String) -> (status: Int32, output: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        proc.arguments = ["-C", dir] + args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        // Deterministic identity so commits succeed without a global gitconfig.
        var env = ProcessInfo.processInfo.environment
        env["GIT_AUTHOR_NAME"] = "Test"
        env["GIT_AUTHOR_EMAIL"] = "test@example.com"
        env["GIT_COMMITTER_NAME"] = "Test"
        env["GIT_COMMITTER_EMAIL"] = "test@example.com"
        proc.environment = env
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (proc.terminationStatus, text)
    }

    /// `git init` + one seed commit so the repo has a HEAD (needed for submodules).
    private func initRepo(_ dir: String) throws {
        XCTAssertEqual(git(["init", "-q", "-b", "main"], in: dir).status, 0)
        try "seed".write(toFile: dir + "/README.md", atomically: true, encoding: .utf8)
        XCTAssertEqual(git(["add", "."], in: dir).status, 0)
        XCTAssertEqual(git(["commit", "-q", "-m", "init"], in: dir).status, 0)
    }

    // MARK: - Tests

    func testProjectRootResolvesToplevelFromSubdirectory() throws {
        let repo = try makeTempDir("repo")
        try initRepo(repo)
        let nested = repo + "/a/b/c"
        try FileManager.default.createDirectory(atPath: nested, withIntermediateDirectories: true)

        let rootFromRepo = SessionEnricher.projectRoot(at: repo)
        XCTAssertNotNil(rootFromRepo)
        // A subdir resolves to the same toplevel as the repo root...
        XCTAssertEqual(SessionEnricher.projectRoot(at: nested), rootFromRepo)
        // ...which is the repo directory itself.
        XCTAssertEqual(rootFromRepo.map(dirName), dirName(repo))
    }

    func testProjectRootCollapsesWorktreeToMainRepo() throws {
        let repo = try makeTempDir("repo")
        try initRepo(repo)

        // Add a linked worktree (outside the repo) on a new branch.
        let worktree = try makeTempDir("wt-parent") + "/wt"
        let add = git(["worktree", "add", "-b", "feature", worktree], in: repo)
        try XCTSkipIf(add.status != 0, "git worktree add unavailable: \(add.output)")

        // A session in the linked worktree resolves to the MAIN working tree, so
        // every worktree of a project groups under one root — not the worktree dir.
        XCTAssertEqual(SessionEnricher.projectRoot(at: worktree).map(dirName), dirName(repo))
        XCTAssertNotEqual(SessionEnricher.projectRoot(at: worktree).map(dirName), dirName(worktree))
        // The main checkout still resolves to itself.
        XCTAssertEqual(SessionEnricher.projectRoot(at: repo).map(dirName), dirName(repo))
    }

    func testProjectRootIsNilOutsideGit() throws {
        let plain = try makeTempDir("plain")
        XCTAssertNil(SessionEnricher.projectRoot(at: plain))
    }

    func testProjectRootIsNilForMissingPath() {
        XCTAssertNil(SessionEnricher.projectRoot(at: "/no/such/dir-\(UUID().uuidString)"))
        XCTAssertNil(SessionEnricher.projectRoot(at: ""))
    }

    func testProjectRootClimbsOutOfSubmodule() throws {
        let sub = try makeTempDir("sub")
        try initRepo(sub)

        let superproject = try makeTempDir("super")
        try initRepo(superproject)

        // Local-file submodules need protocol.file.allow=always on modern git.
        let add = git(
            ["-c", "protocol.file.allow=always", "submodule", "add", sub, "external/sub"],
            in: superproject
        )
        try XCTSkipIf(add.status != 0, "git submodule add unavailable in this environment: \(add.output)")

        let submoduleWorkdir = superproject + "/external/sub"
        let rootFromSuper = SessionEnricher.projectRoot(at: superproject)
        XCTAssertNotNil(rootFromSuper)
        // From inside the submodule, the project root climbs to the superproject —
        // not the submodule's own toplevel.
        XCTAssertEqual(SessionEnricher.projectRoot(at: submoduleWorkdir), rootFromSuper)
        XCTAssertEqual(rootFromSuper.map(dirName), dirName(superproject))
        XCTAssertNotEqual(rootFromSuper.map(dirName), dirName(sub))

        // A deeper directory inside the submodule resolves the same top project.
        let deep = submoduleWorkdir + "/x/y"
        try FileManager.default.createDirectory(atPath: deep, withIntermediateDirectories: true)
        XCTAssertEqual(SessionEnricher.projectRoot(at: deep), rootFromSuper)
    }

    // MARK: - Resolution outcome

    // `projectRoot` flattens three different answers into `nil`, and the enrichment
    // sweep has to tell them apart: "examined, nothing to find" is stampable at the
    // current algorithm version, "couldn't ask" is not. Stamping the second wrote
    // `project_root = ''` through a one-way door, and the window then fell back to
    // the cwd's last component — which is how a worktree's own name ended up
    // labelling the project, once per cwd.

    func testResolutionSaysNotAGitWorkingTreeForAPlainDirectory() throws {
        let plain = try makeTempDir("plain-resolution")
        XCTAssertEqual(SessionEnricher.projectRootResolution(at: plain), .notAGitWorkingTree)
    }

    func testResolutionCollapsesALinkedWorktreeToTheMainWorkingTree() throws {
        let repo = try makeTempDir("repo-resolution")
        try initRepo(repo)
        let worktree = try makeTempDir("wt-resolution-parent") + "/wt"
        let add = git(["worktree", "add", "-b", "resolution", worktree], in: repo)
        try XCTSkipIf(add.status != 0, "git worktree add unavailable: \(add.output)")

        guard case .resolved(let root) = SessionEnricher.projectRootResolution(at: worktree) else {
            return XCTFail("a linked worktree must resolve, not come back undetermined")
        }
        XCTAssertEqual(dirName(root), dirName(repo))
    }

    func testResolutionIsUndeterminedForACwdThatIsNotOnDisk() {
        // The transient case: nothing about this directory has been examined, so the
        // sweep must leave the row eligible instead of stamping an empty root.
        XCTAssertEqual(
            SessionEnricher.projectRootResolution(at: "/no/such/dir-\(UUID().uuidString)"),
            .undetermined
        )
        // An empty cwd is the opposite case: settled forever, so it is stampable.
        XCTAssertEqual(SessionEnricher.projectRootResolution(at: ""), .notAGitWorkingTree)
    }

    // MARK: - Sweep outcome

    /// A DB the enrichment writes can land in. Each test gets its own file.
    private func makeDatabase() throws -> DaemonDatabase {
        let path = NSTemporaryDirectory() + "enricher-\(UUID().uuidString).db"
        tempRoots.append(path)
        return try TestDaemonDatabase.makeSessionDatabase(path: path).db
    }

    private func seedSession(_ database: DaemonDatabase, id: String, cwd: String) throws {
        try database.ingestEvent(
            eventType: "SessionStart",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            hookData: ["session_id": id, "cwd": cwd, "model": "sonnet", "pid": 0]
        )
    }

    func testEnrichReportsAMissingCwdAsUnavailableRatherThanEmptyResults() throws {
        // The startup sweep stamps whatever `enrich` looked at, and the stamp is a
        // one-way door. A cwd that isn't on disk right now — unmounted volume,
        // worktree mid-move — is not the same as "there was nothing to find", so it
        // must not be reported as a completed sweep.
        let database = try makeDatabase()
        let missing = "/no/such/dir-\(UUID().uuidString)"
        try seedSession(database, id: "sess-missing", cwd: missing)

        let outcome = SessionEnricher.enrich(
            sessionId: "sess-missing", cwd: missing, projectRootVersion: 0,
            titleSource: .importedLines, database: database
        )
        XCTAssertEqual(outcome, .inputsUnavailable)
        // And it must not have recorded a resolved-but-empty root at the current
        // algorithm version, which would retire the row just as permanently.
        let stored = try XCTUnwrap(try database.fetchSessions().first { $0.sessionId == "sess-missing" })
        XCTAssertEqual(stored.projectRoot, "")
        XCTAssertTrue(
            try database
                .sessionsNeedingEnrichment(
                    currentProjectRootVersion: SessionEnricher.projectRootAlgoVersion,
                    currentEnrichmentVersion: SessionEnricher.enrichmentAlgoVersion
                )
                .contains { $0.sessionId == "sess-missing" },
            "an unreachable cwd must leave the row eligible for a later launch"
        )
    }

    func testEnrichReportsCompleteForAReachableCwdWithNothingToFind() throws {
        // The other half of the distinction: a real directory that simply isn't a git
        // working tree has been fully examined. That IS stampable — leaving it
        // eligible is what re-selected ~1,260 rows at every launch.
        let database = try makeDatabase()
        let plain = try makeTempDir("plain-reachable")
        try seedSession(database, id: "sess-plain", cwd: plain)

        let outcome = SessionEnricher.enrich(
            sessionId: "sess-plain", cwd: plain, projectRootVersion: 0,
            titleSource: .importedLines, database: database
        )
        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(
            try database.fetchSessions().first { $0.sessionId == "sess-plain" }?.projectRoot, "",
            "a non-git cwd resolves to an empty root — stamped at the current version"
        )
    }

    func testEnrichTreatsAnEmptyCwdAsCompleteBecauseNothingWillEverFillItIn() throws {
        // An empty cwd is permanent, not transient: no remount brings it back, so
        // holding the row open forever buys nothing.
        let database = try makeDatabase()
        try seedSession(database, id: "sess-nocwd", cwd: "")

        XCTAssertEqual(
            SessionEnricher.enrich(
                sessionId: "sess-nocwd", cwd: "", projectRootVersion: 0,
                titleSource: .importedLines, database: database
            ),
            .complete
        )
    }

    // MARK: - Last output

    /// Writes `records` as a transcript JSONL and returns its path.
    private func writeTranscript(_ records: [[String: Any]]) throws -> String {
        let dir = try makeTempDir("transcript")
        let path = dir + "/session.jsonl"
        var body = Data()
        for record in records {
            body.append(try JSONSerialization.data(withJSONObject: record))
            body.append(0x0A)
        }
        try body.write(to: URL(fileURLWithPath: path))
        return path
    }

    private func assistant(_ blocks: [[String: Any]], sidechain: Bool = false) -> [String: Any] {
        ["type": "assistant", "isSidechain": sidechain, "message": ["content": blocks]]
    }

    func testLastAssistantTextSkipsToolOnlyTurnsAndSubagentChatter() throws {
        let path = try writeTranscript([
            // The prompt that opened the turn; everything after it is this turn.
            ["type": "user", "message": ["content": "ok"]],
            assistant([["type": "text", "text": "All eighteen are fixed,\n\nand pushed."]]),
            // A turn that only calls a tool has nothing to say.
            assistant([["type": "tool_use", "name": "Bash", "input": [:] as [String: Any]]]),
            // A dispatched subagent speaking is not this session speaking.
            assistant([["type": "text", "text": "subagent report"]], sidechain: true)
        ])
        XCTAssertEqual(SessionEnricher.transcriptLastAssistantText(path: path),
                       "All eighteen are fixed,\n\nand pushed.")
    }

    /// The reply is markdown, and a list item or table row is only one because it
    /// starts a line. Collapsed onto one line, the Sessions row showed stray `-`
    /// and `|` it could no longer parse away.
    func testLastAssistantTextKeepsTheLineBreaksMarkdownNeeds() throws {
        let path = try writeTranscript([
            assistant([
                ["type": "text", "text": "\n**Shipped.** Both landed:\n- `c4c2cd2` fix\n- `a8c8122` docs\n"],
                ["type": "text", "text": "| File | What |\n|---|---|\n| `a.md` | notes |"]
            ])
        ])
        XCTAssertEqual(
            SessionEnricher.transcriptLastAssistantText(path: path),
            "**Shipped.** Both landed:\n- `c4c2cd2` fix\n- `a8c8122` docs\n"
                + "\n\n| File | What |\n|---|---|\n| `a.md` | notes |"
        )
    }

    /// The Sessions row shows what the agent last said *this turn*. Walking back past
    /// the user's prompt found the previous turn's reply and showed it under a
    /// question that had just been asked — stale text that looked live.
    func testLastAssistantTextStopsAtThePromptThatOpenedTheTurn() throws {
        let path = try writeTranscript([
            assistant([["type": "text", "text": "the previous turn's reply"]]),
            userText("and now do this"),
            // The new turn has only called a tool so far — it has said nothing yet.
            assistant([["type": "tool_use", "name": "Bash", "input": [:] as [String: Any]]])
        ])
        XCTAssertNil(SessionEnricher.transcriptLastAssistantText(path: path),
                     "nothing said this turn is nothing to show")
    }

    /// A tool *result* is also written as a `user` record, and it carries no text of
    /// its own — so it is part of the turn, not the boundary of one.
    func testATaskResultDoesNotEndTheTurn() throws {
        let path = try writeTranscript([
            userText("do the thing"),
            assistant([["type": "text", "text": "Done."]]),
            ["type": "user", "message": ["content": [
                ["type": "tool_result", "tool_use_id": "t1", "content": "exit 0"]
            ]]]
        ])
        XCTAssertEqual(SessionEnricher.transcriptLastAssistantText(path: path), "Done.")
    }

    /// The tail window is a starting size, not a budget. A single turn can exceed it
    /// (a pasted file, a long tool result), and a window that lands mid-record yielded
    /// no whole lines at all — so the row read as having nothing to say until the
    /// session ended. It grows until it finds one.
    func testATurnLargerThanTheTailWindowIsStillFound() throws {
        let filler = String(repeating: "x", count: 700_000)  // > the 512 KB first window
        let path = try writeTranscript([
            assistant([["type": "text", "text": "the answer"]]),
            ["type": "user", "message": [
                "content": [["type": "tool_result", "tool_use_id": "t1", "content": filler]]
            ]]
        ])
        XCTAssertEqual(SessionEnricher.transcriptLastAssistantText(path: path), "the answer")
    }

    // MARK: - Interrupted turns

    private func userText(_ text: String, sidechain: Bool = false) -> [String: Any] {
        [
            "type": "user", "isSidechain": sidechain, "timestamp": "2026-06-01T12:00:05.250Z",
            "message": ["content": [["type": "text", "text": text]]]
        ]
    }

    func testATranscriptEndingInTheInterruptMarkerWasInterrupted() throws {
        let path = try writeTranscript([
            assistant([["type": "tool_use", "name": "Bash", "input": [:] as [String: Any]]]),
            userText("[Request interrupted by user for tool use]"),
            // Bookkeeping records after the marker are not the conversation moving on.
            ["type": "file-history-snapshot", "snapshot": [:] as [String: Any]]
        ])
        XCTAssertEqual(SessionEnricher.transcriptInterruptTimestamp(path: path), "2026-06-01T12:00:05.250Z")
    }

    func testThePlainStringMarkerCountsToo() throws {
        let path = try writeTranscript([[
            "type": "user", "timestamp": "2026-06-01T12:00:07Z",
            "message": ["content": "[Request interrupted by user]"]
        ]])
        XCTAssertEqual(SessionEnricher.transcriptInterruptTimestamp(path: path), "2026-06-01T12:00:07Z")
    }

    /// After the marker the user typed again, or the agent spoke: the turn it cut
    /// short is history, and a subagent's records say nothing about the main turn.
    func testAConversationThatMovedOnWasNotInterrupted() throws {
        let resumed = try writeTranscript([
            userText("[Request interrupted by user for tool use]"),
            userText("try again")
        ])
        XCTAssertNil(SessionEnricher.transcriptInterruptTimestamp(path: resumed))

        let working = try writeTranscript([
            userText("[Request interrupted by user]"),
            assistant([["type": "tool_use", "name": "Read", "input": [:] as [String: Any]]]),
            userText("[Request interrupted by user]", sidechain: true)
        ])
        XCTAssertNil(SessionEnricher.transcriptInterruptTimestamp(path: working))
    }

    func testAMissingTranscriptWasNotInterrupted() {
        XCTAssertNil(SessionEnricher.transcriptInterruptTimestamp(path: "/nonexistent/\(UUID().uuidString).jsonl"))
    }

    func testRefreshLastOutputFillsTheRowTheStartupPassSelects() throws {
        // The startup pass exists for sessions whose last Stop the daemon never saw.
        // It must take such a row out of the selection, or it would re-read that
        // transcript on every launch for nothing.
        let database = try makeDatabase()
        try seedSession(database, id: "sess-idle", cwd: "")
        XCTAssertTrue(try database.sessionIdsMissingLastOutput().contains("sess-idle"))

        let path = try writeTranscript([assistant([["type": "text", "text": "Waiting on you."]])])
        SessionEnricher.refreshLastOutput(sessionId: "sess-idle", transcriptPath: path, database: database)

        XCTAssertEqual(try database.fetchSessions().first { $0.sessionId == "sess-idle" }?.lastOutput,
                       "Waiting on you.")
        XCTAssertFalse(try database.sessionIdsMissingLastOutput().contains("sess-idle"))
    }
}
