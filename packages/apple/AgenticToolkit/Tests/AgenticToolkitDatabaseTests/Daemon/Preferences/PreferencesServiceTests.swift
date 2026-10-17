import XCTest
import Foundation
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitDatabase

/// `PreferencesService` over a real `DaemonDatabase`, an in-memory secret store and a
/// `ClaudeHookInstaller` aimed at a temporary settings file and drop directory, so no
/// test touches the real `~/.claude/settings.json`.
final class PreferencesServiceTests: XCTestCase {

    private var tmpDir: URL!
    private var db: DaemonDatabase!
    private var dbPath: String!
    private var secrets: InMemorySecretStore!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("prefs-service-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        db = opened.db
        dbPath = opened.path
        secrets = InMemorySecretStore()
    }

    override func tearDownWithError() throws {
        TestDaemonDatabase.remove(path: dbPath)
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeInstaller() throws -> ClaudeHookInstaller {
        let dispatcher = tmpDir.appendingPathComponent("dispatch.sh")
        try "#!/bin/sh\n# claudehelpers-statusline-dispatch 1\n".write(to: dispatcher, atomically: true, encoding: .utf8)
        let configuration = ClaudeHookConfiguration(
            name: "prefs-test",
            marker: "# prefs-test-hook",
            hookBinaryPath: tmpDir.appendingPathComponent("helper").path,
            dropDirectory: tmpDir.appendingPathComponent("drop").path,
            settingsURL: tmpDir.appendingPathComponent("settings.json"),
            bundledDispatcher: dispatcher
        )
        return ClaudeHookInstaller(configuration: configuration, helperIsExecutable: { _ in true })
    }

    private func makeService(summariesDefaultEnabled: Bool = true) throws -> PreferencesService {
        PreferencesService(
            database: db, secretStore: secrets, hookInstaller: try makeInstaller(),
            summariesDefaultEnabled: summariesDefaultEnabled
        )
    }

    private func config(
        _ id: UUID, plugin: String = "test.fake", model: String = "m1",
        values: [String: String] = [:], secrets: [String: String] = [:]
    ) -> ResolvedProviderConfig {
        ResolvedProviderConfig(
            id: id, name: "T", pluginIdentifier: plugin, templateId: "custom",
            model: model, values: values, secrets: secrets
        )
    }

    // MARK: - Provider registry

    func testSyncPersistsTheRegistryIdentityAndModel() throws {
        let service = try makeService()
        let id = UUID()
        service.applyAIProviderSync(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil,
            configs: [config(id, plugin: "test.fake", model: "m1", values: ["baseURL": "http://x"])]
        ))
        XCTAssertEqual(service.storedConfigurations().map(\.id), [id])
        XCTAssertEqual(service.storedConfigurations().first?.pluginIdentifier, "test.fake")
        XCTAssertEqual(try db.setting(for: AIProviderConfigKeys.modelKey(config: id)), "m1")
        XCTAssertEqual(try db.setting(for: AIProviderConfigKeys.fieldKey(config: id, field: "baseURL")), "http://x")
    }

    func testFirstSyncClearsTheLegacySelectedPluginAndItsSecrets() throws {
        let legacyKey = DaemonPluginConfig.fieldKey(plugin: "old.plugin", field: "apiKey")
        try db.setSetting(DaemonPluginConfig.selectedPluginKey, "old.plugin")
        try db.setSetting(DaemonPluginConfig.secretFieldsKey(plugin: "old.plugin"), "apiKey")
        _ = secrets.set("legacy-secret", forKey: legacyKey)

        try makeService().applyAIProviderSync(AIProviderConfigSync(enabled: true, selectedConfigId: nil, configs: []))

        XCTAssertEqual(try db.setting(for: DaemonPluginConfig.selectedPluginKey), "")
        XCTAssertNil(secrets.get(forKey: legacyKey))
        XCTAssertEqual(try db.setting(for: AIProviderConfigKeys.legacyCleanedKey), "true")
    }

    func testSecretFieldsGoToTheSecretStoreNeverTheSettingsTable() throws {
        let service = try makeService()
        let id = UUID()
        service.applyAIProviderSync(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil,
            configs: [config(id, values: ["baseURL": "http://x"], secrets: ["apiKey": "s3cret"])]
        ))
        let key = AIProviderConfigKeys.fieldKey(config: id, field: "apiKey")
        XCTAssertEqual(secrets.get(forKey: key), "s3cret")
        XCTAssertNil(try db.setting(for: key), "a secret value must never reach the settings table")
        XCTAssertEqual(try db.setting(for: AIProviderConfigKeys.secretFieldsKey(config: id)), "apiKey")
    }

    func testRemovingAConfigDeletesItsSecret() throws {
        let service = try makeService()
        let id = UUID()
        service.applyAIProviderSync(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(id, secrets: ["apiKey": "s3cret"])]
        ))
        service.applyAIProviderSync(AIProviderConfigSync(enabled: true, selectedConfigId: nil, configs: []))
        XCTAssertNil(secrets.get(forKey: AIProviderConfigKeys.fieldKey(config: id, field: "apiKey")))
        XCTAssertTrue(service.storedConfigurations().isEmpty)
    }

    func testUndecodableSyncBodyIsRejectedWithoutWriting() throws {
        let service = try makeService()
        XCTAssertFalse(service.applyAIProviderSync(from: Data("not json".utf8)))
        XCTAssertNil(try db.setting(for: AIProviderConfigKeys.configurationsKey))
    }

    // MARK: - Summaries

    func testSummariesReadBackTheConfiguredDefaultWhenNoRowExists() throws {
        XCTAssertTrue(try makeService(summariesDefaultEnabled: true).currentSummary().enabled)
        XCTAssertFalse(try makeService(summariesDefaultEnabled: false).currentSummary().enabled)
        XCTAssertEqual(try makeService(summariesDefaultEnabled: false).currentAIPreferences()["enabled"], "false")
    }

    func testStoredSummariesSwitchBeatsTheDefault() throws {
        let service = try makeService(summariesDefaultEnabled: false)
        XCTAssertTrue(service.setSummary(enabled: true).enabled)
        XCTAssertEqual(try db.setting(for: AIProviderConfigKeys.enabledKey), "true")
    }

    func testSummaryNumbersAreClamped() throws {
        let service = try makeService()
        let response = service.setSummary(maxWords: Int.max)
        XCTAssertEqual(response.maxWords, SummaryLimits.maxWords.upperBound)
    }

    // MARK: - Oversight

    func testOversightWritesAreClampedAndReadBack() throws {
        let service = try makeService()
        let response = service.setOversight(enabled: true, contextThresholdPct: 500, llmEnabled: false)
        XCTAssertTrue(response.enabled)
        XCTAssertEqual(response.contextThresholdPct, 100)
        XCTAssertFalse(response.llmEnabled)
    }

    // MARK: - Tracking

    func testTrackingInstallsAndUninstallsThroughTheHookInstaller() throws {
        let installer = try makeInstaller()
        let service = PreferencesService(
            database: db, secretStore: secrets, hookInstaller: installer, summariesDefaultEnabled: true
        )
        let settingsURL = tmpDir.appendingPathComponent("settings.json")

        let on = try service.setTracking(enabled: true)
        XCTAssertTrue(on.enabled)
        XCTAssertEqual(on.outcome, "installed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: settingsURL.path))
        XCTAssertEqual(try service.setTracking(enabled: true).outcome, "already_installed")

        let off = try service.setTracking(enabled: false)
        XCTAssertEqual(off.outcome, "uninstalled")
        XCTAssertEqual(try service.setTracking(enabled: false).outcome, "not_installed")
    }

    func testCurrentTrackingFollowsTheDisabledMarker() throws {
        let installer = try makeInstaller()
        let service = PreferencesService(
            database: db, secretStore: secrets, hookInstaller: installer, summariesDefaultEnabled: true
        )
        XCTAssertTrue(service.currentTracking().enabled)
        try installer.setTrackingDisabled(true)
        let current = service.currentTracking()
        XCTAssertFalse(current.enabled)
        XCTAssertTrue(current.disabledMarkerPresent)
        XCTAssertEqual(current.outcome, "current")
    }
}
