import Foundation
import Testing
@testable import AIPluginKit
@testable import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@Suite("PluginChatConfigProvider")
@MainActor
struct PluginChatConfigProviderTests {

    private func manager() -> AIPluginManager {
        let pluginManager = AIPluginManager(searchPaths: [], appName: "Test")
        pluginManager.registerForTesting(AIPluginDescriptor(
            schemaVersion: 3, identifier: "com.x.claude-local", displayName: "Claude (Local)",
            version: "1.0",
            fields: [],
            templates: [.init(id: "claude-local", displayName: "Claude Code (local CLI)",
                              models: ["sonnet"], defaultModel: "sonnet", secretRequired: false)]
        ))
        pluginManager.registerForTesting(AIPluginDescriptor(
            schemaVersion: 3, identifier: "com.x.openai", displayName: "OpenAI",
            version: "1.0",
            fields: [.init(key: "apiKey", label: "API Key", kind: .secret)],
            templates: [.init(id: "openai", displayName: "OpenAI", models: ["m1"], defaultModel: "m1")]
        ))
        return pluginManager
    }

    private let local = AIProviderConfiguration(
        name: "Claude Code (local CLI)", pluginIdentifier: "com.x.claude-local", templateId: "claude-local")
    private let openAI = AIProviderConfiguration(name: "OpenAI", pluginIdentifier: "com.x.openai", templateId: "openai")

    private func reset() {
        UserSettings.aiProviderConfigurations.value = []
        UserSettings.selectedAIProviderConfigurationId.value = ""
    }

    /// The seeded default is left unselected; it must still carry the chat.
    @Test("Falls back to the sole configuration when nothing is selected")
    func fallsBackToTheSoleConfiguration() {
        reset()
        defer { reset() }
        UserSettings.aiProviderConfigurations.value = [local]
        let provider = PluginChatConfigProvider(pluginManager: manager())
        #expect(provider.selectedPluginIdentifier == "com.x.claude-local")
        #expect(provider.selectedModel == "sonnet")
    }

    @Test("Prefers the selected configuration over the first")
    func prefersTheSelection() {
        reset()
        defer { reset() }
        UserSettings.aiProviderConfigurations.value = [local, openAI]
        UserSettings.selectedAIProviderConfigurationId.value = openAI.id.uuidString
        let provider = PluginChatConfigProvider(pluginManager: manager())
        #expect(provider.selectedPluginIdentifier == "com.x.openai")
        #expect(provider.selectedModel == "m1")
    }

    @Test("A selection that no longer resolves falls back to the first that does")
    func staleSelectionFallsBack() {
        reset()
        defer { reset() }
        UserSettings.aiProviderConfigurations.value = [local, openAI]
        UserSettings.selectedAIProviderConfigurationId.value = UUID().uuidString
        let provider = PluginChatConfigProvider(pluginManager: manager())
        #expect(provider.selectedPluginIdentifier == "com.x.claude-local")
    }

    @Test("Reports no provider when no configuration resolves")
    func nothingResolves() {
        reset()
        defer { reset() }
        UserSettings.aiProviderConfigurations.value = [
            AIProviderConfiguration(name: "Gone", pluginIdentifier: "com.x.gone", templateId: "gone")
        ]
        let provider = PluginChatConfigProvider(pluginManager: manager())
        #expect(provider.selectedPluginIdentifier == "")
        #expect(provider.selectedModel == "")
        #expect(provider.pluginConfigValues.isEmpty)
    }
}
