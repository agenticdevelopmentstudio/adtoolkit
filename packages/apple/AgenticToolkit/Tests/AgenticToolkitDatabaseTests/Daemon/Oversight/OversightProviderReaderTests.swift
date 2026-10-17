import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import AIPluginKit

/// The remapped `oversightAIProviderSettings` reader: oversight's provider selection
/// (inherit / CLI sentinel / dedicated config) and its scoped model override, all
/// without the toolkit's resolution path knowing oversight exists — plus the
/// invariant that the summaries reader never sees the oversight keys.
final class OversightProviderReaderTests: XCTestCase {

    var database: DaemonDatabase!
    var tmpPath: String!

    let configA = AIProviderConfiguration(
        name: "Summaries Provider", pluginIdentifier: "plugin.a", templateId: "t"
    )
    let configB = AIProviderConfiguration(
        name: "Oversight Provider", pluginIdentifier: "plugin.b", templateId: "t"
    )

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path

        // Seed the synced registry: two configs, summaries selecting A with model "model-a".
        let registry = try JSONEncoder().encode([configA, configB])
        try database.setSetting(AIProviderConfigKeys.configurationsKey, String(data: registry, encoding: .utf8)!)
        try database.setSetting(AIProviderConfigKeys.selectedConfigIdKey, configA.id.uuidString)
        try database.setSetting(AIProviderConfigKeys.modelKey(config: configA.id), "model-a")
        try database.setSetting(AIProviderConfigKeys.modelKey(config: configB.id), "model-b")
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    // MARK: - Selection remapping

    func testUnsetSelectionInheritsSummaries() throws {
        let reader = database.oversightAIProviderSettings
        XCTAssertEqual(reader(AIProviderConfigKeys.selectedConfigIdKey), configA.id.uuidString)
        XCTAssertEqual(DaemonProviderResolver.selectedConfiguration(reader)?.id, configA.id)
        XCTAssertEqual(DaemonProviderResolver.model(config: configA.id, reader), "model-a")
    }

    func testCLISentinelForcesNoSelection() throws {
        try database.setSetting(Oversight.selectedConfigKey, Oversight.claudeCLISentinel)
        let reader = database.oversightAIProviderSettings
        XCTAssertEqual(reader(AIProviderConfigKeys.selectedConfigIdKey), "")
        XCTAssertNil(DaemonProviderResolver.selectedConfiguration(reader))
    }

    func testDedicatedConfigOverridesSummariesSelection() throws {
        try database.setSetting(Oversight.selectedConfigKey, configB.id.uuidString)
        let reader = database.oversightAIProviderSettings
        XCTAssertEqual(DaemonProviderResolver.selectedConfiguration(reader)?.id, configB.id)
        // B's own model, since no oversight model override is set.
        XCTAssertEqual(DaemonProviderResolver.model(config: configB.id, reader), "model-b")
    }

    // MARK: - Model override scoping

    func testModelOverrideAppliesOnlyToTheOversightConfig() throws {
        try database.setSetting(Oversight.selectedConfigKey, configB.id.uuidString)
        try database.setSetting(Oversight.modelKey, "override-model")
        let reader = database.oversightAIProviderSettings
        XCTAssertEqual(DaemonProviderResolver.model(config: configB.id, reader), "override-model")
        XCTAssertEqual(DaemonProviderResolver.model(config: configA.id, reader), "model-a",
                       "the override must not bleed into another configuration's model")
    }

    func testModelOverrideScopesToInheritedConfigWhenInheriting() throws {
        try database.setSetting(Oversight.modelKey, "override-model")
        let reader = database.oversightAIProviderSettings
        // Inheriting A: the override applies to A's model key.
        XCTAssertEqual(DaemonProviderResolver.model(config: configA.id, reader), "override-model")
        XCTAssertEqual(DaemonProviderResolver.model(config: configB.id, reader), "model-b")
    }

    func testEmptyModelOverrideMeansConfigOwnModel() throws {
        try database.setSetting(Oversight.selectedConfigKey, configB.id.uuidString)
        try database.setSetting(Oversight.modelKey, "")
        let reader = database.oversightAIProviderSettings
        XCTAssertEqual(DaemonProviderResolver.model(config: configB.id, reader), "model-b")
    }

    // MARK: - No leak into the summaries reader

    func testSummariesReaderIgnoresOversightKeys() throws {
        try database.setSetting(Oversight.selectedConfigKey, configB.id.uuidString)
        try database.setSetting(Oversight.modelKey, "override-model")
        let reader = database.aiProviderSettings
        XCTAssertEqual(DaemonProviderResolver.selectedConfiguration(reader)?.id, configA.id)
        XCTAssertEqual(DaemonProviderResolver.model(config: configA.id, reader), "model-a")
        XCTAssertEqual(DaemonProviderResolver.model(config: configB.id, reader), "model-b")
    }

    // MARK: - modelLabel

    func testModelLabelNamesTheOversightProvider() throws {
        try database.setSetting(Oversight.selectedConfigKey, configB.id.uuidString)
        XCTAssertEqual(ScriptAnalyzer.modelLabel(database), "model-b")

        try database.setSetting(Oversight.modelKey, "override-model")
        XCTAssertEqual(ScriptAnalyzer.modelLabel(database), "override-model")

        try database.setSetting(Oversight.selectedConfigKey, Oversight.claudeCLISentinel)
        XCTAssertEqual(ScriptAnalyzer.modelLabel(database), "claude-cli")
    }
}
