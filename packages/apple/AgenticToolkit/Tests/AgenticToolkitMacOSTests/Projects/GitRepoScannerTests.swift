import XCTest
import AgenticToolkitMacOS

/// What counts as a project on disk. The rules are shared with `proj projects`,
/// so the two tools agree about what the user's projects are.
final class GitRepoScannerTests: XCTestCase {

    private var root: URL!

    override func setUp() async throws {
        try await super.setUp()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("scanner-test-\(UUID().uuidString)")
            .standardizedFileURL
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: root)
        try await super.tearDown()
    }

    func testAPlainRepositoryIsFoundWithItsOriginRemote() throws {
        try makeRepo("dev/alpha", remote: "git@example.com:someone/alpha.git")

        let found = GitRepoScanner(roots: [root]).scan()

        XCTAssertEqual(paths(found), [path("dev/alpha")])
        XCTAssertEqual(found.first?.remote, "git@example.com:someone/alpha.git")
        XCTAssertEqual(found.first?.leafName, "alpha")
    }

    /// A repository is a leaf: the walk stops there. That is also what keeps
    /// submodules and nested checkouts out of the list — they live inside a
    /// repository.
    func testARepositoryInsideARepositoryIsNotAProject() throws {
        try makeRepo("dev/alpha")
        try makeRepo("dev/alpha/external/toolkit")

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()), [path("dev/alpha")])
    }

    /// An absorbed submodule or a linked worktree has a `.git` *file* rather
    /// than a directory. Neither is a project in its own right.
    func testADirectoryWhoseGitIsAFileIsSkippedEntirely() throws {
        let worktree = root.appendingPathComponent("dev/worktree", isDirectory: true)
        try FileManager.default.createDirectory(at: worktree, withIntermediateDirectories: true)
        try "gitdir: /somewhere/else/.git/worktrees/x\n"
            .write(to: worktree.appendingPathComponent(".git"), atomically: true, encoding: .utf8)
        try makeRepo("dev/alpha")

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()), [path("dev/alpha")])
    }

    /// A tool that installs hooks into a plain folder leaves a `.git` behind
    /// with nothing in it but `hooks/`. Git would not open it, so neither does
    /// this: calling it a project invents one.
    func testAGitFolderThatGitWouldNotOpenIsNotAProject() throws {
        try makeHookOnlyGitFolder("dev/container")

        XCTAssertTrue(GitRepoScanner(roots: [root]).scan().isEmpty)
    }

    /// And, because it is not a repository, it does not own its subtree — the
    /// real repositories inside it are exactly what the user was looking for.
    func testRepositoriesUnderSuchAFolderAreStillFound() throws {
        try makeHookOnlyGitFolder("dev/container")
        try makeRepo("dev/container/alpha")
        try makeRepo("dev/container/beta")

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()),
                       [path("dev/container/alpha"), path("dev/container/beta")])
    }

    func testHiddenDirectoriesAreNeverDescendedInto() throws {
        try makeRepo(".claude/worktrees/feature")
        try makeRepo("dev/alpha")

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()), [path("dev/alpha")])
    }

    /// Off, a dot-directory is just another directory.
    func testHiddenDirectoriesAreScannedWhenTheOptionIsOff() throws {
        try makeRepo(".hidden/feature")
        try makeRepo("dev/alpha")

        let scanner = GitRepoScanner(roots: [root], skippedDirectories: [], skipsHiddenDirectories: false)

        XCTAssertEqual(paths(scanner.scan()), [path(".hidden/feature"), path("dev/alpha")])
    }

    /// A skipped directory is never looked inside, however deep the
    /// repositories under it are.
    func testASkippedDirectoryIsNeverLookedInside() throws {
        try makeRepo("dev/alpha")
        try makeRepo("dev/archive/old")
        try makeRepo("dev/archive/deeper/older")

        let scanner = GitRepoScanner(roots: [root], skippedDirectories: [dir("dev/archive")])

        XCTAssertEqual(paths(scanner.scan()), [path("dev/alpha")])
    }

    /// A skip names a directory, not a name: a folder elsewhere that happens
    /// to share its last component is still scanned.
    func testASkipIsAPathNotAName() throws {
        try makeRepo("dev/archive/old")
        try makeRepo("work/archive/kept")

        let scanner = GitRepoScanner(roots: [root], skippedDirectories: [dir("dev/archive")])

        XCTAssertEqual(paths(scanner.scan()), [path("work/archive/kept")])
    }

    /// No roots, no scan: nothing is found until the user adds a directory.
    func testNoRootsFindsNothing() throws {
        try makeRepo("dev/alpha")

        XCTAssertTrue(GitRepoScanner(roots: [], skippedDirectories: []).scan().isEmpty)
    }

    func testSubmodulesAreLeftOutByDefault() throws {
        try makeRepoWithSubmodule()

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()), [path("dev/alpha")])
    }

    /// Off, each checked-out submodule is a project of its own.
    func testSubmodulesAreListedWhenTheOptionIsOff() throws {
        try makeRepoWithSubmodule()

        let scanner = GitRepoScanner(roots: [root], skippedDirectories: [], skipsSubmodules: false)

        XCTAssertEqual(paths(scanner.scan()), [path("dev/alpha"), path("dev/alpha/external/toolkit")])
    }

    /// `skips(path:)` is how the coordinator drops listed projects the
    /// settings now leave out, without waiting for a scan.
    func testSkipsPathAgreesWithTheScan() throws {
        let scanner = GitRepoScanner(roots: [dir("dev")], skippedDirectories: [dir("dev/archive")])

        XCTAssertFalse(scanner.skips(path: path("dev/alpha")))
        XCTAssertTrue(scanner.skips(path: path("dev/archive/old")))
        XCTAssertTrue(scanner.skips(path: path("dev/.hidden/beta")))
        XCTAssertTrue(scanner.skips(path: path("work/gamma")), "outside every root")
    }

    func testBuildAndDependencyDirectoriesArePruned() throws {
        for pruned in GitRepoScanner.prunedDirectoryNames {
            try makeRepo("dev/\(pruned)/vendored")
        }
        try makeRepo("dev/alpha")

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()), [path("dev/alpha")])
    }

    /// Following symlinks turns one repository into several, or into a loop.
    func testSymlinkedDirectoriesAreNotFollowed() throws {
        try makeRepo("dev/alpha")
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("mirror"),
            withDestinationURL: root.appendingPathComponent("dev")
        )

        XCTAssertEqual(paths(GitRepoScanner(roots: [root]).scan()), [path("dev/alpha")])
    }

    /// Sorted output, so two scans of an unchanged tree are byte-identical
    /// and the reconciler sees no churn (`idempotency`).
    func testResultsAreSortedByPathAndStableAcrossRuns() throws {
        try makeRepo("dev/zeta")
        try makeRepo("dev/alpha")
        try makeRepo("work/beta")

        let scanner = GitRepoScanner(roots: [root])
        let first = scanner.scan()
        XCTAssertEqual(paths(first), [path("dev/alpha"), path("dev/zeta"), path("work/beta")])
        XCTAssertEqual(first, scanner.scan())
    }

    func testAnEmptyTreeFindsNothingRatherThanFailing() {
        XCTAssertTrue(GitRepoScanner(roots: [root]).scan().isEmpty)
    }

    func testProgressIsReportedAsTheWalkGoes() throws {
        try makeRepo("dev/alpha")
        let reports = Recorder()

        _ = GitRepoScanner(roots: [root]).scan(onProgress: { progress in
            reports.append(progress)
        })

        XCTAssertGreaterThan(reports.count, 0, "the progress window needs something truthful to say")
        XCTAssertEqual(reports.lastVisited, reports.count,
                       "every visited directory is reported exactly once")
    }

    /// The hook exists because the alternative is a walk that keeps running
    /// after the app is told to quit.
    func testCancellationStopsTheWalk() throws {
        try makeRepo("dev/alpha")
        try makeRepo("work/beta")

        let found = GitRepoScanner(roots: [root]).scan(isCancelled: { true })

        XCTAssertTrue(found.isEmpty)
    }

    // MARK: - Remote parsing

    func testOriginIsReadOutOfTheConfigWithoutShellingOutToGit() throws {
        let gitDirectory = try makeRepo("dev/alpha", configBody: """
            [core]
            \trepositoryformatversion = 0
            [remote "upstream"]
            \turl = git@example.com:upstream/alpha.git
            [remote "origin"]
            \turl = git@example.com:someone/alpha.git
            \tfetch = +refs/heads/*:refs/remotes/origin/*
            [branch "main"]
            \tremote = origin
            """)

        XCTAssertEqual(GitRepoScanner.originRemote(inGitDirectory: gitDirectory),
                       "git@example.com:someone/alpha.git")
    }

    func testARepositoryWithNoOriginHasNoRemote() throws {
        let gitDirectory = try makeRepo("dev/alpha", configBody: "[core]\n\tbare = false\n")
        XCTAssertNil(GitRepoScanner.originRemote(inGitDirectory: gitDirectory))
    }

    func testAMissingConfigIsNotAnError() throws {
        let gitDirectory = root.appendingPathComponent("dev/alpha/.git", isDirectory: true)
        try FileManager.default.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        XCTAssertNil(GitRepoScanner.originRemote(inGitDirectory: gitDirectory))
    }

    // MARK: - Helpers

    /// Records progress from whatever thread the walk runs on.
    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var visited: [Int] = []

        func append(_ progress: GitRepoScanner.Progress) {
            lock.lock()
            visited.append(progress.directoriesVisited)
            lock.unlock()
        }

        var count: Int {
            lock.lock(); defer { lock.unlock() }
            return visited.count
        }

        var lastVisited: Int {
            lock.lock(); defer { lock.unlock() }
            return visited.last ?? 0
        }
    }

    /// A `.git` directory holding only `hooks/` — what a hook installer leaves
    /// in a folder that was never a checkout.
    private func makeHookOnlyGitFolder(_ relativePath: String) throws {
        let hooks = root
            .appendingPathComponent(relativePath, isDirectory: true)
            .appendingPathComponent(".git/hooks", isDirectory: true)
        try FileManager.default.createDirectory(at: hooks, withIntermediateDirectories: true)
    }

    @discardableResult
    private func makeRepo(_ relativePath: String, remote: String? = nil) throws -> URL {
        let body = remote.map { "[remote \"origin\"]\n\turl = \($0)\n" } ?? "[core]\n\tbare = false\n"
        return try makeRepo(relativePath, configBody: body)
    }

    @discardableResult
    private func makeRepo(_ relativePath: String, configBody: String) throws -> URL {
        let gitDirectory = root
            .appendingPathComponent(relativePath, isDirectory: true)
            .appendingPathComponent(".git", isDirectory: true)
        try FileManager.default.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        try configBody.write(to: gitDirectory.appendingPathComponent("config"),
                             atomically: true, encoding: .utf8)
        // `HEAD` is what makes it a repository rather than a folder called
        // `.git`, and what the scanner checks for.
        try "ref: refs/heads/main\n".write(to: gitDirectory.appendingPathComponent("HEAD"),
                                           atomically: true, encoding: .utf8)
        return gitDirectory
    }

    private func dir(_ relativePath: String) -> URL {
        root.appendingPathComponent(relativePath, isDirectory: true)
    }

    /// `dev/alpha` with `external/toolkit` checked out as an absorbed
    /// submodule: a `.git` file pointing into the parent's `.git/modules`.
    private func makeRepoWithSubmodule() throws {
        let parentGit = try makeRepo("dev/alpha")
        try "[submodule \"external/toolkit\"]\n\tpath = external/toolkit\n\turl = git@example.com:x/toolkit.git\n"
            .write(to: dir("dev/alpha").appendingPathComponent(".gitmodules"), atomically: true, encoding: .utf8)
        let module = parentGit.appendingPathComponent("modules/external/toolkit", isDirectory: true)
        try FileManager.default.createDirectory(at: module, withIntermediateDirectories: true)
        try "[core]\n\tbare = false\n"
            .write(to: module.appendingPathComponent("config"), atomically: true, encoding: .utf8)
        try "ref: refs/heads/main\n"
            .write(to: module.appendingPathComponent("HEAD"), atomically: true, encoding: .utf8)
        let checkout = dir("dev/alpha/external/toolkit")
        try FileManager.default.createDirectory(at: checkout, withIntermediateDirectories: true)
        try "gitdir: \(module.path)\n"
            .write(to: checkout.appendingPathComponent(".git"), atomically: true, encoding: .utf8)
    }

    private func path(_ relativePath: String) -> String {
        root.appendingPathComponent(relativePath, isDirectory: true).standardizedFileURL.path
    }

    private func paths(_ found: [ScannedGitRepo]) -> [String] {
        found.map { URL(fileURLWithPath: $0.path).standardizedFileURL.path }
    }
}
