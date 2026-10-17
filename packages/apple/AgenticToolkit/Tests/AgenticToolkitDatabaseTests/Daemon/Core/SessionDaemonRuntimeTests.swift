import XCTest
import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// The runtime's steps over a temporary root, with the hook installer pointed at
/// a `settings.json` inside it — never the real Claude Code settings.
final class SessionDaemonRuntimeTests: XCTestCase {

    private struct NoSink: SessionEventSink {
        func broadcast(eventType: String, payload: Data, sessionId: String?) {}
        func broadcastSessionStatus(sessionId: String, status: SessionStatus) {}
    }

    private struct Undecodable: Error {}

    private var root: URL!

    override func setUpWithError() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("session-runtime-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeRuntime() throws -> SessionDaemonRuntime {
        let configuration = SessionDaemonConfiguration.test(port: 0, root: root)
        let dispatcher = root.appendingPathComponent("dispatch.sh")
        try "#!/bin/sh\n# claudehelpers-statusline-dispatch 1\n"
            .write(to: dispatcher, atomically: true, encoding: .utf8)
        var hook = configuration.hook
        hook.bundledDispatcher = dispatcher
        let installer = ClaudeHookInstaller(configuration: hook, helperIsExecutable: { _ in true })
        return SessionDaemonRuntime(
            configuration: configuration,
            behavior: .init(sink: NoSink(), decode: { _ in throw Undecodable() }),
            secretStore: InMemorySecretStore(),
            hookInstaller: installer
        )
    }

    func testOpenPhaseALeavesTheDatabaseNotReady() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        XCTAssertFalse(runtime.database.isReady)
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtime.configuration.databasePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtime.configuration.spoolPath))
        await runtime.shutdown()
    }

    func testMigrateMakesTheDatabaseReady() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        try runtime.migrate()
        XCTAssertTrue(runtime.database.isReady)
        try runtime.migrate()  // idempotent once it has succeeded
        await runtime.shutdown()
    }

    func testServicesAreReachableAfterOpen() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        let services = runtime.services(
            .init(
                endpointIndex: ["GET /health"],
                startupDurationMs: { nil },
                memorySample: { nil },
                parseQuarantinedEvent: { _ in .lostEvent },
                buildHookEvent: { _, _ in nil },
                runImport: { _ in throw Undecodable() }
            ),
            startTime: Date()
        )
        XCTAssertEqual(services.daemonVersion, "0.0.0-test")
        XCTAssertEqual(services.endpointIndex, ["GET /health"])
        XCTAssertNotNil(services.spool)
        XCTAssertFalse(services.database.isReady)
        await runtime.shutdown()
    }

    func testStartIngressInstallsHooksIntoTheTempSettings() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        await runtime.startIngress()
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: runtime.configuration.hook.settingsURL.path)
                || runtime.hookDisabled
        )
        await runtime.shutdown()
    }

    func testShutdownIsIdempotent() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        try runtime.migrate()
        await runtime.startDrainer()
        await runtime.shutdown()
        await runtime.shutdown()
    }

    func testShutdownBeforeOpenIsHarmless() async throws {
        let runtime = try makeRuntime()
        await runtime.shutdown()
    }
}
