import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class ReviewGitTests: XCTestCase {

    func testDefaultBranchAndLocalBranches() async throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let defaultBranch = try await repo.review.defaultBranch(in: repo.directory)
        let branches = try await repo.review.localBranches(in: repo.directory)
        XCTAssertEqual(defaultBranch, "main")
        XCTAssertEqual(branches, ["main"])
    }

    func testIsAncestor() async throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        let onMain = try await repo.review.isAncestor(second, of: "main", in: repo.directory)
        XCTAssertTrue(onMain)
        try repo.git("branch", "copy")
        try repo.git("branch", "-f", "copy", "HEAD~1")
        let onCopy = try await repo.review.isAncestor(second, of: "copy", in: repo.directory)
        XCTAssertFalse(onCopy)
    }

    func testParentAndRootParent() async throws {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        let parentOfSecond = try await repo.review.parent(of: second, in: repo.directory)
        let parentOfFirst = try await repo.review.parent(of: first, in: repo.directory)
        XCTAssertEqual(parentOfSecond, first)
        XCTAssertEqual(parentOfFirst, ReviewGit.emptyTree)
    }

    func testChangedFiles() async throws {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        let files = try await repo.review.changedFiles(parent: first, sha: second, in: repo.directory)
        XCTAssertEqual(files, ["a.txt"])
    }

    func testSupersedingCommitsAndTipDiffWhenLaterCommitTouchesFile() async throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        let third = try repo.commit(file: "a.txt", day: 3, message: "third")
        let later = try await repo.review.supersedingCommits(
            after: second, on: "main", files: ["a.txt"], in: repo.directory)
        XCTAssertEqual(later, [third])
        let diff = try await repo.review.tipDiff(from: second, to: "main", files: ["a.txt"], in: repo.directory)
        XCTAssertFalse(diff.isEmpty)
        let cut = try await repo.review.tipDiff(
            from: second, to: "main", files: ["a.txt"], in: repo.directory, maxBytes: 10)
        XCTAssertEqual(cut.utf8.count, 10)
    }

    func testSupersedingCommitsEmptyWhenLaterCommitTouchesOtherFile() async throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "second")
        try repo.commit(file: "b.txt", day: 3, message: "third")
        let later = try await repo.review.supersedingCommits(
            after: second, on: "main", files: ["a.txt"], in: repo.directory)
        XCTAssertEqual(later, [])
        let diff = try await repo.review.tipDiff(from: second, to: "main", files: ["a.txt"], in: repo.directory)
        XCTAssertEqual(diff, "")
    }

    func testIsCleanAndFailureThrowsCommandFailed() async throws {
        let repo = try PartnerGitFixture()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let clean = try await repo.review.isClean(worktree: repo.directory)
        XCTAssertTrue(clean)
        try "x".write(to: repo.directory.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)
        let dirty = try await repo.review.isClean(worktree: repo.directory)
        XCTAssertFalse(dirty)
        do {
            _ = try await repo.review.run(["rev-parse", "--verify", "nope"], in: repo.directory)
            XCTFail("expected a failure")
        } catch let error as GitClientError {
            guard case let .commandFailed(verb, status, _) = error else { return XCTFail("unexpected \(error)") }
            XCTAssertEqual(verb, "rev-parse")
            XCTAssertNotEqual(status, 0)
        }
    }

    func testLargeOutputDoesNotDeadlock() async throws {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        let second = try repo.commit(file: "a.txt", day: 2, message: "big",
                                     content: String(repeating: "line of text\n", count: 100_000))
        let diff = try await repo.review.run(["diff", first, second], in: repo.directory)
        XCTAssertGreaterThan(diff.utf8.count, 65_536)
    }
}
