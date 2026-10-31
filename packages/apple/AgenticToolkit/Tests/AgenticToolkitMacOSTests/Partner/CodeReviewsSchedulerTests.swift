import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Drives real git in temp repos; the fixture's commits are dated January 2026, so the clock sits just after.
@MainActor
final class CodeReviewsSchedulerTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var settings: SettingsStore!
    private var repo: PartnerGitFixture!
    private var projects: [PartnerToolSource.Project] = []
    /// 2026-01-04T00:00:00Z: day 1 and day 2 commits fall inside a 72-hour window.
    private let clock = Date(timeIntervalSince1970: 1_767_484_800)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodeReviewsSchedulerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
        settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                 secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        settings.set(72, for: UserSettings.partnerReviewsWindowHours)
        repo = try PartnerGitFixture()
        projects = [PartnerToolSource.Project(id: "repo", name: "demo", path: repo.directory.path)]
    }

    override func tearDown() async throws {
        store = nil; repo = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeScheduler() -> CodeReviewsScheduler {
        CodeReviewsScheduler(store: store, crawler: CommitCrawler(git: repo.review), git: repo.review,
                             projects: { [unowned self] in projects }, settings: settings,
                             now: { [unowned self] in clock })
    }

    func testTwoCommitsAreQueued() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.commit(file: "b.txt", day: 2, message: "second")
        let summary = await makeScheduler().crawlAndSummarise()
        XCTAssertEqual(summary, "2 queued, 0 running, 2 inserted this crawl")
        XCTAssertEqual(try store.reviews(state: .queued).map(\.subject), ["first", "second"])
    }

    func testASecondCrawlInsertsNothing() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let scheduler = makeScheduler()
        _ = await scheduler.crawlAndSummarise()
        let summary = await scheduler.crawlAndSummarise()
        XCTAssertEqual(summary, "1 queued, 0 running, 0 inserted this crawl")
    }

    func testCommitsOutsideTheWindowAreNotQueued() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "old")
        try repo.commit(file: "b.txt", day: 3, message: "recent")
        settings.set(24, for: UserSettings.partnerReviewsWindowHours)
        let summary = await makeScheduler().crawlAndSummarise()
        XCTAssertTrue(summary.contains("1 queued"), summary)
        XCTAssertEqual(try store.reviews(state: .queued).map(\.subject), ["recent"])
    }

    func testAnOptedOutRepoQueuesNothing() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.commit(file: "b.txt", day: 2, message: "second")
        try store.setReviewSetting(repoID: "repo", key: "opted_out", value: "1")
        let summary = await makeScheduler().crawlAndSummarise()
        XCTAssertTrue(summary.contains("0 queued"), summary)
        XCTAssertTrue(try store.reviews(state: .queued).isEmpty)
    }

    func testOtherBranchesAreCrawledOnlyWhenTheSettingIsOn() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.git("checkout", "-b", "feature")
        try repo.commit(file: "b.txt", day: 2, message: "on feature")
        try repo.git("checkout", "main")

        let without = await makeScheduler().crawlAndSummarise()
        XCTAssertTrue(without.contains("1 queued"), without)

        settings.set(true, for: UserSettings.partnerReviewsIncludeOtherBranches)
        let with = await makeScheduler().crawlAndSummarise()
        XCTAssertTrue(with.contains("2 queued"), with)
        let feature = try store.reviews(state: .queued).first { $0.subject == "on feature" }
        XCTAssertEqual(feature?.branch, "feature")
    }

    /// One repo whose git calls throw is skipped and logged; the others still queue.
    func testARepoThatFailsIsSkippedAndTheOthersStillQueue() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.commit(file: "b.txt", day: 2, message: "second")
        let plain = directory.appendingPathComponent("not-a-repo")
        try FileManager.default.createDirectory(at: plain, withIntermediateDirectories: true)
        projects = [PartnerToolSource.Project(id: "broken", name: "broken", path: plain.path)] + projects

        let summary = await makeScheduler().crawlAndSummarise()
        XCTAssertEqual(summary, "2 queued, 0 running, 2 inserted this crawl")
        XCTAssertEqual(Set(try store.reviews(state: .queued).map(\.repoID)), ["repo"])
    }

    func testRunningReviewsAreCounted() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.commit(file: "b.txt", day: 2, message: "second")
        let scheduler = makeScheduler()
        _ = await scheduler.crawlAndSummarise()
        var review = try XCTUnwrap(try store.reviews(state: .queued).first)
        review.state = .running
        try store.updateReview(review)
        let summary = await scheduler.crawlAndSummarise()
        XCTAssertEqual(summary, "1 queued, 1 running, 0 inserted this crawl")
    }

    // MARK: - The job's text

    func testTheFixStepCommitsOnTheFixBranchAndNeverPushes() {
        let fix = PartnerJobDefaults.codeReviews().steps[2].command
        XCTAssertTrue(fix.contains("Commit on {fix_branch}"), fix)
        XCTAssertTrue(fix.contains("Do not push"), fix)
        XCTAssertTrue(fix.contains("\"Reviewed-Commit: {sha}\""), fix)
    }

    func testTheGuidelinesNameTheLoopAndTheRangeFallback() {
        let guidelines = PartnerJobDefaults.codeReviews().guidelines
        for needle in ["partner_review_next", "partner_review_start", "partner_review_finish",
                       "partner_session_run", "partner_session_wait", "{sha}^..{sha}"] {
            XCTAssertTrue(guidelines.contains(needle), needle)
        }
    }
}
