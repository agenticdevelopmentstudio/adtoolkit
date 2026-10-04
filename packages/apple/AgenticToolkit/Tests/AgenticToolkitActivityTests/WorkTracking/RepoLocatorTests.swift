import XCTest
@testable import AgenticToolkitActivity

final class RepoLocatorTests: XCTestCase {
    private func fs(dirs: Set<String>, files: [String: String]) -> RepoLocator.FileSystem {
        RepoLocator.FileSystem(
            kind: { dirs.contains($0) ? .directory : (files[$0] != nil ? .file : .missing) },
            read: { files[$0] })
    }
    func testFindsRepoAndBranch() {
        let locator = RepoLocator(fileSystem: fs(dirs: ["/src/app/.git"],
                                                 files: ["/src/app/.git/HEAD": "ref: refs/heads/main\n"]))
        XCTAssertEqual(locator.locate("/src/app/Sources/a.swift"), RepoLocation(root: "/src/app", branch: "main"))
    }
    func testInnermostGitWins() {
        let locator = RepoLocator(fileSystem: fs(
            dirs: ["/src/app/.git", "/src/app/external/kit/.git"],
            files: ["/src/app/.git/HEAD": "ref: refs/heads/main\n",
                    "/src/app/external/kit/.git/HEAD": "ref: refs/heads/feature/x\n"]))
        XCTAssertEqual(locator.locate("/src/app/external/kit/a.swift"),
                       RepoLocation(root: "/src/app/external/kit", branch: "feature/x"))
    }
    func testWorktreeGitFile() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: /src/app/.git/worktrees/b\n",
            "/src/app/.git/worktrees/b/HEAD": "ref: refs/heads/b\n"]))
        XCTAssertEqual(locator.locate("/wt/b/x"), RepoLocation(root: "/wt/b", branch: "b"))
    }
    func testRelativeGitdirResolvesAgainstRoot() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: ../meta\n",
            "/wt/meta/HEAD": "ref: refs/heads/rel\n"]))
        XCTAssertEqual(locator.locate("/wt/b"), RepoLocation(root: "/wt/b", branch: "rel"))
    }
    func testDetachedHeadHasEmptyBranch() {
        let locator = RepoLocator(fileSystem: fs(dirs: ["/r/.git"], files: ["/r/.git/HEAD": "0123abcd\n"]))
        XCTAssertEqual(locator.locate("/r/f"), RepoLocation(root: "/r", branch: ""))
    }
    func testNoRepoIsNil() {
        XCTAssertNil(RepoLocator(fileSystem: fs(dirs: [], files: [:])).locate("/tmp/x"))
    }
    func testLiveFileSystemFindsThisRepo() {
        XCTAssertNotNil(RepoLocator().locate(#filePath))
    }
}
