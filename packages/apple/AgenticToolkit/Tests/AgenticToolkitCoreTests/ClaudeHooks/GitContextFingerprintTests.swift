@testable import AgenticToolkitCore
import XCTest
import Foundation

/// Unit tests for `GitContextFingerprint` — the per-render sample of the git
/// state Claude Code renders into its system prompt.
///
/// The point of the fingerprint is a *diff across two renders*, so every test
/// here asserts on change: what must move when the working tree moves, and what
/// must stay put when it doesn't. A test that only checked "the field is
/// present" would pass on a fingerprint that returned a constant.
final class GitContextFingerprintTests: XCTestCase {

    private var repo: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Neuter the machine's git config for this process, fixture and sample
        // alike. `ReadOnlyGit` inherits this process's environment, so these
        // two variables are the only way to pin what the code under test sees.
        // Without them the whole suite is at the mercy of the developer's
        // `~/.gitconfig`: `status.showUntrackedFiles=no` makes an untracked file
        // invisible (the assertion that the status hash *moves* then fails on a
        // correct fingerprint), `core.excludesFile` can ignore `scratch.txt`
        // outright, and `commit.gpgsign=true` turns every fixture commit into a
        // keychain prompt.
        setenv("GIT_CONFIG_GLOBAL", "/dev/null", 1)
        setenv("GIT_CONFIG_SYSTEM", "/dev/null", 1)
        repo = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gitctx-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        XCTAssertEqual(git("init", "-b", "fingerprint-branch"), 0)
        try write("README.md", "one\n")
        XCTAssertEqual(git("add", "README.md"), 0)
        XCTAssertEqual(commit("first"), 0)
    }

    override func tearDownWithError() throws {
        unsetenv("GIT_CONFIG_GLOBAL")
        unsetenv("GIT_CONFIG_SYSTEM")
        if let repo { try? FileManager.default.removeItem(at: repo) }
        try super.tearDownWithError()
    }

    // MARK: - sample

    func testSampleReturnsNilOutsideAGitRepository() throws {
        let plain = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("plain-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: plain) }

        // No git block in the system prompt to fingerprint ⇒ no fields, rather
        // than a row of zeros that would read as "clean tree".
        XCTAssertNil(GitContextFingerprint.sample(directory: plain.path))
    }

    func testSampleReportsTheBranchAndACleanTree() throws {
        let sample = try XCTUnwrap(GitContextFingerprint.sample(directory: repo.path))
        XCTAssertEqual(sample["branch"] as? String, "fingerprint-branch")
        XCTAssertEqual(sample["status_char_count"] as? Int, 0)
        XCTAssertEqual(sample["status_entry_count"] as? Int, 0)
        // SHA256 of the empty string — a clean tree hashes to a known constant,
        // which is what makes "did the status change" a string comparison.
        XCTAssertEqual(sample["status_sha256"] as? String,
                       "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertGreaterThan(try XCTUnwrap(sample["recent_commits_char_count"] as? Int), 0)
        XCTAssertNotNil(sample["sampled_at"] as? String)
    }

    func testAnUntrackedFileMovesTheStatusHashButNotTheCommitHash() throws {
        let before = try XCTUnwrap(GitContextFingerprint.sample(directory: repo.path))
        try write("scratch.txt", "hello\n")
        let after = try XCTUnwrap(GitContextFingerprint.sample(directory: repo.path))

        XCTAssertNotEqual(after["status_sha256"] as? String, before["status_sha256"] as? String)
        XCTAssertEqual(after["status_entry_count"] as? Int, 1)
        XCTAssertGreaterThan(try XCTUnwrap(after["status_char_count"] as? Int), 0)
        // The commits didn't move, so their fingerprint must not either —
        // otherwise every diff would implicate the commit list.
        XCTAssertEqual(after["recent_commits_sha256"] as? String,
                       before["recent_commits_sha256"] as? String)
    }

    func testANewCommitMovesTheCommitHashButNotTheStatusHash() throws {
        let before = try XCTUnwrap(GitContextFingerprint.sample(directory: repo.path))
        try write("second.md", "two\n")
        XCTAssertEqual(git("add", "second.md"), 0)
        XCTAssertEqual(commit("second"), 0)
        let after = try XCTUnwrap(GitContextFingerprint.sample(directory: repo.path))

        XCTAssertNotEqual(after["recent_commits_sha256"] as? String,
                          before["recent_commits_sha256"] as? String)
        XCTAssertEqual(after["status_sha256"] as? String, before["status_sha256"] as? String,
                       "committing leaves the tree clean, so the status hash must not move")
    }

    func testTheStatusHashCountsPorcelainsLeadingStatusColumn() throws {
        // Porcelain's `XY` prefix is two columns wide, so an unstaged-only
        // change on the alphabetically-first path emits a *leading space*:
        // " M README.md\n" is 13 characters. Trimming it (which is what
        // `ReadOnlyGit.git` does, and what `rawGit` exists to avoid) yields
        // 11 and a different digest for a purely cosmetic reason.
        try write("README.md", "one\ntwo\n")
        let sample = try XCTUnwrap(GitContextFingerprint.sample(directory: repo.path))
        XCTAssertEqual(sample["status_char_count"] as? Int, 13,
                       "the leading status column must survive into the hash")
        XCTAssertEqual(sample["status_entry_count"] as? Int, 1)
    }

    func testRawGitKeepsWhitespaceThatGitTrimsAway() throws {
        try write("README.md", "one\ntwo\n")
        let args = ["-C", repo.path, "status", "--porcelain", "-unormal", "--no-renames"]
        XCTAssertEqual(ReadOnlyGit.rawGit(args), " M README.md\n")
        XCTAssertEqual(ReadOnlyGit.git(args), "M README.md",
                       "the trimming wrapper is still the default for displayed values")
    }

    // MARK: - enriched

    func testEnrichedNestsTheFingerprintAndKeepsEveryOriginalKey() throws {
        let payload = try JSONSerialization.data(withJSONObject: [
            "cwd": repo.path,
            "session_id": "abc",
            "model": ["id": "claude-opus-5"]
        ])
        let out = GitContextFingerprint.enriched(payload: payload)
        let decoded = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: out) as? [String: Any])

        XCTAssertEqual(decoded["session_id"] as? String, "abc")
        XCTAssertEqual((decoded["model"] as? [String: Any])?["id"] as? String, "claude-opus-5")
        let git = try XCTUnwrap(decoded[GitContextFingerprint.payloadKey] as? [String: Any])
        XCTAssertEqual(git["branch"] as? String, "fingerprint-branch")
    }

    func testEnrichedFallsBackToTheWorkspaceCurrentDir() throws {
        // Older payload shapes carry the directory under `workspace`, not at the
        // top level; the sample must still land in the right repository.
        let payload = try JSONSerialization.data(withJSONObject: [
            "workspace": ["current_dir": repo.path]
        ])
        let decoded = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: GitContextFingerprint.enriched(payload: payload))
                as? [String: Any])
        let git = try XCTUnwrap(decoded[GitContextFingerprint.payloadKey] as? [String: Any])
        XCTAssertEqual(git["branch"] as? String, "fingerprint-branch")
    }

    func testEnrichedPreservesTheOriginalBytesOfEveryValue() throws {
        // The splice exists because a decode/re-encode round trip collapses a
        // JSON `1.0` to `1` — the NSNumber arrives as objCType 'd' and leaves as
        // 'q'. `DynamicSchema.affinity` types a column from the first value it
        // sees, so one perfectly-warm sample would declare `hit_ratio` INTEGER
        // forever and truncate every later `0.973…` to 0.
        let payload = Data(#"{"cwd":"\#(repo.path)","prompt_cache":{"hit_ratio":1.0}}"#.utf8)
        let out = GitContextFingerprint.enriched(payload: payload)
        let text = try XCTUnwrap(String(data: out, encoding: .utf8))

        XCTAssertTrue(text.contains(#""hit_ratio":1.0"#),
                      "a re-encode collapsed the float; got \(text)")
        let decoded = try XCTUnwrap(try JSONSerialization.jsonObject(with: out) as? [String: Any])
        XCTAssertNotNil(decoded[GitContextFingerprint.payloadKey])
    }

    func testEnrichedNamespacesTheFingerprintSoTheDaemonCanStripIt() throws {
        // The daemon's `claude_versions` audit records Anthropic's payload
        // schema, first-seen-wins, and strips exactly the `stenographer_`
        // namespace before doing it. A key outside that namespace would be
        // recorded as Anthropic's forever, with no way to clean it after.
        XCTAssertTrue(GitContextFingerprint.payloadKey.hasPrefix("stenographer_"))
    }

    func testEnrichedReturnsThePayloadUnchangedWhenItIsNotJSONObject() {
        // Enrichment is best-effort: a payload we can't parse still has to reach
        // the daemon exactly as Claude Code sent it.
        let garbage = Data("not json at all".utf8)
        XCTAssertEqual(GitContextFingerprint.enriched(payload: garbage), garbage)
    }

    func testEnrichedReturnsThePayloadUnchangedOutsideAGitRepository() throws {
        let plain = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("plain-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: plain) }

        let payload = try JSONSerialization.data(withJSONObject: ["cwd": plain.path])
        let decoded = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: GitContextFingerprint.enriched(payload: payload))
                as? [String: Any])
        XCTAssertNil(decoded[GitContextFingerprint.payloadKey])
    }

    // MARK: - Helpers

    private func write(_ name: String, _ contents: String) throws {
        try contents.write(to: repo.appendingPathComponent(name),
                           atomically: true, encoding: .utf8)
    }

    /// Run `git` in the fixture repo, returning its exit status.
    @discardableResult
    private func git(_ args: String...) -> Int32 { run(args) }

    /// Commit with an identity and signing pinned on the command line, so the
    /// test doesn't depend on (or disturb) the machine's git config.
    @discardableResult
    private func commit(_ message: String) -> Int32 {
        run(["-c", "user.email=test@example.com",
             "-c", "user.name=Test",
             "-c", "commit.gpgsign=false",
             "commit", "-m", message])
    }

    /// Spawn `git` in the fixture repo under the same conditions
    /// ``ReadOnlyGit/rawGit(_:)`` spawns it: the repaired PATH (so `git`
    /// resolves under Xcode's minimal environment, not just an interactive
    /// shell's) and a 5-second watchdog (so a fixture command that hangs — an
    /// unexpected credential or editor prompt on a closed stdin — fails the test
    /// in five seconds instead of hanging the whole suite until the scheme's
    /// timeout).
    private func run(_ args: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "-C", repo.path] + args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = ReadOnlyGit.repairedPath(env["PATH"])
        process.environment = env
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return -1
        }
        let watchdog = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: watchdog)
        process.waitUntilExit()
        watchdog.cancel()
        return process.terminationStatus
    }
}
