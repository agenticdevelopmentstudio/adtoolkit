import XCTest
@testable import AgenticToolkitMacOS

final class CommitCrawlerTests: XCTestCase {
    private var store: PartnerStore!
    private var storeDirectory: URL!

    override func setUpWithError() throws {
        storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommitCrawlerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        store = try PartnerStore(path: storeDirectory.appendingPathComponent("Partner.db").path)
    }

    override func tearDownWithError() throws {
        store = nil
        try? FileManager.default.removeItem(at: storeDirectory)
    }

    /// first on main, second on feature, third on main, then a merge of feature into main.
    private func mergedRepo() throws -> (PartnerGitFixture, [String]) {
        let repo = try PartnerGitFixture()
        let first = try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.git("checkout", "-b", "feature")
        let second = try repo.commit(file: "b.txt", day: 2, message: "second")
        try repo.git("checkout", "main")
        let third = try repo.commit(file: "a.txt", day: 3, message: "third")
        try repo.merge(branch: "feature", day: 4)
        return (repo, [first, second, third])
    }

    func testCommitsExcludeMergesAndAreOldestFirst() async throws {
        let (repo, shas) = try mergedRepo()
        let found = try await CommitCrawler(git: repo.review)
            .commits(in: repo.directory, branch: "main", since: .distantPast)
        XCTAssertEqual(found.map(\.sha), shas)
        XCTAssertEqual(found.map(\.subject), ["first", "second", "third"])
        XCTAssertEqual(found[0].parent, ReviewGit.emptyTree)
        XCTAssertEqual(found[2].parent, shas[0])
        XCTAssertEqual(found[0].author, "Ann")
    }

    func testSinceFiltersOldCommits() async throws {
        let (repo, shas) = try mergedRepo()
        let since = ISO8601DateFormatter().date(from: "2026-01-02T18:00:00Z")!
        let found = try await CommitCrawler(git: repo.review).commits(in: repo.directory, branch: "main", since: since)
        XCTAssertEqual(found.map(\.sha), [shas[2]])
    }

    func testCrawlInsertsOnceThenNothing() async throws {
        let (repo, shas) = try mergedRepo()
        let repos = [(id: "r1", path: repo.directory.path, name: "repo")]
        let crawler = CommitCrawler(git: repo.review)
        let first = try await crawler.crawl(repos: repos, branches: { _ in ["main"] },
                                        since: .distantPast, store: store)
        let second = try await crawler.crawl(repos: repos, branches: { _ in ["main"] },
                                        since: .distantPast, store: store)
        XCTAssertEqual(first, 3)
        XCTAssertEqual(second, 0)
        let queued = try store.reviews(state: .queued)
        XCTAssertEqual(queued.map(\.sha), shas)
        XCTAssertEqual(queued[0].id, "r1:\(shas[0])")
        XCTAssertEqual(queued[0].branch, "main")
        XCTAssertEqual(queued[0].repoName, "repo")
        XCTAssertEqual(queued[0].supersededBy, [])
    }
}
