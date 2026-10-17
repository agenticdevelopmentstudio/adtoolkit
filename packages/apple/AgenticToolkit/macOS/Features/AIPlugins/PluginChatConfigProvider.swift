import Foundation
import AIPluginKit
import AgenticToolkitCore

/// Default `ChatConfigProvider`: the configuration selected in Settings
/// (`UserSettings.selectedAIProviderConfigurationId`), resolved to its plugin,
/// model and values. When nothing is selected, or the selection no longer
/// resolves, the first configuration that does resolve stands in: the seeded
/// default is deliberately left unselected, and a chat that answers "no
/// provider is configured" over a working configuration is a dead chat.
@MainActor
public final class PluginChatConfigProvider: ChatConfigProvider {

    private let pluginManager: AIPluginManager

    public init(pluginManager: AIPluginManager) {
        self.pluginManager = pluginManager
    }

    private var resolved: AIProviderResolver.Resolved? {
        let configurations = UserSettings.aiProviderConfigurations.value
        if let uuid = UUID(uuidString: UserSettings.selectedAIProviderConfigurationId.value),
           let chosen = configurations.first(where: { $0.id == uuid }),
           let resolved = AIProviderResolver.resolve(chosen, manager: pluginManager) {
            return resolved
        }
        for configuration in configurations {
            if let resolved = AIProviderResolver.resolve(configuration, manager: pluginManager) { return resolved }
        }
        return nil
    }

    public var selectedPluginIdentifier: String { resolved?.pluginIdentifier ?? "" }
    public var selectedModel: String { resolved?.model ?? "" }
    public var pluginConfigValues: [String: String] { resolved?.values ?? [:] }
}
