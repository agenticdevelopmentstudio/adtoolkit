import Foundation
import OSLog
import AgenticToolkitCore
import AIPluginKit

/// The single owner of the "LLM provider configurations → daemon" contract.
///
/// The LLM Providers pane edits the configuration list, the selection and each
/// configuration's model and fields. One set of observers lives here; on any
/// change, at startup and on every daemon reconnect the whole registry (every
/// configuration fully resolved, secrets read from the Keychain, plus the
/// selected id) is pushed through `POST /preferences/ai`. The engine is Core's
/// `SettingsSnapshotPush`; the transport is the service's `setAIPreferences`.
///
/// The configuration-scoped observers are dynamic: they re-subscribe to EVERY
/// configuration's settings whenever the selection or the list changes, since
/// those setting keys are configuration-specific and the daemon mirrors the
/// whole set.
@MainActor
public enum StenographerAIConfigPush {

    private static var push: SettingsSnapshotPush?
    private static var configScopedObservers: [UserSettingObserver<String>] = []
    private static var observedManager: AIPluginManager?
    private static var onChange: (@MainActor () -> Void)?
    /// The ids this host last pushed. The daemon's registry is shared with other hosts, so
    /// a push names only the ones dropped from this list and never deletes anyone else's.
    private nonisolated static let ledger = AIConfigPushLedger(
        key: "stenographer.aiConfigPush.http.lastPushedIds")

    /// Installs the observers and reconciles the daemon now and on every
    /// reconnect. Call once at startup, after the plugin manager exists.
    public static func startObserving(service: any StenographerDaemonService, pluginManager: AIPluginManager?) {
        guard push == nil else {
            logger.warning("startObserving called more than once; ignoring the repeat call")
            return
        }
        observedManager = pluginManager
        let engine = SettingsSnapshotPush(
            label: "AI config",
            logger: logger,
            snapshot: { currentBody() },
            send: { body in
                guard let sync = try? JSONDecoder().decode(AIProviderConfigSync.self, from: body) else {
                    return false
                }
                let landed = await service.setAIPreferences(sync)
                if landed { ledger.recordLanded(sync) }
                return landed
            },
            registerReconnect: { service.onReconnect($0) }
        )
        push = engine
        engine.start { onChange -> [AnyObject] in
            Self.onChange = onChange
            let selection = UserSettingObserver(UserSettings.selectedAIProviderConfigurationId) { _ in
                Self.resubscribeConfigScopedObservers()
                onChange()
            }
            let list = UserSettingObserver(UserSettings.aiProviderConfigurations) { _ in
                Self.resubscribeConfigScopedObservers()
                onChange()
            }
            Self.resubscribeConfigScopedObservers()
            return [selection, list]
        }
    }

    /// Tears the observers down (test isolation; production installs once).
    public static func stopObserving() {
        push?.stop()
        push = nil
        configScopedObservers.removeAll()
        observedManager = nil
        onChange = nil
    }

    /// Awaits the most recent push (test-only determinism hook).
    public static func awaitPendingPush() async {
        await push?.awaitPendingPush()
    }

    /// Re-binds field and model observers to EVERY configuration's id-scoped
    /// settings, so a token or model edit on any configuration pushes.
    private static func resubscribeConfigScopedObservers() {
        configScopedObservers.removeAll()
        guard let manager = observedManager, let onChange else { return }
        for config in UserSettings.aiProviderConfigurations.value {
            guard let template = manager.template(
                pluginIdentifier: config.pluginIdentifier, templateId: config.templateId)
            else { continue }
            // Only field names are needed to wire observers, so read the
            // descriptor's field list rather than resolving (which would also
            // read every secret from the Keychain).
            let fields = manager.fields(pluginIdentifier: config.pluginIdentifier, template: template)
            configScopedObservers.append(
                UserSettingObserver(AIProviderConfigStore.modelSetting(config: config.id, template: template)) { _ in
                    onChange()
                }
            )
            for field in fields {
                configScopedObservers.append(
                    UserSettingObserver(AIProviderConfigStore.fieldSetting(config: config.id, field: field)) { _ in
                        onChange()
                    }
                )
            }
        }
    }

    /// Assembles the sync from all configurations. `resolve` returns
    /// the already-split wire config for a configuration, or nil to skip it
    /// (plugin uninstalled / template gone). Pure and injectable.
    static func makeSync(
        configurations: [AIProviderConfiguration],
        selectedConfigId: String,
        enabled: Bool,
        removedConfigIds: [UUID]? = nil,
        resolve: (AIProviderConfiguration) -> ResolvedProviderConfig?
    ) -> AIProviderConfigSync {
        AIProviderConfigSync(
            enabled: enabled,
            selectedConfigId: UUID(uuidString: selectedConfigId),
            configs: configurations.compactMap(resolve),
            removedConfigIds: removedConfigIds
        )
    }

    /// The Keychain keys of every empty secret in `sync` that has a stored item
    /// `read` cannot return. A cleared secret is stored as "" and reads back as
    /// "", and a secret never set has no item at all; only an item that exists
    /// yet reads back nil is unreadable. Pure and injectable.
    static func unreadableSecretKeys(
        in sync: AIProviderConfigSync,
        exists: (String) -> Bool,
        read: (String) -> String?
    ) -> [String] {
        sync.configs.flatMap { config in
            config.secrets
                .filter { $0.value.isEmpty }
                .map { AIProviderConfigKeys.fieldKey(config: config.id, field: $0.key) }
                .filter { exists($0) && read($0) == nil }
        }
        .sorted()
    }

    /// Splits a resolver result into the non-secret `values` and secret
    /// `secrets` the wire config carries. Secret descriptor fields go in
    /// `secrets`; everything else the resolver produced (descriptor fields and
    /// template defaults alike) goes in `values`. `model` has its own field.
    static func wireConfig(
        _ config: AIProviderConfiguration, resolved: AIProviderResolver.Resolved
    ) -> ResolvedProviderConfig {
        let secretKeys = Set(resolved.fields.filter(\.isSecret).map(\.key))
        var values: [String: String] = [:]
        var secrets: [String: String] = [:]
        for (key, value) in resolved.values where key != "model" {
            if secretKeys.contains(key) { secrets[key] = value } else { values[key] = value }
        }
        return ResolvedProviderConfig(
            id: config.id, name: config.name, pluginIdentifier: resolved.pluginIdentifier,
            templateId: config.templateId, model: resolved.model, values: values, secrets: secrets
        )
    }

    /// The registry the daemon receives, encoded; nil when it must not be sent.
    ///
    /// A nil manager resolves nothing, so nothing is sent. The sync is partial: it
    /// names the configurations this host dropped since its last push and the daemon
    /// deletes only those. Nor is
    /// anything sent while a stored secret cannot be read: an empty secret is a
    /// delete on the daemon side, and the empty value is not the user's.
    private static func currentBody() -> Data? {
        guard let manager = observedManager else { return nil }
        let sync = makeSync(
            configurations: UserSettings.aiProviderConfigurations.value,
            selectedConfigId: UserSettings.selectedAIProviderConfigurationId.value,
            enabled: true,
            removedConfigIds: ledger.removed(configured: UserSettings.aiProviderConfigurations.value.map(\.id)),
            resolve: { config in
                guard let resolved = AIProviderResolver.resolve(config, manager: manager) else { return nil }
                return wireConfig(config, resolved: resolved)
            }
        )
        let unreadable = unreadableSecretKeys(
            in: sync,
            exists: { KeychainHelper.exists(forKey: $0) },
            read: { KeychainHelper.get(forKey: $0) }
        )
        guard unreadable.isEmpty else {
            logger.warning(
                "Not pushing AI config: \(unreadable.count) stored secret(s) could not be read from the Keychain")
            return nil
        }
        return try? JSONEncoder().encode(sync)
    }
}

extension StenographerAIConfigPush: Loggable {
    public static nonisolated let logger = makeLogger()
}
