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

    private func makeCoordinator(quitLimit: Duration = PartnerCoordinator.quitTurnLimit) -> PartnerCoordinator {
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
                    settings: settings, pid: 4242, isPIDAlive: { _ in false })
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
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(coordinator.controller.state, .stopped, "no endpoint yet, so no start")
        endpointUp()
        await waitUntil { !self.log.all.isEmpty }
        XCTAssertEqual(log.all.count, 1)
        XCTAssertNotEqual(coordinator.controller.state, .stopped)
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
                     "X.COMMAND", "go.fileloc", "site.webloc"] {
            let path = try file(name)
            XCTAssertEqual(action(["path": path]), .reveal(URL(fileURLWithPath: path)), name)
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
