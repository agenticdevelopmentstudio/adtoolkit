import XCTest
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitMacOS

/// The LLM provider registry reaching the daemon through `setAIPreferences`.
@MainActor
final class StenographerAIConfigPushTests: XCTestCase {

    override func setUp() async throws {
        StenographerAIConfigPush.stopObserving()
        UserSettings.aiProviderConfigurations.value = []
        UserSettings.selectedAIProviderConfigurationId.value = ""
    }

    override func tearDown() async throws {
        StenographerAIConfigPush.stopObserving()
        UserSettings.aiProviderConfigurations.value = []
        UserSettings.selectedAIProviderConfigurationId.value = ""
    }

    private func config(_ name: String) -> AIProviderConfiguration {
        AIProviderConfiguration(name: name, pluginIdentifier: "p.openai-compatible", templateId: "custom")
    }

    private func resolved(_ candidate: AIProviderConfiguration) -> ResolvedProviderConfig {
        ResolvedProviderConfig(
            id: candidate.id, name: candidate.name, pluginIdentifier: candidate.pluginIdentifier,
            templateId: candidate.templateId, model: "m", values: ["baseURL": "h"],
            secrets: ["apiKey": "k-\(candidate.name)"])
    }

    // MARK: - Payload

    func testPayloadCarriesBothConfigsAndTheSelection() {
        let first = config("A"), second = config("B")
        let sync = StenographerAIConfigPush.makeSync(
            configurations: [first, second], selectedConfigId: second.id.uuidString, enabled: true,
            resolve: { resolved($0) })
        XCTAssertTrue(sync.enabled)
        XCTAssertEqual(sync.selectedConfigId, second.id)
        XCTAssertEqual(sync.configs.map(\.id), [first.id, second.id])
        XCTAssertEqual(sync.configs.map { $0.secrets["apiKey"] }, ["k-A", "k-B"])
    }

    func testAnUnresolvableConfigIsSkipped() {
        let kept = config("A"), ghost = config("Ghost")
        let sync = StenographerAIConfigPush.makeSync(
            configurations: [kept, ghost], selectedConfigId: "", enabled: true,
            resolve: { $0.id == ghost.id ? nil : resolved($0) })
        XCTAssertEqual(sync.configs.map(\.id), [kept.id])
        XCTAssertNil(sync.selectedConfigId)
    }

    func testWireConfigSplitsSecretsFromValuesAndLeavesTheModelOut() {
        let source = config("A")
        let resolution = AIProviderResolver.Resolved(
            pluginIdentifier: "p.openai-compatible", model: "gpt",
            values: ["model": "gpt", "baseURL": "h", "apiKey": "k"],
            fields: [
                .init(key: "baseURL", label: "URL", kind: .text),
                .init(key: "apiKey", label: "Key", kind: .secret)])
        let wire = StenographerAIConfigPush.wireConfig(source, resolved: resolution)
        XCTAssertEqual(wire.model, "gpt")
        XCTAssertEqual(wire.values, ["baseURL": "h"])
        XCTAssertEqual(wire.secrets, ["apiKey": "k"])
    }

    func testAStoredSecretThatCannotBeReadIsReported() {
        let source = config("A")
        let sync = AIProviderConfigSync(
            enabled: true, selectedConfigId: source.id,
            configs: [ResolvedProviderConfig(
                id: source.id, name: "A", pluginIdentifier: "p", templateId: "t", model: "m",
                values: [:], secrets: ["apiKey": ""])])
        let key = AIProviderConfigKeys.fieldKey(config: source.id, field: "apiKey")
        XCTAssertEqual(
            StenographerAIConfigPush.unreadableSecretKeys(in: sync, exists: { $0 == key }, read: { _ in nil }), [key])
        XCTAssertEqual(
            StenographerAIConfigPush.unreadableSecretKeys(in: sync, exists: { _ in true }, read: { _ in "" }), [])
        XCTAssertEqual(
            StenographerAIConfigPush.unreadableSecretKeys(in: sync, exists: { _ in false }, read: { _ in nil }), [])
    }

    // MARK: - Pushing

    func testStartupPushesTheCurrentRegistryOnce() async throws {
        let daemon = StubDaemonService()
        StenographerAIConfigPush.startObserving(service: daemon, pluginManager: AIPluginManager(searchPaths: []))
        await StenographerAIConfigPush.awaitPendingPush()
        XCTAssertEqual(daemon.aiSyncs.count, 1)
        let sync = try XCTUnwrap(daemon.aiSyncs.first)
        XCTAssertTrue(sync.enabled)
        XCTAssertNil(sync.selectedConfigId)
    }

    func testANilManagerPushesNothingSoTheRegistryIsNotDeleted() async {
        let daemon = StubDaemonService()
        StenographerAIConfigPush.startObserving(service: daemon, pluginManager: nil)
        await StenographerAIConfigPush.awaitPendingPush()
        XCTAssertTrue(daemon.aiSyncs.isEmpty)
    }

    func testASelectionChangePushesOnce() async {
        let daemon = StubDaemonService()
        StenographerAIConfigPush.startObserving(service: daemon, pluginManager: AIPluginManager(searchPaths: []))
        await StenographerAIConfigPush.awaitPendingPush()
        let chosen = UUID()
        UserSettings.selectedAIProviderConfigurationId.value = chosen.uuidString
        await StenographerAIConfigPush.awaitPendingPush()
        XCTAssertEqual(daemon.aiSyncs.count, 2)
        XCTAssertEqual(daemon.aiSyncs.last?.selectedConfigId, chosen)
    }

    func testADaemonReconnectPushesTheSnapshotAgain() async {
        let daemon = StubDaemonService()
        StenographerAIConfigPush.startObserving(service: daemon, pluginManager: AIPluginManager(searchPaths: []))
        await StenographerAIConfigPush.awaitPendingPush()
        daemon.fireReconnect()
        try? await Task.sleep(nanoseconds: 100_000_000)
        await StenographerAIConfigPush.awaitPendingPush()
        XCTAssertEqual(daemon.aiSyncs.count, 2)
    }

    func testAFailedPushIsRetried() async {
        let daemon = StubDaemonService()
        daemon.aiPushResult = false
        StenographerAIConfigPush.startObserving(service: daemon, pluginManager: AIPluginManager(searchPaths: []))
        await StenographerAIConfigPush.awaitPendingPush()
        XCTAssertGreaterThan(daemon.aiSyncs.count, 1, "an undelivered snapshot must be attempted again")
    }
}
