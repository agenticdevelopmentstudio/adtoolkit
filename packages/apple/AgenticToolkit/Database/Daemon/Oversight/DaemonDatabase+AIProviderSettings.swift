#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation

extension DaemonDatabase {

    /// The synced provider-registry values, read live from this database's settings table.
    public var aiProviderSettings: ProviderSettingsReader {
        { [self] key in ((try? setting(for: key)) ?? nil) }
    }

    /// The provider-registry reader for **oversight** completions: identical to
    /// `aiProviderSettings` except that the summaries selection and its model can be
    /// overridden by the oversight keys — so the toolkit's resolution path needs no
    /// oversight awareness at all.
    ///
    /// - `oversight_selected_config_id` unset/"" → inherit the summaries selection
    ///   (`ai_selected_config_id`), today's behavior.
    /// - the `claude-cli` sentinel → report *no* selection, forcing the zero-config
    ///   CLI path.
    /// - a configuration UUID → report that configuration as selected.
    /// - `oversight_model` (when set) overrides `modelKey(config:)` — scoped to the
    ///   oversight-resolved configuration only, so it can never bleed into another
    ///   configuration's stored model.
    public var oversightAIProviderSettings: ProviderSettingsReader {
        let base = aiProviderSettings
        return { key in
            let choice = base(Oversight.selectedConfigKey) ?? ""
            if key == AIProviderConfigKeys.selectedConfigIdKey {
                if choice.isEmpty { return base(key) }
                if choice == Oversight.claudeCLISentinel { return "" }
                return choice
            }
            // The configuration oversight resolves to (after inherit/sentinel).
            let effective: String = {
                if choice.isEmpty { return base(AIProviderConfigKeys.selectedConfigIdKey) ?? "" }
                if choice == Oversight.claudeCLISentinel { return "" }
                return choice
            }()
            if let uuid = UUID(uuidString: effective),
               key == AIProviderConfigKeys.modelKey(config: uuid),
               let override = base(Oversight.modelKey), !override.isEmpty {
                return override
            }
            return base(key)
        }
    }
}
#endif
