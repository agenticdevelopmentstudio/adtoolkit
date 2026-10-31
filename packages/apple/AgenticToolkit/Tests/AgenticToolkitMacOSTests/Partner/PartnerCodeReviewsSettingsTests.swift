import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class PartnerCodeReviewsSettingsTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerCodeReviewsSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Settings

    func testTheReviewSettingsDefaults() {
        let settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                     secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsWindowHours), 24)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsCrawlIntervalMinutes), 30)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsConcurrency), 1)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsIncludeOtherBranches), false)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsReviewerModel), "")
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsFixBranch), "partner/review-fixes")
    }

    // MARK: - Projects table

    private func makeTab() -> PartnerCodeReviewsSettingsViewController {
        let tab = PartnerCodeReviewsSettingsViewController(store: store, projects: {
            [.init(id: "a", name: "Alpha", path: "/r/alpha"), .init(id: "b", name: "Beta", path: "/r/beta"),
             .init(id: "c", name: "No Path", path: "")]
        })
        tab.loadViewIfNeeded()
        tab.reloadProjects()
        return tab
    }

    func testProjectsWithAPathAreListed() {
        let tab = makeTab()
        XCTAssertEqual(tab.listed.map(\.id), ["a", "b"])
        XCTAssertEqual(tab.projectsTable.numberOfRows, 2)
    }

    func testTheReviewCheckboxWritesTheOptOut() throws {
        let tab = makeTab()
        XCTAssertTrue(tab.isReviewed("a"), "reviewed unless opted out")
        tab.setReviewed(false, projectID: "a")
        XCTAssertEqual(try store.reviewSetting(repoID: "a", key: "opted_out"), "1")
        XCTAssertFalse(tab.isReviewed("a"))
        XCTAssertTrue(tab.isReviewed("b"))
        tab.setReviewed(true, projectID: "a")
        XCTAssertNil(try store.reviewSetting(repoID: "a", key: "opted_out"), "opting back in deletes the row")
        XCTAssertTrue(tab.isReviewed("a"))
    }

    func testTheCheckboxCellShowsTheOptOut() throws {
        try store.setReviewSetting(repoID: "b", key: "opted_out", value: "1")
        let tab = makeTab()
        let column = try XCTUnwrap(tab.projectsTable.tableColumns.first { $0.identifier.rawValue == "review" })
        let alpha = tab.tableView(tab.projectsTable, viewFor: column, row: 0) as? NSButton
        let beta = tab.tableView(tab.projectsTable, viewFor: column, row: 1) as? NSButton
        XCTAssertEqual(alpha?.state, .on)
        XCTAssertEqual(beta?.state, .off)
    }

    private func makeController() -> PartnerController {
        let sessions = PartnerSessionRegistry(store: store, environment: { [:] },
                                              detector: ManualSessionEventDetector())
        let paths = PartnerPaths(home: directory, token: "kitchen-test")
        return PartnerController(
            store: store, sessions: sessions, notifier: PartnerNotifier(store: store), paths: paths,
            endpoint: { nil })
    }

    func testThePanelHasACodeReviewsTab() {
        let panel = PartnerSettingsPanel.make(controller: makeController(), projects: { [] })
        XCTAssertTrue(panel.containedPanels.contains { $0 is PartnerCodeReviewsSettingsViewController },
                      "\(panel.containedPanels.map { type(of: $0) })")
    }

    func testShowingTheJobsTabKeepsTheGuidelines() throws {
        let controller = makeController()
        let panel = PartnerSettingsPanel.make(controller: controller, projects: { [] })
        let jobs = try XCTUnwrap(panel.containedPanels.first { $0 is PartnerJobsSettingsViewController }
            as? PartnerJobsSettingsViewController)
        jobs.loadViewIfNeeded()
        jobs.flushGuidelines()
        let stored = try XCTUnwrap(store.jobs().first { $0.id == PartnerJobDefaults.codeReviewsID })
        XCTAssertEqual(stored.guidelines, PartnerJobDefaults.codeReviewsGuidelines,
                       "the first refresh's selection flush must not save the unfilled view")
        let file = controller.paths.jobsDirectory.appendingPathComponent("code-reviews.md")
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    // MARK: - Toolbar status

    func testTheStatusShowsTheQueueWhileReviewsAreEnabled() {
        let queue = PartnerToolbar.ReviewQueue(waiting: 2, running: 1, done: 3)
        XCTAssertEqual(PartnerToolbar.statusText(state: .idle, jobs: ["Code reviews"], queue: queue,
                                                 reviewsEnabled: true),
                       "Idle · Code reviews · queue: 2 waiting · 1 running · 3 done")
        XCTAssertEqual(PartnerToolbar.statusText(state: .idle, jobs: ["Code reviews"],
                                                 queue: .init(waiting: 0, running: 0, done: 0), reviewsEnabled: true),
                       "Idle · Code reviews · queue: 0 waiting · 0 running · 0 done")
    }

    func testTheStatusHidesAnEmptyQueueWhileReviewsAreOff() {
        let empty = PartnerToolbar.ReviewQueue(waiting: 0, running: 0, done: 0)
        let finished = PartnerToolbar.ReviewQueue(waiting: 0, running: 0, done: 4)
        XCTAssertEqual(PartnerToolbar.statusText(state: .stopped, jobs: [], queue: empty, reviewsEnabled: false),
                       "Stopped")
        XCTAssertEqual(PartnerToolbar.statusText(state: .stopped, jobs: [], queue: finished, reviewsEnabled: false),
                       "Stopped · queue: 0 waiting · 0 running · 4 done")
        XCTAssertEqual(PartnerToolbar.statusText(state: .idle, jobs: [], queue: nil, reviewsEnabled: true), "Idle")
    }

    // MARK: - Shelf subtitle

    private func review(state: PartnerReviewState, summary: String? = nil, skip: String? = nil) -> PartnerReview {
        PartnerReview(id: "r", repoID: "repo", repoPath: "/p", repoName: "demo", sha: "abc", parent: "p",
                      branch: "main", subject: "s", author: "Ann", committedAt: Date(), state: state,
                      summary: summary, skipReason: skip)
    }

    func testASessionWithoutAReviewShowsItsFolderAndState() {
        XCTAssertEqual(PartnerShelfRow.sessionSubtitle(directory: "/w/demo", state: "idle", review: nil),
                       "demo · idle")
    }

    func testAReviewSessionShowsTheReviewsStateAndSummary() {
        XCTAssertEqual(PartnerShelfRow.sessionSubtitle(directory: "/w/demo", state: "busy",
                                                       review: review(state: .running)), "review running")
        XCTAssertEqual(PartnerShelfRow.sessionSubtitle(directory: "/w/demo", state: "closed",
                                                       review: review(state: .done, summary: "Fixed two.\n")),
                       "review done · Fixed two.")
        XCTAssertEqual(PartnerShelfRow.sessionSubtitle(directory: "/w/demo", state: "closed",
                                                       review: review(state: .skipped, skip: "dirty worktree")),
                       "review skipped · dirty worktree")
    }
}
