import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class PartnerCoordinatorTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var settings: SettingsStore!
    private var status: AutomationServerStatus!
    private var log: FakeProcessLog!
    private var registered: [any ChatToolSource] = []
    private var coordinator: PartnerCoordinator?

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerCoordinatorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
        settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                 secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        status = AutomationServerStatus()
        log = FakeProcessLog()
        registered = []
    }

    override func tearDown() async throws {
        if let coordinator {
            coordinator.stop()
            await coordinator.controller.stop()
            _ = coordinator.controller.sessions.closeAll()
            coordinator.unregister()
        }
        coordinator = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeCoordinator(quitLimit: Duration = PartnerCoordinator.quitTurnLimit,
                                 isPIDAlive: @escaping (Int32) -> Bool = { _ in false }) -> PartnerCoordinator {
        let log = log!
        let settings = settings!
        let made = PartnerCoordinator(
            store: store, paths: PartnerPaths(home: directory, token: "kitchen-test"), status: status,
            terminalEnvironment: { [:] }, registerTools: { [unowned self] in registered.append($0) },
            projects: { [] }, commandRegistry: CommandRegistry(), detector: ManualSessionEventDetector(),
            settings: settings, quitLimit: quitLimit,
            makeController: { store, sessions, notifier, paths, endpoint in
                PartnerController(
                    store: store, sessions: sessions, notifier: notifier, paths: paths, endpoint: endpoint,
                    findClaude: { "/bin/true" },
                    makeProcess: { configuration, _ in
                        let process = FakePartnerProcess(configuration: configuration)
                        log.add(process)
                        return process
                    },
                    settings: settings, pid: 4242, isPIDAlive: isPIDAlive)
            })
        coordinator = made
        return made
    }

    private func waitUntil(_ timeout: TimeInterval = 3, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private func endpointUp() {
        status.token = "t"
        status.port = 4321
    }

    func testToolsAreRegisteredOnceAcrossRestarts() {
        let coordinator = makeCoordinator()
        coordinator.startServices()
        coordinator.stop()
        coordinator.startServices()
        XCTAssertEqual(registered.count, 1)
        XCTAssertTrue(registered.first is PartnerToolSource)
    }

    func testDisabledPartnerStaysStopped() async {
        endpointUp()
        let coordinator = makeCoordinator()
        coordinator.startServices()
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(coordinator.controller.state, .stopped)
        XCTAssertTrue(log.all.isEmpty)
    }

    func testEnabledPartnerWaitsForTheEndpoint() async {
        settings.set(true, for: UserSettings.partnerEnabled)
        let coordinator = makeCoordinator()
        coordinator.startServices()
        status.failureReason = "port 22848 is in use"
        await waitUntil { coordinator.controller.state != .stopped }
        XCTAssertEqual(coordinator.controller.state,
                       .failed("waiting for the automation endpoint: port 22848 is in use"),
                       "no endpoint yet, so no start, and the state says why")
        XCTAssertTrue(log.all.isEmpty)
        endpointUp()
        await waitUntil { !self.log.all.isEmpty }
        XCTAssertEqual(log.all.count, 1)
        XCTAssertFalse(coordinator.controller.state.displayText.contains("waiting"))
    }

    func testTurningEnabledOnStartsAndOffStops() async {
        endpointUp()
        let coordinator = makeCoordinator()
        coordinator.startServices()
        settings.set(true, for: UserSettings.partnerEnabled)
        await waitUntil { coordinator.controller.state == .thinking }
        XCTAssertEqual(log.all.count, 1)
        XCTAssertNotNil(coordinator.controller.callerID)

        settings.set(false, for: UserSettings.partnerEnabled)
        await waitUntil { coordinator.controller.state == .stopped }
        XCTAssertEqual(coordinator.controller.state, .stopped)
        XCTAssertTrue(log.all[0].wasTerminated)
    }

    func testToolSourceAcceptsOnlyThePartnersCallerID() async {
        endpointUp()
        settings.set(true, for: UserSettings.partnerEnabled)
        let coordinator = makeCoordinator()
        coordinator.startServices()
        await waitUntil { coordinator.controller.callerID != nil && coordinator.controller.state == .thinking }
        guard let source = registered.first, let caller = coordinator.controller.callerID else {
            return XCTFail("partner did not start")
        }
        let allowed = await source.callTool(name: "partner_projects_list", argumentsJSON: Data("{}".utf8),
                                            caller: caller)
        XCTAssertFalse(allowed.isError, allowed.content)
        let refused = await source.callTool(name: "partner_projects_list", argumentsJSON: Data("{}".utf8),
                                            caller: "someone-else")
        XCTAssertTrue(refused.isError)
    }

    // MARK: - Code reviews

    func testTheCodeReviewsJobHasATickPreparerAndTheReviewTools() async {
        let coordinator = makeCoordinator()
        XCTAssertNotNil(coordinator.controller.tickPreparers[PartnerJobDefaults.codeReviewsID])
        coordinator.startServices()
        let names = await registered.first?.toolDefinitions().map(\.name) ?? []
        XCTAssertTrue(names.contains("partner_review_start"), "\(names)")
        let summary = await coordinator.controller.tickPreparers[PartnerJobDefaults.codeReviewsID]?()
        XCTAssertEqual(summary, "0 queued, 0 running, 0 inserted this crawl")
    }

    private func insertRunningReview() throws {
        try store.insertReview(PartnerReview(
            id: "repo:abc", repoID: "repo", repoPath: "/tmp/none", repoName: "demo", sha: "abc", parent: "def",
            branch: "main", subject: "s", author: "Ann", committedAt: Date(), state: .running, supersededBy: []))
    }

    func testInterruptedReviewsAreRequeuedOnceTheLockIsTaken() async throws {
        try insertRunningReview()
        let coordinator = makeCoordinator()
        coordinator.startServices()
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(try store.review(id: "repo:abc")?.state, .running, "a disabled partner takes no lock")

        endpointUp()
        settings.set(true, for: UserSettings.partnerEnabled)
        await waitUntil { coordinator.controller.state == .thinking }
        XCTAssertEqual(try store.review(id: "repo:abc")?.state, .queued)

        var later = try XCTUnwrap(try store.review(id: "repo:abc"))
        later.state = .running
        try store.updateReview(later)
        await coordinator.controller.restart()
        await waitUntil { coordinator.controller.state == .thinking }
        XCTAssertEqual(try store.review(id: "repo:abc")?.state, .running, "only the first lock requeues")
    }

    func testAnotherCopysLiveReviewIsNotRequeued() async throws {
        try insertRunningReview()
        XCTAssertTrue(try store.acquireLock(pid: 999, isAlive: { _ in true }))
        endpointUp()
        settings.set(true, for: UserSettings.partnerEnabled)
        let coordinator = makeCoordinator(isPIDAlive: { $0 == 999 })
        coordinator.startServices()
        await waitUntil { coordinator.controller.state != .stopped && coordinator.controller.state != .starting }
        guard case .failed(let reason) = coordinator.controller.state else {
            return XCTFail("expected the lock refusal, got \(coordinator.controller.state)")
        }
        XCTAssertTrue(reason.contains("999"), reason)
        XCTAssertEqual(try store.review(id: "repo:abc")?.state, .running)
    }

    // MARK: - Crawl interval

    private func codeReviewsJob() throws -> PartnerJob? {
        try store.jobs().first { $0.id == PartnerJobDefaults.codeReviewsID }
    }

    func testTheCrawlIntervalRewritesTheStoppedJobsSchedule() async throws {
        let coordinator = makeCoordinator()
        coordinator.startServices()
        settings.set(5, for: UserSettings.partnerReviewsCrawlIntervalMinutes)
        await waitUntil { (try? self.codeReviewsJob())??.scheduleSeconds == 300 }
        XCTAssertEqual(try codeReviewsJob()?.scheduleSeconds, 300, "the job is seeded, then rewritten")
        XCTAssertTrue(coordinator.controller.refreshers.isEmpty, "a stopped partner keeps no timers")
    }

    func testTheCrawlIntervalRestartsTheRunningJobsTimer() async throws {
        var job = PartnerJobDefaults.codeReviews()
        job.isEnabled = true
        try store.upsert(job)
        endpointUp()
        settings.set(true, for: UserSettings.partnerEnabled)
        let coordinator = makeCoordinator()
        coordinator.startServices()
        let id = PartnerJobDefaults.codeReviewsID
        await waitUntil { coordinator.controller.refreshers[id] != nil }
        XCTAssertEqual(coordinator.controller.refreshers[id]?.interval, 1800)
        let before = coordinator.controller.refreshers[id]

        settings.set(1, for: UserSettings.partnerReviewsCrawlIntervalMinutes)
        await waitUntil { coordinator.controller.refreshers[id]?.interval == 60 }
        XCTAssertEqual(coordinator.controller.refreshers[id]?.interval, 60)
        XCTAssertEqual(try codeReviewsJob()?.scheduleSeconds, 60)
        XCTAssertFalse(before?.isRunning ?? true, "the old timer is stopped")
        XCTAssertTrue(coordinator.controller.refreshers[id]?.isRunning ?? false)
    }

    func testStartingAppliesTheCrawlInterval() throws {
        settings.set(5, for: UserSettings.partnerReviewsCrawlIntervalMinutes)
        makeCoordinator().startServices()
        XCTAssertEqual(try codeReviewsJob()?.scheduleSeconds, 300, "a setting changed while quit still lands")
    }

    func testAJobWriteIsBroughtBackToTheCrawlInterval() async throws {
        let coordinator = makeCoordinator()
        coordinator.startServices()
        settings.set(2, for: UserSettings.partnerReviewsCrawlIntervalMinutes)
        await waitUntil { (try? self.codeReviewsJob())??.scheduleSeconds == 120 }
        try store.upsert(PartnerJobDefaults.codeReviews()) // Reset to default stores 1800
        await waitUntil { (try? self.codeReviewsJob())??.scheduleSeconds == 120 }
        XCTAssertEqual(try codeReviewsJob()?.scheduleSeconds, 120)
    }

    func testTheCrawlIntervalStopsFollowingOnceStopped() async throws {
        let coordinator = makeCoordinator()
        coordinator.startServices()
        coordinator.stop()
        settings.set(7, for: UserSettings.partnerReviewsCrawlIntervalMinutes)
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertNotEqual(try codeReviewsJob()?.scheduleSeconds, 420)
    }

    // MARK: - Review counts and subtitles

    private func review(_ sha: String, state: PartnerReviewState, summary: String? = nil) -> PartnerReview {
        PartnerReview(
            id: "repo:\(sha)", repoID: "repo", repoPath: "/tmp/none", repoName: "demo", sha: sha, parent: "p",
            branch: "main", subject: "s", author: "Ann", committedAt: Date(), state: state, summary: summary,
            supersededBy: [])
    }

    func testAReviewsWriteRefreshesTheToolbarQueue() async throws {
        let coordinator = makeCoordinator()
        let toolbar = PartnerToolbar(controller: coordinator.controller)
        XCTAssertFalse(toolbar.statusLabel.stringValue.contains("queue"), toolbar.statusLabel.stringValue)
        let store = self.store!
        let running = review("aaa", state: .running)
        let queued = review("bbb", state: .queued)
        let done = review("ccc", state: .done)
        try await Task.detached {
            try store.insertReview(running)
            try store.insertReview(queued)
            try store.insertReview(done)
        }.value
        let expected = "queue: 1 waiting · 1 running · 1 done"
        await waitUntil { toolbar.statusLabel.stringValue.contains(expected) }
        XCTAssertTrue(toolbar.statusLabel.stringValue.hasSuffix(expected), toolbar.statusLabel.stringValue)
    }

    func testAReviewSessionsSubtitleShowsTheReviewsStateAndSummary() async throws {
        let coordinator = makeCoordinator()
        let split = PartnerSplitViewController(controller: coordinator.controller)
        split.loadViewIfNeeded()
        var owned = review("abc1234", state: .running)
        owned.sessionID = "s1"  // the session the review is running in
        try store.insertReview(owned)
        try store.upsert(PartnerStore.SessionRecord(id: "s1", title: "review abc1234", directory: "/w/demo",
                                                    openedAt: Date(), closedAt: Date(), reviewID: "repo:abc1234"))
        await waitUntil { split.shelf.rows.contains { $0.id == "s1" } }
        XCTAssertEqual(split.shelf.rows.first { $0.id == "s1" }?.subtitle, "review running")

        var finished = try XCTUnwrap(try store.review(id: "repo:abc1234"))
        finished.state = .done
        finished.summary = "Fixed one finding."
        try store.updateReview(finished)
        await waitUntil { split.shelf.rows.first { $0.id == "s1" }?.subtitle == "review done · Fixed one finding." }
        XCTAssertEqual(split.shelf.rows.first { $0.id == "s1" }?.subtitle, "review done · Fixed one finding.")
    }

    // MARK: - Quit

    func testQuitTurnFitsTheFlushBudget() {
        XCTAssertEqual(PartnerCoordinator.quitTurnLimit, .seconds(3))
        XCTAssertLessThan(PartnerCoordinator.quitTurnLimit, ApplicationShutdownCoordinator.defaultFlushBudget)
    }

    func testAQuitTurnThatNeverFinishesStillStopsWithinTheCap() async {
        endpointUp()
        settings.set(true, for: UserSettings.partnerEnabled)
        let coordinator = makeCoordinator(quitLimit: .milliseconds(300))
        coordinator.startServices()
        await waitUntil { coordinator.controller.state == .thinking }
        guard let process = log.all.first else { return XCTFail("partner did not start") }
        process.push(ClaudeStreamMessage(kind: .result, subtype: "success"))
        await waitUntil { coordinator.controller.state == .idle }
        XCTAssertEqual(coordinator.controller.state, .idle)

        coordinator.stop()
        let clock = ContinuousClock()
        let began = clock.now
        await coordinator.terminate()
        let elapsed = clock.now - began

        XCTAssertEqual(process.sent.count, 2, "the quit turn was sent after the start turn")
        XCTAssertEqual(coordinator.controller.state, .stopped)
        XCTAssertTrue(process.wasTerminated)
        XCTAssertGreaterThanOrEqual(elapsed, .milliseconds(250), "it waited for the turn")
        XCTAssertLessThan(elapsed, .milliseconds(1500), "and no longer than the cap")

        // A second terminate (the registry's, after the host's early one) does not quit twice.
        await coordinator.terminate()
        XCTAssertEqual(process.sent.count, 2)
        XCTAssertEqual(log.all.count, 1)
    }

    func testQuitClosesOpenSessionsKeepingTheirFinalScreens() async throws {
        let coordinator = makeCoordinator(quitLimit: .milliseconds(100))
        coordinator.startServices()
        let session = coordinator.controller.sessions.open(directory: directory.path, title: "review",
                                                           firstCommand: "echo READY")
        await waitUntil { session.chat.screen()?.contains("READY") ?? false }
        await coordinator.terminate()
        XCTAssertTrue(coordinator.controller.sessions.sessions.isEmpty)
        let record = try XCTUnwrap(store.sessions().first { $0.id == session.id.uuidString })
        XCTAssertNotNil(record.closedAt)
        XCTAssertTrue(record.finalScreen?.contains("READY") ?? false, record.finalScreen ?? "nil")
    }

    func testNothingStartsAfterTerminate() async {
        endpointUp()
        let coordinator = makeCoordinator(quitLimit: .milliseconds(100))
        coordinator.startServices()
        await coordinator.terminate()
        settings.set(true, for: UserSettings.partnerEnabled)
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertTrue(log.all.isEmpty)
        XCTAssertEqual(coordinator.controller.state, .stopped)
    }

    // MARK: - Window subscribers fed off the main actor

    func testAJobsWriteOffTheMainActorRefreshesTheToolbar() async throws {
        let coordinator = makeCoordinator()
        let toolbar = PartnerToolbar(controller: coordinator.controller)
        let store = self.store!
        try await Task.detached {
            try store.upsert(PartnerJob(id: "offmain", name: "Off Main", isEnabled: true, guidelines: "",
                                        steps: []))
        }.value
        await waitUntil { toolbar.statusLabel.stringValue.contains("Off Main") }
        XCTAssertTrue(toolbar.statusLabel.stringValue.contains("Off Main"), toolbar.statusLabel.stringValue)
    }

    func testASessionsWriteOffTheMainActorReloadsTheShelf() async throws {
        let coordinator = makeCoordinator()
        let split = PartnerSplitViewController(controller: coordinator.controller)
        split.loadViewIfNeeded()
        let store = self.store!
        try await Task.detached {
            try store.upsert(PartnerStore.SessionRecord(id: "offmain", title: "Off Main", directory: "/a",
                                                        openedAt: Date(), closedAt: Date()))
        }.value
        await waitUntil { split.shelf.rows.contains { $0.id == "offmain" } }
        XCTAssertTrue(split.shelf.rows.contains { $0.id == "offmain" })
    }

    // MARK: - References

    private func file(_ name: String, permissions: Int = 0o644) throws -> String {
        let url = directory.appendingPathComponent(name)
        try Data("x".utf8).write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
        return url.path
    }

    private func action(_ reference: [String: String]) -> PartnerCoordinator.ReferenceAction {
        PartnerCoordinator.referenceAction(reference)
    }

    private func isIgnored(_ action: PartnerCoordinator.ReferenceAction) -> Bool {
        if case .ignore = action { return true }
        return false
    }

    func testWebURLsOpen() {
        XCTAssertEqual(action(["url": "https://example.com/a"]), .open(URL(string: "https://example.com/a")!))
        XCTAssertEqual(action(["url": "http://example.com"]), .open(URL(string: "http://example.com")!))
        XCTAssertEqual(action(["url": "HTTPS://example.com/b"]), .open(URL(string: "HTTPS://example.com/b")!))
    }

    func testOtherSchemesAreIgnored() {
        for text in ["file:///etc/passwd", "javascript:alert(1)", "x-kitchen-evil://run", "ssh://host",
                     "https:", "not a url"] {
            XCTAssertTrue(isIgnored(action(["url": text])), text)
        }
        XCTAssertTrue(isIgnored(action(["commit": "abc"])))
        XCTAssertTrue(isIgnored(action([:])))
    }

    func testAPlainRegularFileOpens() throws {
        let path = try file("notes.txt")
        XCTAssertEqual(action(["path": path]), .open(URL(fileURLWithPath: path).resolvingSymlinksInPath()))
        // A bad url beside a good path does not taint the path.
        XCTAssertEqual(action(["url": "file:///etc/passwd", "path": path]),
                       .open(URL(fileURLWithPath: path).resolvingSymlinksInPath()))
    }

    func testLaunchingTypesAreRevealedNotOpened() throws {
        for name in ["run.command", "setup.pkg", "x.tool", "x.terminal", "x.workflow", "x.scpt", "x.sh",
                     "X.COMMAND", "go.fileloc", "site.webloc", "lib.jar", "disk.dmg", "Xcode.xip", "tool.py",
                     "x.rb", "x.js", "x.inetloc", "x.mobileconfig", "x.configprofile", "x.action", "x.plist",
                     "noextension", "x.unknownext"] {
            let path = try file(name)
            XCTAssertEqual(action(["path": path]), .reveal(URL(fileURLWithPath: path)), name)
        }
    }

    func testDocumentTypesOpen() throws {
        for name in ["notes.md", "shot.png", "paper.pdf", "Main.swift", "data.json", "photo.JPG"] {
            let path = try file(name)
            XCTAssertEqual(action(["path": path]), .open(URL(fileURLWithPath: path).resolvingSymlinksInPath()),
                           name)
        }
    }

    func testAnExecutableFileIsRevealed() throws {
        let path = try file("innocent.txt", permissions: 0o755)
        XCTAssertEqual(action(["path": path]), .reveal(URL(fileURLWithPath: path)))
        let userOnly = try file("userx.md", permissions: 0o700)
        XCTAssertEqual(action(["path": userOnly]), .reveal(URL(fileURLWithPath: userOnly)))
    }

    func testBundlesAndDirectoriesAreRevealed() throws {
        let app = directory.appendingPathComponent("Evil.app")
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents"),
                                                withIntermediateDirectories: true)
        XCTAssertEqual(action(["path": app.path]), .reveal(URL(fileURLWithPath: app.path)))
        let folder = directory.appendingPathComponent("folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        XCTAssertEqual(action(["path": folder.path]), .reveal(URL(fileURLWithPath: folder.path)))
    }

    func testASymlinkIsJudgedByItsTarget() throws {
        let target = try file("payload.command")
        let link = directory.appendingPathComponent("readme.txt")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: target)
        XCTAssertEqual(action(["path": link.path]), .reveal(URL(fileURLWithPath: link.path)))
    }

    func testRelativeAndMissingPathsAreIgnored() {
        XCTAssertTrue(isIgnored(action(["path": "relative/file.txt"])))
        XCTAssertTrue(isIgnored(action(["path": directory.appendingPathComponent("gone.txt").path])))
        XCTAssertTrue(isIgnored(action(["path": ""])))
    }
}
