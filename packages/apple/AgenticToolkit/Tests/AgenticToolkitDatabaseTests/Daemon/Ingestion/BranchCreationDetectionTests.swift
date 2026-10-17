import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

final class BranchCreationDetectionTests: XCTestCase {

    var database: DaemonDatabase!
    var tmpPath: String!

    override func setUpWithError() throws {
        (database, tmpPath) = try TestDaemonDatabase.makeSessionDatabase()
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    private func parse(_ command: String) -> String? {
        database.parseBashBranchCreation(command: command)
    }

    // MARK: - git branch <name>

    func testPlainBranch() {
        XCTAssertEqual(parse("git branch feat-plain"), "feat-plain")
    }

    func testBranchWithStartPoint() {
        XCTAssertEqual(parse("git branch feat-sp origin/main"), "feat-sp")
    }

    func testBranchChainedAfterAnd() {
        XCTAssertEqual(parse("cd /tmp && git branch feat-chained"), "feat-chained")
    }

    func testBranchChainedAfterSemicolon() {
        XCTAssertEqual(parse("cd /tmp; git branch feat-semi"), "feat-semi")
    }

    func testBranchChainedAfterPipe() {
        XCTAssertEqual(parse("true | git branch feat-pipe"), "feat-pipe")
    }

    func testBranchInsideCommandSubstitution() {
        XCTAssertEqual(parse("echo $(git branch feat-sub)"), "feat-sub")
    }

    func testBranchInsideBackticks() {
        XCTAssertEqual(parse("echo `git branch feat-btick`"), "feat-btick")
    }

    func testBranchInsideBraceGroup() {
        XCTAssertEqual(parse("{ git branch feat-brace; }"), "feat-brace")
    }

    func testBranchAfterNewline() {
        XCTAssertEqual(parse("cd /tmp\ngit branch feat-nl"), "feat-nl")
    }

    // MARK: - git <subcommand> creation forms

    func testCheckoutB() {
        XCTAssertEqual(parse("git checkout -b feat-co"), "feat-co")
    }

    func testCheckoutBWithBase() {
        XCTAssertEqual(parse("git checkout -b feat-co-base origin/main"), "feat-co-base")
    }

    func testSwitchC() {
        XCTAssertEqual(parse("git switch -c feat-sw"), "feat-sw")
    }

    func testWorktreeAddBEarly() {
        XCTAssertEqual(
            parse("git worktree add -b feat-wt /tmp/wt"), "feat-wt"
        )
    }

    func testWorktreeAddBLate() {
        XCTAssertEqual(
            parse("git worktree add /tmp/wt -b feat-wt-late"), "feat-wt-late"
        )
    }

    // MARK: - git global options (formerly false negatives)

    func testGitDashCThenBranch() {
        XCTAssertEqual(
            parse("git -C /tmp branch feat-dashC"), "feat-dashC"
        )
    }

    func testGitDashCConfigThenBranch() {
        XCTAssertEqual(
            parse("git -c user.email=a@b branch feat-conf"), "feat-conf"
        )
    }

    func testGitDashCAndCheckoutB() {
        XCTAssertEqual(
            parse("git -C /tmp checkout -b feat-cb"), "feat-cb"
        )
    }

    // MARK: - Negative cases (formerly false positives)

    func testEchoMentioningGitIsIgnored() {
        // Previously matched because the regex looked for "git branch X"
        // anywhere in the string. Now skipped because `git` is not the
        // invoked command on this segment.
        XCTAssertNil(parse("echo git branch foo"))
    }

    func testQuotedGitInsideEchoIsIgnored() {
        XCTAssertNil(parse(#"echo "run git branch foo""#))
    }

    // MARK: - Negative cases (destructive/listing branch forms)

    func testBranchDeleteLower() {
        XCTAssertNil(parse("git branch -d feat-del"))
    }

    func testBranchDeleteUpper() {
        XCTAssertNil(parse("git branch -D feat-del"))
    }

    func testBranchMove() {
        XCTAssertNil(parse("git branch -m feat-old feat-new"))
    }

    func testBranchList() {
        XCTAssertNil(parse("git branch --list feat-*"))
    }

    func testBranchWithNoArgs() {
        XCTAssertNil(parse("git branch"))
    }

    // MARK: - Non-git commands

    func testLsIsNotGit() {
        XCTAssertNil(parse("ls -la"))
    }

    func testEmptyCommand() {
        XCTAssertNil(parse(""))
    }
}
