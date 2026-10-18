#if canImport(AgenticToolkitCore)
import Foundation
import OSLog
import AgenticToolkitCore
import AIPluginKit

/// The single owner of the daemon's preference-write business logic — AI
/// summarization config (plus plugin secrets) and tracking enablement.
///
/// Both the HTTP router and the XPC service delegate here, so the rules (secret
/// namespacing, plugin-switch secret clearing, CFBoolean normalization, hook
/// install/uninstall) live in exactly one place rather than being duplicated per
/// transport. Holds no mutable state of its own — it reads/writes the shared
/// `DaemonDatabase`, the daemon Keychain (`SecretStoring`), and `ClaudeHookInstaller`.
public final class PreferencesService: @unchecked Sendable {

    public enum PreferencesError: Error {
        case hookInstallFailed(String)
    }

    private let database: DaemonDatabase
    private let secretStore: any SecretStoring
    private let hookInstaller: ClaudeHookInstaller
    private let summarizer: DaemonSessionSummarizer

    /// Serializes the whole provider-config reconcile. HTTP `POST /preferences/ai`
    /// and XPC `setAIPreferences` call `applyAIProviderSync` from independent
    /// execution contexts, and the reconcile is a read-modify-write of the registry
    /// index — two interleaved syncs could delete a config the other just upserted.
    /// This lock makes each sync atomic with respect to the others (the type is
    /// `@unchecked Sendable`, so the compiler doesn't enforce this for us).
    private let syncLock = NSLock()

    /// `summariesDefaultEnabled` is the daemon's own answer to "are summaries on when no
    /// row has been written yet" (see `DaemonSessionSummarizer.defaultEnabled`).
    public init(
        database: DaemonDatabase,
        secretStore: any SecretStoring,
        hookInstaller: ClaudeHookInstaller,
        summariesDefaultEnabled: Bool
    ) {
        self.database = database
        self.secretStore = secretStore
        self.hookInstaller = hookInstaller
        self.summarizer = DaemonSessionSummarizer(defaultEnabled: summariesDefaultEnabled)
    }

    // MARK: - AI summarization preferences

    /// Current AI prefs for a GET/echo — `{enabled, selected_config_id, plugin_id,
    /// model}`, derived from the selected registry entry. Secrets are deliberately
    /// never included.
    public func currentAIPreferences() -> [String: String] {
        let selectedId = ((try? database.setting(for: AIProviderConfigKeys.selectedConfigIdKey)) ?? nil) ?? ""
        let selected = DaemonProviderResolver.selectedConfiguration(database.aiProviderSettings)
        return [
            "enabled": String(summarizer.isEnabled(database)),
            "selected_config_id": selectedId,
            "plugin_id": selected?.pluginIdentifier ?? "",
            "model": selected.map { DaemonProviderResolver.model(config: $0.id, database.aiProviderSettings) } ?? ""
        ]
    }

    // MARK: - AI provider-config registry sync

    /// Applies a full-set provider-config sync: reconciles the stored registry
    /// against the incoming configurations (upsert present, delete absent) and
    /// their secrets, and one-time-cleans the legacy plugin-keyed layout. It owns only
    /// the provider registry: the enabled flag and the selected configuration belong to
    /// `setSummary` (POST /preferences/summaries) and are never written here.
    /// Returns `false` (a no-op, no partial wipe) when the body can't be decoded
    /// so the caller can answer 400 rather than a false success.
    @discardableResult
    public func applyAIProviderSync(from body: Data) -> Bool {
        guard let sync = try? JSONDecoder().decode(AIProviderConfigSync.self, from: body) else {
            Self.logger.warning("Ignoring AI provider sync: undecodable body")
            return false
        }
        applyAIProviderSync(sync)
        return true
    }

    /// A sync touches the provider registry only. `sync.enabled` and
    /// `sync.selectedConfigId` are carried for wire compatibility and ignored.
    public func applyAIProviderSync(_ sync: AIProviderConfigSync) {
        // See `syncLock`: serialize the read-modify-write so HTTP and XPC callers
        // can't interleave and corrupt the registry.
        syncLock.lock()
        defer { syncLock.unlock() }
        // Batch every settings write into ONE transaction on the write lane instead
        // of dozens of separate commits. `setSetting` (→ `execute`) is reentrant, so
        // the nested `persistSetting` calls join this transaction; a mid-flight
        // eviction rolls the whole sync back (no partial state — it self-heals on the
        // host's next push). Keychain writes run inline (they aren't transactional).
        try? database.transaction {
            let incoming = Set(sync.configs.map(\.id))
            for stored in storedConfigurations() where !incoming.contains(stored.id) {
                removeStoredConfig(id: stored.id)
            }
            for config in sync.configs { upsertStoredConfig(config) }

            let identities = sync.configs.map {
                AIProviderConfiguration(id: $0.id, name: $0.name,
                                        pluginIdentifier: $0.pluginIdentifier, templateId: $0.templateId)
            }
            if let data = try? JSONEncoder().encode(identities), let json = String(data: data, encoding: .utf8) {
                persistSetting(AIProviderConfigKeys.configurationsKey, json)
            }
            cleanUpLegacyIfNeeded()
        }
    }

    /// The daemon's known configuration identities (registry index).
    public func storedConfigurations() -> [AIProviderConfiguration] {
        DaemonProviderResolver.configurations(database.aiProviderSettings)
    }

    // MARK: - Registry write helpers

    private func upsertStoredConfig(_ config: ResolvedProviderConfig) {
        // Clean replace, not merge: clear any non-secret field stored for this config
        // in a PRIOR push but absent from this one (a template/descriptor change that
        // dropped or renamed a field). Otherwise the stale value lingers and the
        // summarizer, which reads authMode/baseURL/etc. straight from the settings
        // table, would resurrect it into a request the app no longer intends.
        let incomingKeys = Set(config.values.keys)
        for old in ledgerFields(AIProviderConfigKeys.fieldsKey(config: config.id)) where !incomingKeys.contains(old) {
            persistSetting(AIProviderConfigKeys.fieldKey(config: config.id, field: old), "")
        }
        for (key, value) in config.values {
            persistSetting(AIProviderConfigKeys.fieldKey(config: config.id, field: key), value)
        }
        persistSetting(AIProviderConfigKeys.fieldsKey(config: config.id),
                       config.values.keys.sorted().joined(separator: "\n"))
        persistSetting(AIProviderConfigKeys.modelKey(config: config.id), config.model)
        storeConfigSecrets(config.secrets, config: config.id)
    }

    private func storeConfigSecrets(_ secrets: [String: String], config id: UUID) {
        // Clean replace, not merge: delete any secret field stored in a PRIOR push
        // whose KEY is absent from this one (a descriptor change removed/renamed it).
        // Without this the old Keychain entry is neither overwritten nor tracked by
        // the shrunken ledger, so it orphans a credential removeStoredConfig can never
        // reach — the exact leak this subsystem exists to prevent. (An empty *value*
        // for a still-present field is handled below, deleting that entry.)
        let incomingKeys = Set(secrets.keys)
        for old in ledgerFields(AIProviderConfigKeys.secretFieldsKey(config: id)) where !incomingKeys.contains(old) {
            secretStore.delete(forKey: AIProviderConfigKeys.fieldKey(config: id, field: old))
        }
        var storedFields: [String] = []
        for (field, value) in secrets {
            let storeKey = AIProviderConfigKeys.fieldKey(config: id, field: field)
            if value.isEmpty {
                secretStore.delete(forKey: storeKey)
            } else {
                secretStore.set(value, forKey: storeKey)
                storedFields.append(field)
            }
        }
        persistSetting(AIProviderConfigKeys.secretFieldsKey(config: id),
                       storedFields.sorted().joined(separator: "\n"))
    }

    private func removeStoredConfig(id: UUID) {
        let secretLedger = AIProviderConfigKeys.secretFieldsKey(config: id)
        for field in ledgerFields(secretLedger) {
            secretStore.delete(forKey: AIProviderConfigKeys.fieldKey(config: id, field: field))
        }
        let fieldLedger = AIProviderConfigKeys.fieldsKey(config: id)
        for field in ledgerFields(fieldLedger) {
            persistSetting(AIProviderConfigKeys.fieldKey(config: id, field: field), "")
        }
        persistSetting(secretLedger, "")
        persistSetting(fieldLedger, "")
        persistSetting(AIProviderConfigKeys.modelKey(config: id), "")
    }

    private func ledgerFields(_ key: String) -> [String] {
        (((try? database.setting(for: key)) ?? nil) ?? "")
            .split(separator: "\n").map(String.init)
    }

    /// One-time removal of the legacy plugin-keyed AI settings the registry replaces.
    /// Idempotent via the `legacyCleaned` flag; runs after the first sync so nothing
    /// stale (a previous plugin's `ai_base_url`/`ai_model` or Keychain secret) lingers.
    private func cleanUpLegacyIfNeeded() {
        let cleaned = ((try? database.setting(for: AIProviderConfigKeys.legacyCleanedKey)) ?? nil) ?? ""
        guard cleaned != "true" else { return }
        let legacyPlugin = ((try? database.setting(for: DaemonPluginConfig.selectedPluginKey)) ?? nil) ?? ""
        if !legacyPlugin.isEmpty { clearStoredSecrets(forPlugin: legacyPlugin) }
        persistSetting(DaemonPluginConfig.selectedPluginKey, "")
        persistSetting("ai_base_url", "")
        persistSetting("ai_model", "")
        persistSetting(AIProviderConfigKeys.legacyCleanedKey, "true")
    }

    // MARK: - Tracking preference

    /// Installs or uninstalls the Claude hooks to enforce tracking, returning the
    /// resulting state. Throws ``PreferencesError/hookInstallFailed`` when enabling
    /// fails (the caller maps it to a 500).
    public func setTracking(enabled: Bool) throws -> TrackingPreferenceResponse {
        let outcome: String
        if enabled {
            switch hookInstaller.installHooks() {
            case .installed: outcome = "installed"
            case .alreadyInstalled: outcome = "already_installed"
            case .failed(let message): throw PreferencesError.hookInstallFailed(message)
            }
        } else {
            outcome = hookInstaller.uninstallHooks() ? "uninstalled" : "not_installed"
        }
        return TrackingPreferenceResponse(
            enabled: enabled,
            disabledMarkerPresent: hookInstaller.isTrackingDisabled(),
            outcome: outcome
        )
    }

    public func currentTracking() -> TrackingPreferenceResponse {
        TrackingPreferenceResponse(
            enabled: !hookInstaller.isTrackingDisabled(),
            disabledMarkerPresent: hookInstaller.isTrackingDisabled(),
            outcome: "current"
        )
    }

    // MARK: - Status-line display

    /// Switches the status-line display on or off (off keeps the capture feed).
    public func setStatusLineDisplay(_ enabled: Bool) throws {
        try hookInstaller.setStatusLineDisplay(enabled)
    }

    public var isStatusLineDisplayed: Bool { hookInstaller.isStatusLineDisplayed }

    /// The dispatcher's record of our renderer's last failure, nil while it works.
    public var statusLineError: String? { hookInstaller.statusLineError }

    // MARK: - Oversight preferences

    /// Persists the AI-oversight subsystem settings and returns the resulting state.
    /// A `nil` argument is left unchanged (so `""` is a meaningful write: "inherit the
    /// summaries selection" / "the configuration's own model"). `enabled` gates the
    /// whole subsystem (opt-in, default off); `contextThresholdPct` (clamped 1…100)
    /// tunes when `ContextObserver` flags a session; `selectedConfigId`/`model` steer
    /// which provider oversight completions use (see `Oversight.selectedConfigKey`).
    /// All live in the settings table, read live by `Oversight`, so a toggle takes
    /// effect on the next oversight tick without a daemon restart.
    public func setOversight(
        enabled: Bool?,
        contextThresholdPct: Int?,
        llmEnabled: Bool?,
        selectedConfigId: String? = nil,
        model: String? = nil
    ) -> OversightPreferenceResponse {
        if let enabled {
            persistSetting("oversight_enabled", enabled ? "true" : "false")
        }
        if let pct = contextThresholdPct {
            persistSetting("oversight_context_threshold_pct", String(min(100, max(1, pct))))
        }
        if let llmEnabled {
            persistSetting("oversight_llm_enabled", llmEnabled ? "true" : "false")
        }
        if let selectedConfigId {
            persistSetting(Oversight.selectedConfigKey, selectedConfigId)
        }
        if let model {
            persistSetting(Oversight.modelKey, model)
        }
        return currentOversight()
    }

    /// Applies a decoded oversight-preference request (the shared HTTP/XPC body).
    public func setOversight(_ request: OversightPreferenceRequest) -> OversightPreferenceResponse {
        setOversight(
            enabled: request.enabled,
            contextThresholdPct: request.contextThresholdPct,
            llmEnabled: request.llmEnabled,
            selectedConfigId: request.selectedConfigId,
            model: request.model
        )
    }

    public func currentOversight() -> OversightPreferenceResponse {
        OversightPreferenceResponse(
            enabled: Oversight.isEnabled(database),
            contextThresholdPct: Oversight.contextThresholdPct(database),
            llmEnabled: Oversight.llmEnabled(database),
            selectedConfigId: (try? database.setting(for: Oversight.selectedConfigKey)).flatMap { $0 } ?? "",
            model: (try? database.setting(for: Oversight.modelKey)).flatMap { $0 } ?? ""
        )
    }

    // MARK: - AI-summaries tuning

    /// Persists the summaries tuning knobs and returns the resulting state. A `nil`
    /// argument is left unchanged; numbers are clamped through `SummaryLimits` so a
    /// stale app or a hand-rolled POST can't wedge the summarizer. A prompt of `""`
    /// is a meaningful write — it means "back to the shipped template", which is
    /// exactly what `SummaryPrefs.prompt` reads a blank value as. All live in the
    /// settings table, read live on each summarization, so an edit takes effect on
    /// the next tick without a daemon restart.
    public func setSummary(
        enabled: Bool? = nil,
        selectedConfigId: String? = nil,
        prompt: String? = nil,
        maxWords: Int? = nil,
        activityLines: Int? = nil,
        detailChars: Int? = nil,
        intervalMinutes: Int? = nil,
        maxPerRun: Int? = nil,
        timeoutSeconds: Int? = nil
    ) -> SummaryPreferenceResponse {
        if let enabled {
            persistSetting(AIProviderConfigKeys.enabledKey, enabled ? "true" : "false")
        }
        if let selectedConfigId {
            persistSetting(AIProviderConfigKeys.selectedConfigIdKey, selectedConfigId)
        }
        if let prompt {
            persistSetting(SummarySettingsKeys.prompt, prompt)
        }
        func persistClamped(_ key: String, _ value: Int?, _ range: ClosedRange<Int>) {
            guard let value else { return }
            persistSetting(key, String(SummaryLimits.clamp(value, to: range)))
        }
        persistClamped(SummarySettingsKeys.maxWords, maxWords, SummaryLimits.maxWords)
        persistClamped(SummarySettingsKeys.activityLines, activityLines, SummaryLimits.activityLines)
        persistClamped(SummarySettingsKeys.detailChars, detailChars, SummaryLimits.detailChars)
        persistClamped(SummarySettingsKeys.intervalMinutes, intervalMinutes, SummaryLimits.intervalMinutes)
        persistClamped(SummarySettingsKeys.maxPerRun, maxPerRun, SummaryLimits.maxPerRun)
        persistClamped(SummarySettingsKeys.timeoutSeconds, timeoutSeconds, SummaryLimits.timeoutSeconds)
        return currentSummary()
    }

    /// Applies a decoded summaries-preference request (the shared HTTP/XPC body).
    public func setSummary(_ request: SummaryPreferenceRequest) -> SummaryPreferenceResponse {
        setSummary(
            enabled: request.enabled,
            selectedConfigId: request.selectedConfigId,
            prompt: request.prompt,
            maxWords: request.maxWords,
            activityLines: request.activityLines,
            detailChars: request.detailChars,
            intervalMinutes: request.intervalMinutes,
            maxPerRun: request.maxPerRun,
            timeoutSeconds: request.timeoutSeconds
        )
    }

    /// The effective tuning — what the summarizer would use right now, defaults
    /// filled in, not the raw stored strings.
    public func currentSummary() -> SummaryPreferenceResponse {
        SummaryPreferenceResponse(
            enabled: summarizer.isEnabled(database),
            selectedConfigId: (try? database.setting(for: AIProviderConfigKeys.selectedConfigIdKey)) ?? "",
            prompt: SummaryPrefs.prompt(database),
            maxWords: SummaryPrefs.maxWords(database),
            activityLines: SummaryPrefs.activityLines(database),
            detailChars: SummaryPrefs.detailChars(database),
            intervalMinutes: SummaryPrefs.intervalMinutes(database),
            maxPerRun: SummaryPrefs.maxPerRun(database),
            timeoutSeconds: Int(SummaryPrefs.timeoutSeconds(database))
        )
    }

    // MARK: - Private helpers

    /// Persists one settings-table value, normalizing the JSON-decoded type: a JSON
    /// boolean becomes `"true"`/`"false"`, a number its canonical string, a string
    /// verbatim; other types are ignored. A failed write is logged, not fatal — the
    /// table self-heals on the host's next push.
    private func persistSetting(_ key: String, _ value: Any?) {
        let stringValue: String
        if let str = value as? String {
            stringValue = str
        } else if let number = value as? NSNumber {
            // A JSON bool and a JSON number both bridge to NSNumber; only a CFBoolean
            // should persist as "true"/"false" rather than "1"/"0".
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                stringValue = number.boolValue ? "true" : "false"
            } else {
                stringValue = number.stringValue
            }
        } else {
            return
        }
        do {
            try database.setSetting(key, stringValue)
        } catch {
            Self.logger.warning(
                "Failed to persist setting \(key, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Removes every secret recorded for `pluginId` (via the ledger) and clears the
    /// ledger, so a plugin switch can't leave a stale credential in the Keychain.
    private func clearStoredSecrets(forPlugin pluginId: String) {
        let ledgerKey = DaemonPluginConfig.secretFieldsKey(plugin: pluginId)
        let fields = (((try? database.setting(for: ledgerKey)) ?? nil) ?? "")
            .split(separator: "\n")
            .map(String.init)
        for field in fields {
            let key = DaemonPluginConfig.fieldKey(plugin: pluginId, field: field)
            secretStore.delete(forKey: key)        // pinned service (no-op if absent)
            // deleteLegacy hits the pre-pin fallback service, where the real old key lives.
            secretStore.deleteLegacy(forKey: key)
        }
        persistSetting(ledgerKey, "")
    }
}

extension PreferencesService: Loggable {
    public static nonisolated let logger = makeLogger()
}

#endif
