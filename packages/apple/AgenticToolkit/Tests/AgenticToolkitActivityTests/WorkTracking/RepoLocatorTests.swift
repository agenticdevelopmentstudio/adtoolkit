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
    func testLinkedWorktreeRootsAtMainRepoWithOwnBranch() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: /src/app/.git/worktrees/b\n",
            "/src/app/.git/worktrees/b/commondir": "../..\n",
            "/src/app/.git/worktrees/b/HEAD": "ref: refs/heads/b\n"]))
        XCTAssertEqual(locator.locate("/wt/b/x"), RepoLocation(root: "/src/app", branch: "b"))
    }
    func testRelativeGitdirAndAbsoluteCommondir() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: ../meta/worktrees/b\n",
            "/wt/meta/worktrees/b/commondir": "/wt/meta\n",
            "/wt/meta/worktrees/b/HEAD": "ref: refs/heads/rel\n"]))
        XCTAssertEqual(locator.locate("/wt/b"), RepoLocation(root: "/wt", branch: "rel"))
    }
    /// Review F12: a submodule bills to its superproject, as `GitProjectRoot`
    /// resolves it, not to a directory inside the superproject's `.git`.
    func testSubmoduleResolvesToItsSuperproject() {
        let locator = RepoLocator(fileSystem: fs(dirs: ["/super/.git"], files: [
            "/super/.git/HEAD": "ref: refs/heads/main\n",
            "/super/sub/.git": "gitdir: ../.git/modules/sub\n",
            "/super/.git/modules/sub/HEAD": "ref: refs/heads/dev\n"]))
        XCTAssertEqual(locator.locate("/super/sub/a.swift"), RepoLocation(root: "/super", branch: "main"))
    }
    func testSubmoduleOfALinkedWorktreeResolvesToTheMainRepo() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: /src/app/.git/worktrees/b\n",
            "/src/app/.git/worktrees/b/commondir": "../..\n",
            "/src/app/.git/worktrees/b/HEAD": "ref: refs/heads/b\n",
            "/wt/b/external/kit/.git": "gitdir: ../../../../src/app/.git/worktrees/b/modules/external/kit\n",
            "/src/app/.git/worktrees/b/modules/external/kit/HEAD": "ref: refs/heads/kit-branch\n"]))
        XCTAssertEqual(locator.locate("/wt/b/external/kit/Sources/a.swift"),
                       RepoLocation(root: "/src/app", branch: "b"))
    }
    func testNestedSubmodulesClimbToTheTopmostSuperproject() {
        let locator = RepoLocator(fileSystem: fs(dirs: ["/super/.git"], files: [
            "/super/.git/HEAD": "ref: refs/heads/main\n",
            "/super/a/.git": "gitdir: ../.git/modules/a\n",
            "/super/.git/modules/a/HEAD": "ref: refs/heads/x\n",
            "/super/a/b/.git": "gitdir: ../../.git/modules/a/modules/b\n",
            "/super/.git/modules/a/modules/b/HEAD": "ref: refs/heads/y\n"]))
        XCTAssertEqual(locator.locate("/super/a/b/f"), RepoLocation(root: "/super", branch: "main"))
    }
    func testRealGitWorktreeAndSubmoduleMatchCommonDir() throws {
        let base = (NSTemporaryDirectory() as NSString).appendingPathComponent("rl-\(UUID().uuidString)")
        let canonical = URL(fileURLWithPath: base).resolvingSymlinksInPath().path
        try FileManager.default.createDirectory(atPath: canonical, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: canonical) }
        func git(_ dir: String, _ args: String...) throws -> String {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = ["git", "-C", dir, "-c", "user.name=t", "-c", "user.email=t@t",
                           "-c", "protocol.file.allow=always"] + args
            let out = Pipe()
            p.standardOutput = out; p.standardError = Pipe()
            try p.run()
            let data = out.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            guard p.terminationStatus == 0 else { throw XCTSkip("git \(args) failed") }
            return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let main = canonical + "/main", wt = canonical + "/wt", subSrc = canonical + "/subsrc"
        try FileManager.default.createDirectory(atPath: main, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: subSrc, withIntermediateDirectories: true)
        _ = try git(main, "init", "-q", "-b", "main")
        _ = try git(main, "commit", "-q", "--allow-empty", "-m", "i")
        _ = try git(subSrc, "init", "-q", "-b", "main")
        _ = try git(subSrc, "commit", "-q", "--allow-empty", "-m", "i")
        _ = try git(main, "worktree", "add", "-q", "-b", "feat", wt)
        _ = try git(main, "submodule", "add", "-q", subSrc, "sub")
        for dir in [main, wt, main + "/sub"] {
            // A submodule is billed to its superproject, so its expected root
            // is the superproject's common-dir parent (what GitProjectRoot gives).
            let owner = dir == main + "/sub" ? main : dir
            let common = try git(owner, "rev-parse", "--path-format=absolute", "--git-common-dir")
            let expected = (common as NSString).deletingLastPathComponent
            // git reports /private/var/...; Foundation's symlink resolution drops /private.
            func bare(_ p: String?) -> String? { p.map { $0.hasPrefix("/private/") ? String($0.dropFirst(8)) : $0 } }
            XCTAssertEqual(bare(RepoLocator().locate(dir)?.root), bare(expected), dir)
        }
        XCTAssertEqual(RepoLocator().locate(wt)?.branch, "feat")
    }
    func testDetachedHeadHasEmptyBranch() {
        let locator = RepoLocator(fileSystem: fs(dirs: ["/r/.git"], files: ["/r/.git/HEAD": "0123abcd\n"]))
        XCTAssertEqual(locator.locate("/r/f"), RepoLocation(root: "/r", branch: ""))
    }
    func testDanglingWorktreeRootsAtItsOwnDirectory() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: /super/.git/worktrees/gone\n"]))
        XCTAssertEqual(locator.locate("/wt/b/x"), RepoLocation(root: "/wt/b", branch: ""))
    }
    func testEmptyGitFile() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: ["/wt/b/.git": ""]))
        XCTAssertEqual(locator.locate("/wt/b"), RepoLocation(root: "/wt/b", branch: ""))
    }
    func testGitFileWithoutGitdirPrefix() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: ["/wt/b/.git": "/somewhere/else\n"]))
        XCTAssertEqual(locator.locate("/wt/b"), RepoLocation(root: "/wt/b", branch: ""))
    }
    func testCRLFInGitFileCommondirAndHead() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: /src/app/.git/worktrees/b\r\n",
            "/src/app/.git/worktrees/b/commondir": "../..\r\n",
            "/src/app/.git/worktrees/b/HEAD": "ref: refs/heads/crlf\r\n"]))
        XCTAssertEqual(locator.locate("/wt/b"), RepoLocation(root: "/src/app", branch: "crlf"))
    }
    func testBareSHAHeadHasEmptyBranch() {
        let sha = "0123456789abcdef0123456789abcdef01234567"
        let locator = RepoLocator(fileSystem: fs(dirs: ["/r/.git"], files: ["/r/.git/HEAD": sha + "\n"]))
        XCTAssertEqual(locator.locate("/r"), RepoLocation(root: "/r", branch: ""))
    }
    func testEmptyHeadWithCommondirRootsAtCommonRepo() {
        let locator = RepoLocator(fileSystem: fs(dirs: [], files: [
            "/wt/b/.git": "gitdir: /src/app/.git/worktrees/b\n",
            "/src/app/.git/worktrees/b/commondir": "../..\n",
            "/src/app/.git/worktrees/b/HEAD": ""]))
        XCTAssertEqual(locator.locate("/wt/b"), RepoLocation(root: "/src/app", branch: ""))
    }
    func testLiveReadOfEmptyFileIsEmptyNotNil() throws {
        let path = NSTemporaryDirectory() + "empty-\(UUID().uuidString)"
        try "".write(toFile: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: path) }
        XCTAssertEqual(RepoLocator.FileSystem.live.read(path), "")
    }
    func testLiveReadIsCapped() throws {
        let path = NSTemporaryDirectory() + "cap-\(UUID().uuidString)"
        try String(repeating: "a", count: 10_000).write(toFile: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: path) }
        XCTAssertEqual(RepoLocator.FileSystem.live.read(path)?.count, RepoLocator.FileSystem.readLimit)
    }
    func testNoRepoIsNil() {
        XCTAssertNil(RepoLocator(fileSystem: fs(dirs: [], files: [:])).locate("/tmp/x"))
    }
    func testLiveFileSystemFindsThisRepo() {
        XCTAssertNotNil(RepoLocator().locate(#filePath))
    }
}
