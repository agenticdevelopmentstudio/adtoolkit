import XCTest
import Foundation
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitDatabase

private struct FixedMemory: SystemMemoryMonitoring {
    let physicalRAM: UInt64
    let pressureLevel: MemoryPressureLevel
}

/// The toolkit guard flowing through the `complete(feature:)` overload:
/// refusals land in `ai_interactions` as guard outcomes with the reason, never
/// reach a transport, and never cascade into `claude -p`.
final class DaemonAIGuardChokepointTests: XCTestCase {
    private var database: DaemonDatabase!
    private var secretStore: InMemorySecretStore!

    private static let ram: UInt64 = 64_000_000_000
    private static let tags = Data("""
        {"models":[{"name":"big:latest","size":51000000000},
                   {"name":"small:latest","size":4900000000}]}
        """.utf8)

    override func setUpWithError() throws {
        database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        secretStore = InMemorySecretStore()
    }

    override func tearDownWithError() throws {
        database = nil
        secretStore = nil
    }

    /// The shared registry seeding, adapted to this suite's shape: the guard only
    /// cares about the model and whether `baseURL` is loopback.
    private func selectConfig(_ id: UUID, model: String, baseURL: String) {
        selectProviderConfig(
            id, model: model, values: ["baseURL": baseURL],
            database: database, secretStore: secretStore
        )
    }

    private func makeGuard(pressure: MemoryPressureLevel) -> LocalInferenceGuard {
        LocalInferenceGuard(
            catalog: LocalModelCatalog(fetcher: { _ in Self.tags }),
            memory: FixedMemory(physicalRAM: Self.ram, pressureLevel: pressure))
    }

    private func forbiddenRuntime() -> DaemonAIChat.PluginRuntime {
        DaemonAIChat.PluginRuntime(
            load: { _, _ in
                XCTFail("transport must not run for a refused request")
                throw URLError(.badURL)
            },
            run: { _, _ in AsyncThrowingStream { $0.finish() } }
        )
    }

    private let forbiddenCLI: DaemonAIChat.CLIRunner = { _, _, _, _ in
        XCTFail("a guard refusal must never cascade into claude -p")
        return ""
    }

    func testBlockedModelRecordsGuardBlockedRow() async throws {
        selectConfig(UUID(), model: "big:latest", baseURL: "http://localhost:11434/v1")
        do {
            _ = try await DaemonAIChat.complete(
                feature: .summarize, sessionId: "s1",
                systemPrompt: "sys", userPrompt: "user", maxTokens: 64,
                database: database, runtime: forbiddenRuntime(), cliRunner: forbiddenCLI,
                secretStore: secretStore, inferenceGuard: makeGuard(pressure: .normal))
            XCTFail("expected AIGuardError.blocked")
        } catch let error as AIGuardError {
            guard case .blocked(let reason) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(reason.contains("block threshold"))
        }
        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].outcome, "guard_blocked")
        XCTAssertTrue(rows[0].error.contains("block threshold"))
        XCTAssertEqual(rows[0].model, "big:latest")
    }

    func testPressureRecordsGuardDeferredRow() async throws {
        selectConfig(UUID(), model: "small:latest", baseURL: "http://localhost:11434/v1")
        do {
            _ = try await DaemonAIChat.complete(
                feature: .summarize, sessionId: "s1",
                systemPrompt: "sys", userPrompt: "user", maxTokens: 64,
                database: database, runtime: forbiddenRuntime(), cliRunner: forbiddenCLI,
                secretStore: secretStore, inferenceGuard: makeGuard(pressure: .warning))
            XCTFail("expected AIGuardError.deferred")
        } catch let error as AIGuardError {
            guard case .deferred = error else { return XCTFail("\(error)") }
        }
        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.first?.outcome, "guard_deferred")
    }

    func testAllowedLocalModelRecordsOkRow() async throws {
        selectConfig(UUID(), model: "small:latest", baseURL: "http://localhost:11434/v1")
        let runtime = makeRuntime(
            captured: CapturingPlugin.Captured(),
            events: [.textDelta("Fixing the sessions window"), .end(stopReason: nil)]
        )
        let reply = try await DaemonAIChat.complete(
            feature: .summarize, sessionId: "s1",
            systemPrompt: "sys", userPrompt: "user", maxTokens: 64,
            database: database, runtime: runtime, cliRunner: forbiddenCLI,
            secretStore: secretStore, inferenceGuard: makeGuard(pressure: .normal))
        XCTAssertEqual(reply, "Fixing the sessions window")
        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.first?.outcome, "ok")
    }

    func testRemoteProviderBypassesGuardEndToEnd() async throws {
        selectConfig(UUID(), model: "big:latest", baseURL: "https://api.example/v1")
        let runtime = makeRuntime(
            captured: CapturingPlugin.Captured(),
            events: [.textDelta("remote ok"), .end(stopReason: nil)]
        )
        let reply = try await DaemonAIChat.complete(
            feature: .summarize, sessionId: "s1",
            systemPrompt: "sys", userPrompt: "user", maxTokens: 64,
            database: database, runtime: runtime, cliRunner: forbiddenCLI,
            secretStore: secretStore, inferenceGuard: makeGuard(pressure: .critical))
        XCTAssertEqual(reply, "remote ok")
        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.first?.outcome, "ok")
    }
}
