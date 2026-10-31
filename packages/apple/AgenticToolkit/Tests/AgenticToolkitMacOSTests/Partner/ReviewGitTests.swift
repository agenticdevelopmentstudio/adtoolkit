import XCTest
@testable import AgenticToolkitMacOS

final class ReviewGitTests: XCTestCase {
    private let git = ReviewGit()

    func testDefaultBranchAndLocalBranches() throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        XCTAssertEqual(try git.defaultBranch(in: repo.directory), "main")
        XCTAssertEqual(try git.localBranches(in: repo.directory), ["main"])
    }

    func testIsAncestor() throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        XCTAssertTrue(try git.isAncestor(second, of: "main", in: repo.directory))
        try repo.git("branch", "copy")
        try repo.git("branch", "-f", "copy", "HEAD~1")
        XCTAssertFalse(try git.isAncestor(second, of: "copy", in: repo.directory))
    }

    func testParentAndRootParent() throws {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        XCTAssertEqual(try git.parent(of: second, in: repo.directory), first)
        XCTAssertEqual(try git.parent(of: first, in: repo.directory), ReviewGit.emptyTree)
    }

    func testChangedFiles() throws {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        XCTAssertEqual(try git.changedFiles(parent: first, sha: second, in: repo.directory), ["a.txt"])
    }

    func testSupersedingCommitsAndTipDiffWhenLaterCommitTouchesFile() throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        let third = try repo.commit(file: "a.txt", day: 3, message: "third")
        let later = try git.supersedingCommits(after: second, on: "main", files: ["a.txt"], in: repo.directory)
        XCTAssertEqual(later, [third])
        XCTAssertFalse(try git.tipDiff(from: second, to: "main", files: ["a.txt"], in: repo.directory).isEmpty)
        let cut = try git.tipDiff(from: second, to: "main", files: ["a.txt"], in: repo.directory, maxBytes: 10)
        XCTAssertEqual(cut.utf8.count, 10)
    }

    func testSupersedingCommitsEmptyWhenLaterCommitTouchesOtherFile() throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        try repo.commit(file: "b.txt", day: 3, message: "third")
        XCTAssertEqual(try git.supersedingCommits(after: second, on: "main", files: ["a.txt"], in: repo.directory), [])
        XCTAssertEqual(try git.tipDiff(from: second, to: "main", files: ["a.txt"], in: repo.directory), "")
    }

    func testIsCleanAndFailureThrowsGitError() throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        XCTAssertTrue(try git.isClean(worktree: repo.directory))
        try "x".write(to: repo.directory.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)
        XCTAssertFalse(try git.isClean(worktree: repo.directory))
        XCTAssertThrowsError(try git.run(["rev-parse", "--verify", "nope"], in: repo.directory)) { error in
            XCTAssertNotEqual((error as? GitError)?.status, 0)
            XCTAssertNotNil(error as? GitError)
        }
    }

    func testLargeOutputDoesNotDeadlock() throws {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "big",
                                 content: String(repeating: "line of text\n", count: 100_000))
        let diff = try git.run(["diff", first, second], in: repo.directory)
        XCTAssertGreaterThan(diff.utf8.count, 65_536)
    }
}
