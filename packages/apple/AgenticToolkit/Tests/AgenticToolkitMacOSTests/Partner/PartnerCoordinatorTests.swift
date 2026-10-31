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

    private func makeCoordinator() -> PartnerCoordinator {
        let log = log!
        let settings = settings!
        let made = PartnerCoordinator(
            store: store, paths: PartnerPaths(home: directory, token: "kitchen-test"), status: status,
            terminalEnvironment: { [:] }, registerTools: { [unowned self] in registered.append($0) },
            projects: { [] }, commandRegistry: CommandRegistry(), detector: ManualSessionEventDetector(),
            settings: settings,
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

    func testReferenceURL() {
        XCTAssertEqual(PartnerCoordinator.referenceURL(["url": "https://example.com/a"])?.absoluteString,
                       "https://example.com/a")
        XCTAssertEqual(PartnerCoordinator.referenceURL(["path": "/tmp/x.swift"]), URL(fileURLWithPath: "/tmp/x.swift"))
        XCTAssertEqual(PartnerCoordinator.referenceURL(["url": "file:///etc/passwd", "path": "/tmp/y"]),
                       URL(fileURLWithPath: "/tmp/y"))
        XCTAssertNil(PartnerCoordinator.referenceURL(["url": "javascript:alert(1)"]))
        XCTAssertNil(PartnerCoordinator.referenceURL(["commit": "abc"]))
    }
}
