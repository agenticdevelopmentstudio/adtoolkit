import XCTest
import Foundation
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitDatabase

/// Exercises both `DaemonSessionSummarizer` paths through their injectable seams —
/// the plugin path via `PluginRuntime`/`SecretStoring`, the zero-config default via
/// `CLIRunner`. No real `.aiplugin` bundle, network, `claude -p` subprocess, or
/// Keychain is touched, and the DB is in-memory, so the suite is fully hermetic.
/// Asserts the daemon resolves config from the right stores, hands the plugin a
/// correctly-bounded context, picks the right path, and maps failures.
final class DaemonSummarizerPluginTests: XCTestCase {

    private var database: DaemonDatabase!
    /// Shared with `selectConfig`'s registry seeding so a secret it
    /// stores config-keyed is visible to the same instance passed into
    /// `DaemonSessionSummarizer.summarize(secretStore:)` — the daemon's real
    /// wiring is exactly this: one Keychain-backed store for both the write (host
    /// push) and read (summarizer) sides.
    private var secretStore: InMemorySecretStore!

    private let pluginId = "test.fake"

    /// Fixed so the seeded events (and any timestamp-derived prompt content) are
    /// deterministic instead of depending on wall-clock at run time.
    private static let baseTimestamp = "2026-01-01T00:00:00.000Z"
    private static let nextTimestamp = "2026-01-01T00:00:01.000Z"

    override func setUpWithError() throws {
        // In-memory DB: no temp file to create, name, or clean up, and no on-disk
        // WAL artifacts — each test gets a pristine schema.
        database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        secretStore = InMemorySecretStore()
        try seedSession()
    }

    override func tearDownWithError() throws {
        database = nil
        secretStore = nil
    }

    /// The shared `selectProviderConfig` (AIPluginTestSupport) bound to this
    /// suite's database/secret store; its `plugin`/`template` defaults match
    /// `makeRuntime`'s canned "test.fake" descriptor.
    private func selectConfig(
        _ id: UUID, model: String,
        values: [String: String] = [:], secrets: [String: String] = [:]
    ) {
        selectProviderConfig(
            id, model: model, values: values, secrets: secrets,
            database: database, secretStore: secretStore
        )
    }

    // MARK: - Plugin path

    func testPluginPathResolvesConfigAndReturnsSummary() async throws {
        // baseURL (plain) lives in the settings table, config-keyed; the apiKey
        // (secret) only in the injected secret store — never the DB.
        let configId = UUID()
        selectConfig(
            configId, model: "",
            values: ["baseURL": "https://api.example/v1"],
            secrets: ["apiKey": "sk-secret-123"]
        )

        let captured = CapturingPlugin.Captured()
        let runtime = makeRuntime(
            captured: captured,
            events: [.textDelta("Fixing the "), .textDelta("sessions window"), .end(stopReason: nil)]
        )

        let summary = try await DaemonSessionSummarizer.summarize(
            sessionId: "s", database: database, runtime: runtime,
            cliRunner: failingCLIRunner(), secretStore: secretStore
        )

        XCTAssertEqual(summary, "Fixing the sessions window")

        let context = try XCTUnwrap(captured.context)
        // A title is short — the daemon must bound the request tightly.
        XCTAssertEqual(context.maxTokens, 64)
        XCTAssertEqual(context.systemPrompt, DaemonSessionSummarizer.systemPrompt(database))
        // No model chosen → the descriptor's default.
        XCTAssertEqual(context.model, "fake-small")
        XCTAssertEqual(context.config.model, "fake-small")
        // Secret resolved from the secret store; plain field from the DB.
        XCTAssertEqual(context.config.apiKey, "sk-secret-123")
        XCTAssertEqual(context.config.baseURL, "https://api.example/v1")
        // The prompt is delivered as a single user message.
        XCTAssertEqual(context.messages.count, 1)
        XCTAssertEqual(context.messages.first?.role, .user)
        XCTAssertTrue(context.messages.first?.content.contains("Project:") ?? false)
    }

    /// Mirrors the real `ClaudeAPI` plugin's descriptor shape (only `apiKey` is a
    /// declared field — `authMode`/`baseURL` are template-level seed values, see
    /// `AIPluginDescriptor.ProviderTemplate.defaultValues` and `ClaudeAPI/descriptor.json`).
    /// The host resolves those two values and forwards them inside the config's
    /// non-secret `values`, so they're stored config-keyed
    /// (`AIProviderConfigKeys.fieldKey(config:field:)`) and recorded in the config's
    /// fields ledger. `summarizeViaPlugin` rebuilds the config bag by reading that
    /// ledger — not by re-listing descriptor fields — so both survive; without the
    /// host forwarding them a Claude Max (token) config would fall back to the
    /// plugin's `x-api-key` header path instead of bearer-oauth. This is the
    /// daemon-side counterpart to `PluginRequestTests.claudeAPIBearerOAuth`.
    func testPluginPathForwardsAuthModeAndBaseURLWhenNotDescriptorFields() async throws {
        let configId = UUID()
        selectConfig(
            configId, model: "",
            values: ["authMode": "bearer-oauth", "baseURL": "https://api.anthropic.com/v1"],
            secrets: ["apiKey": "sess-token-abc"]
        )

        let captured = CapturingPlugin.Captured()
        let plugin = CapturingPlugin(captured: captured)
        // Only `apiKey` declared — no `baseURL`/`authMode` field — matching the real
        // ClaudeAPI descriptor, so the fix under test can't be masked by a fake
        // descriptor that (unlike the real one) declares them as ordinary fields.
        let descriptor = AIPluginDescriptor(
            identifier: pluginId,
            displayName: "Test Fake (Claude-shaped)",
            version: "1.0",
            models: ["fake-small"],
            defaultModel: "fake-small",
            fields: [AIPluginDescriptor.Field(key: "apiKey", label: "API Key", kind: .secret)]
        )
        let runtime = DaemonSessionSummarizer.PluginRuntime(
            load: { _, _ in (plugin, descriptor) },
            run: { _, _ in
                AsyncThrowingStream { continuation in
                    continuation.yield(.textDelta("ok"))
                    continuation.finish()
                }
            }
        )

        _ = try await DaemonSessionSummarizer.summarize(
            sessionId: "s", database: database, runtime: runtime,
            cliRunner: failingCLIRunner(), secretStore: secretStore
        )

        let context = try XCTUnwrap(captured.context)
        XCTAssertEqual(context.config["authMode"], "bearer-oauth")
        XCTAssertEqual(context.config.baseURL, "https://api.anthropic.com/v1")
        XCTAssertEqual(context.config.apiKey, "sess-token-abc")
    }

    /// Generalizes the previous test: the daemon must thread through EVERY non-secret
    /// value the host stored, not just the baseURL/authMode it used to special-case.
    /// A template default beyond those two (e.g. an `apiVersion` header seed) must
    /// reach `buildRequest` on the daemon summarize path, exactly as in interactive
    /// chat. Old descriptor-fields-only reconstruction dropped it silently.
    func testPluginPathForwardsArbitraryTemplateDefaultBeyondBaseURLAndAuthMode() async throws {
        let configId = UUID()
        selectConfig(
            configId, model: "",
            values: ["baseURL": "https://api.example/v1", "apiVersion": "2026-01-01"],
            secrets: ["apiKey": "k"]
        )

        let captured = CapturingPlugin.Captured()
        let plugin = CapturingPlugin(captured: captured)
        // `apiVersion` is deliberately NOT a declared descriptor field, so the fix
        // can't be masked by the descriptor happening to list it.
        let descriptor = AIPluginDescriptor(
            identifier: pluginId,
            displayName: "Test Fake",
            version: "1.0",
            models: ["fake-small"],
            defaultModel: "fake-small",
            fields: [AIPluginDescriptor.Field(key: "apiKey", label: "API Key", kind: .secret)]
        )
        let runtime = DaemonSessionSummarizer.PluginRuntime(
            load: { _, _ in (plugin, descriptor) },
            run: { _, _ in
                AsyncThrowingStream { continuation in
                    continuation.yield(.textDelta("ok"))
                    continuation.finish()
                }
            }
        )

        _ = try await DaemonSessionSummarizer.summarize(
            sessionId: "s", database: database, runtime: runtime,
            cliRunner: failingCLIRunner(), secretStore: secretStore
        )

        let context = try XCTUnwrap(captured.context)
        XCTAssertEqual(context.config["apiVersion"], "2026-01-01")
        XCTAssertEqual(context.config.baseURL, "https://api.example/v1")
    }

    func testPluginPathHonorsExplicitModelSetting() async throws {
        let configId = UUID()
        selectConfig(configId, model: "fake-large")

        let captured = CapturingPlugin.Captured()
        let runtime = makeRuntime(captured: captured, events: [.textDelta("ok"), .end(stopReason: nil)])

        _ = try await DaemonSessionSummarizer.summarize(
            sessionId: "s", database: database, runtime: runtime,
            cliRunner: failingCLIRunner(), secretStore: secretStore
        )

        let context = try XCTUnwrap(captured.context)
        XCTAssertEqual(context.model, "fake-large")
        XCTAssertEqual(context.config.model, "fake-large")
    }

    func testPluginPathEmptyReplyThrows() async throws {
        let configId = UUID()
        selectConfig(configId, model: "")

        // Stream ends with no text → emptyReply, never a blank summary.
        let runtime = makeRuntime(captured: CapturingPlugin.Captured(), events: [.end(stopReason: nil)])

        await assertThrows(.emptyReply) {
            _ = try await DaemonSessionSummarizer.summarize(
                sessionId: "s", database: database, runtime: runtime,
                cliRunner: failingCLIRunner(), secretStore: secretStore
            )
        }
    }

    func testPluginPathTransportErrorMapsToProviderError() async throws {
        let configId = UUID()
        selectConfig(configId, model: "")

        let runtime = makeRuntime(captured: CapturingPlugin.Captured(), events: [], error: FakeError.boom)

        // The underlying transport error's message must reach the provider error so a
        // failure is diagnosable, not flattened to a generic string.
        await assertThrows(.providerError(""), messageContains: "boom") {
            _ = try await DaemonSessionSummarizer.summarize(
                sessionId: "s", database: database, runtime: runtime,
                cliRunner: failingCLIRunner(), secretStore: secretStore
            )
        }
    }

    // MARK: - Zero-config CLI default path

    func testEmptyPluginIdUsesLegacyCLIPathNotPlugin() async throws {
        // No configuration selected → the zero-config CLI default. The plugin
        // runtime must never be touched (its `load` XCTFails if it is), and the
        // injected runner stands in for `claude -p` so no subprocess or network
        // call happens.
        let captured = CLICaptured()
        let summary = try await DaemonSessionSummarizer.summarize(
            sessionId: "s", database: database, runtime: failingPluginRuntime(),
            cliRunner: captured.runner(returning: "Refactoring the parser"),
            secretStore: InMemorySecretStore()
        )

        XCTAssertEqual(summary, "Refactoring the parser")
        // No selected configuration → the daemon's Haiku default, with the session
        // system prompt and a prompt built from the seeded session.
        XCTAssertEqual(captured.model, "haiku")
        XCTAssertEqual(captured.systemPrompt, DaemonSessionSummarizer.systemPrompt(database))
        XCTAssertTrue(captured.prompt?.contains("Project:") ?? false)
    }

    /// Before the config registry, the global `ai_model` setting steered the
    /// zero-config CLI path (see `testLegacyCLIPathHonorsExplicitModel` prior to
    /// this commit). The registry migration retires that wiring — model choice
    /// now lives per-configuration (`testPluginPathHonorsExplicitModelSetting`),
    /// and the CLI default always uses Haiku. Guards against a stale `ai_model`
    /// row (left by a pre-registry daemon version) leaking into the CLI default.
    func testLegacyGlobalAiModelSettingIsIgnoredByCLIDefaultPath() async throws {
        try database.setSetting("ai_model", "opus")

        let captured = CLICaptured()
        _ = try await DaemonSessionSummarizer.summarize(
            sessionId: "s", database: database, runtime: failingPluginRuntime(),
            cliRunner: captured.runner(returning: "ok"), secretStore: InMemorySecretStore()
        )

        XCTAssertEqual(captured.model, "haiku")
    }

    func testLegacyCLIPathEmptyReplyMapsToEmptyReply() async throws {
        let cliRunner: DaemonSessionSummarizer.CLIRunner = { _, _, _, _ in
            throw ClaudeCLI.CLIError.emptyReply
        }
        await assertThrows(.emptyReply) {
            _ = try await DaemonSessionSummarizer.summarize(
                sessionId: "s", database: database, runtime: failingPluginRuntime(),
                cliRunner: cliRunner, secretStore: InMemorySecretStore()
            )
        }
    }

    func testLegacyCLIPathBinaryNotFoundMapsToClaudeNotFound() async throws {
        let cliRunner: DaemonSessionSummarizer.CLIRunner = { _, _, _, _ in
            throw ClaudeCLI.CLIError.binaryNotFound
        }
        await assertThrows(.claudeNotFound) {
            _ = try await DaemonSessionSummarizer.summarize(
                sessionId: "s", database: database, runtime: failingPluginRuntime(),
                cliRunner: cliRunner, secretStore: InMemorySecretStore()
            )
        }
    }

    func testLegacyCLIPathNonZeroExitMapsToProviderError() async throws {
        let cliRunner: DaemonSessionSummarizer.CLIRunner = { _, _, _, _ in
            throw ClaudeCLI.CLIError.nonZeroExit(code: 2, stderr: "model unavailable")
        }
        await assertThrows(.providerError(""), messageContains: "model unavailable") {
            _ = try await DaemonSessionSummarizer.summarize(
                sessionId: "s", database: database, runtime: failingPluginRuntime(),
                cliRunner: cliRunner, secretStore: InMemorySecretStore()
            )
        }
    }

    // MARK: - Search paths

    func testPluginSearchPathsIncludeHomeAgenticplugins() {
        let paths = DaemonSessionSummarizer.pluginSearchPaths()
        let home = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".agenticplugins")
        XCTAssertTrue(
            paths.contains(home),
            "search paths must include ~/.agenticplugins (where plugins install); got \(paths)"
        )
        // Every entry is a real file URL (not a string accidentally treated as a path).
        XCTAssertTrue(paths.allSatisfy { $0.isFileURL }, "all search paths must be file URLs")
    }

    // MARK: - Helpers

    private func seedSession() throws {
        try database.ingestEvent(
            eventType: "SessionStart",
            timestamp: Self.baseTimestamp,
            hookData: ["session_id": "s", "cwd": "/tmp/proj", "model": "sonnet", "pid": 0, "term_program": "Test"]
        )
        try database.ingestEvent(
            eventType: "PreToolUse",
            timestamp: Self.nextTimestamp,
            hookData: ["session_id": "s", "cwd": "/tmp/proj", "tool_name": "Read", "tool_input": [String: Any]()]
        )
    }

    /// A plugin runtime that fails the test if it is ever exercised — used on the
    /// CLI-default path to prove no plugin is loaded.
    private func failingPluginRuntime() -> DaemonSessionSummarizer.PluginRuntime {
        DaemonSessionSummarizer.PluginRuntime(
            load: { _, _ in XCTFail("CLI-default path must not load a plugin"); throw FakeError.boom },
            run: { _, _ in AsyncThrowingStream { $0.finish() } }
        )
    }

    /// A CLI runner that fails the test if it is ever called — used on the plugin
    /// path to prove the legacy subprocess is not invoked.
    private func failingCLIRunner() -> DaemonSessionSummarizer.CLIRunner {
        { _, _, _, _ in XCTFail("plugin path must not invoke the CLI runner"); return "" }
    }

    /// Asserts the block throws a `SummarizeError` matching `expected` by case. When
    /// `messageContains` is set, also asserts the thrown error's description carries
    /// that substring — so error mapping is checked, not just the case tag.
    private func assertThrows(
        _ expected: DaemonSessionSummarizer.SummarizeError,
        messageContains needle: String? = nil,
        _ block: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await block()
            XCTFail("expected \(expected) to be thrown", file: file, line: line)
        } catch let error as DaemonSessionSummarizer.SummarizeError {
            XCTAssertTrue(error.sameCase(as: expected), "got \(error), expected \(expected)", file: file, line: line)
            if let needle {
                let desc = error.errorDescription ?? ""
                XCTAssertTrue(
                    desc.contains(needle),
                    "error description '\(desc)' did not contain '\(needle)'", file: file, line: line
                )
            }
        } catch {
            XCTFail("unexpected error type: \(error)", file: file, line: line)
        }
    }
}

// MARK: - Fakes
//
// `FakeError`, `CapturingPlugin`, and `NoopDecoder` moved (unchanged) to
// `Support/AIPluginTestSupport.swift` so `DaemonAIGuardChokepointTests` can share them.

/// Records the arguments the daemon passed to the injected CLI runner so tests can
/// assert model selection, system prompt, and prompt content without a subprocess.
private final class CLICaptured: @unchecked Sendable {
    private let lock = NSLock()
    private var storedPrompt: String?
    private var storedSystemPrompt: String?
    private var storedModel: String?

    var prompt: String? { lock.withLock { storedPrompt } }
    var systemPrompt: String? { lock.withLock { storedSystemPrompt } }
    var model: String? { lock.withLock { storedModel } }

    func runner(returning reply: String) -> DaemonSessionSummarizer.CLIRunner {
        { [self] prompt, systemPrompt, model, _ in
            lock.withLock {
                storedPrompt = prompt
                storedSystemPrompt = systemPrompt
                storedModel = model
            }
            return reply
        }
    }
}

private extension DaemonSessionSummarizer.SummarizeError {
    /// Case-only equality — providerError carries a variable message.
    func sameCase(as other: DaemonSessionSummarizer.SummarizeError) -> Bool {
        switch (self, other) {
        case (.sessionNotFound, .sessionNotFound), (.noEvents, .noEvents),
             (.claudeNotFound, .claudeNotFound),
             (.providerError, .providerError), (.emptyReply, .emptyReply):
            return true
        default:
            return false
        }
    }
}
