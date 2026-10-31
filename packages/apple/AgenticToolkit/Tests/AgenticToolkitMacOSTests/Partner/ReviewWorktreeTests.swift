import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class ReviewWorktreeTests: XCTestCase {

    private let fix = "partner/review-fixes"

    private struct Setup {
        let repo: PartnerGitFixture
        let worktree: URL
        let sut: ReviewWorktree
    }

    private func makeSetup() throws -> Setup {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let worktree = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerWorktree-\(UUID().uuidString)")
        return Setup(repo: repo, worktree: worktree, sut: ReviewWorktree(git: repo.review))
    }

    private func prepare(_ setup: Setup) async throws -> ReviewWorktree.Outcome {
        try await setup.sut.prepare(repo: setup.repo.directory, branch: "main", fixBranch: fix,
                                    worktree: setup.worktree)
    }

    private func head(of directory: URL, _ ref: String = "HEAD") throws -> String {
        try git(in: directory, "rev-parse", ref).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func currentBranch(of directory: URL) throws -> String {
        try git(in: directory, "branch", "--show-current").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Plain system git, independent of the code under test.
    @discardableResult
    private func git(in directory: URL, _ arguments: String...) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", directory.path] + arguments
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw GitClientError.commandFailed(verb: arguments.first ?? "", exitStatus: process.terminationStatus,
                                               standardError: "")
        }
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    private func commitInWorktree(_ setup: Setup, file: String, content: String) throws -> String {
        try content.write(to: setup.worktree.appendingPathComponent(file), atomically: true, encoding: .utf8)
        try git(in: setup.worktree, "add", file)
        try git(in: setup.worktree, "commit", "-m", "fix \(file)")
        return try head(of: setup.worktree)
    }

    func testCreatesWorktreeOnFixBranchAtTip() async throws {
        let setup = try makeSetup()
        let outcome = try await prepare(setup)
        XCTAssertEqual(outcome, .created)
        XCTAssertEqual(try head(of: setup.worktree), try head(of: setup.repo.directory, "main"))
        XCTAssertEqual(try currentBranch(of: setup.worktree), fix)
    }

    func testFastForwardsWhenMainAdvanced() async throws {
        let setup = try makeSetup()
        _ = try await prepare(setup)
        let tip = try setup.repo.commit(file: "b.txt", day: 2, message: "second")
        let outcome = try await prepare(setup)
        XCTAssertEqual(outcome, .fastForwarded)
        XCTAssertEqual(try head(of: setup.worktree), tip)
    }

    func testRebasesWaitingFixesOntoTip() async throws {
        let setup = try makeSetup()
        _ = try await prepare(setup)
        let fixCommit = try commitInWorktree(setup, file: "fix.txt", content: "fix\n")
        let tip = try setup.repo.commit(file: "b.txt", day: 2, message: "second")
        let outcome = try await prepare(setup)
        XCTAssertEqual(outcome, .rebased)
        XCTAssertNotEqual(try head(of: setup.worktree), fixCommit)
        XCTAssertEqual(try head(of: setup.worktree, "HEAD~1"), tip)
    }

    func testResetsAfterFixBranchMerged() async throws {
        let setup = try makeSetup()
        _ = try await prepare(setup)
        _ = try commitInWorktree(setup, file: "fix.txt", content: "fix\n")
        try setup.repo.commit(file: "b.txt", day: 2, message: "second")
        try setup.repo.merge(branch: fix, day: 3)
        let tip = try setup.repo.commit(file: "c.txt", day: 4, message: "third")
        let outcome = try await prepare(setup)
        XCTAssertEqual(outcome, .reset)
        XCTAssertEqual(try head(of: setup.worktree), tip)
    }

    func testRefusesDirtyWorktree() async throws {
        let setup = try makeSetup()
        _ = try await prepare(setup)
        let before = try head(of: setup.worktree)
        let junk = setup.worktree.appendingPathComponent("junk.txt")
        try "x".write(to: junk, atomically: true, encoding: .utf8)
        try setup.repo.commit(file: "b.txt", day: 2, message: "second")
        do {
            _ = try await prepare(setup)
            XCTFail("expected .dirty")
        } catch let failure as ReviewWorktree.Failure {
            XCTAssertEqual(failure, .dirty)
        }
        XCTAssertEqual(try head(of: setup.worktree), before)
        XCTAssertTrue(FileManager.default.fileExists(atPath: junk.path))
    }

    func testRebaseConflictAbortsAndThrows() async throws {
        let setup = try makeSetup()
        _ = try await prepare(setup)
        let fixCommit = try commitInWorktree(setup, file: "a.txt", content: "from the fix\n")
        try setup.repo.commit(file: "a.txt", day: 2, message: "second", content: "from main\n")
        do {
            _ = try await prepare(setup)
            XCTFail("expected a conflict")
        } catch ReviewWorktree.Failure.rebaseConflict(let message) {
            XCTAssertFalse(message.isEmpty)
        }
        XCTAssertEqual(try head(of: setup.worktree), fixCommit)
        XCTAssertFalse(try git(in: setup.worktree, "status").contains("rebase in progress"))
        XCTAssertTrue(try git(in: setup.worktree, "status", "--porcelain").isEmpty)
    }

    func testRecreatesMissingDirectoryKeepingBranch() async throws {
        let setup = try makeSetup()
        _ = try await prepare(setup)
        _ = try commitInWorktree(setup, file: "fix.txt", content: "fix\n")
        try FileManager.default.removeItem(at: setup.worktree)
        let tip = try setup.repo.commit(file: "b.txt", day: 2, message: "second")
        let outcome = try await prepare(setup)
        XCTAssertEqual(outcome, .rebased)
        XCTAssertEqual(try currentBranch(of: setup.worktree), fix)
        XCTAssertEqual(try head(of: setup.worktree, "HEAD~1"), tip)
        XCTAssertTrue(FileManager.default.fileExists(atPath: setup.worktree.appendingPathComponent("fix.txt").path))
    }
}
