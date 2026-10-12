import Foundation
import OSLog
import AgenticToolkitCore

/// The single owner of the "oversight preferences → daemon" contract.
///
/// The settings pane and the AI Oversight window's options dialog edit the same
/// prefs (enabled, LLM judgment, provider selection, per-config model). One set
/// of observers lives here; on any change, at startup and on every daemon
/// reconnect the full idempotent snapshot is pushed, so a daemon restart cannot
/// strand a stale value. The engine is Core's `SettingsSnapshotPush`.
@MainActor
public enum StenographerOversightPrefsPush {

    private static var push: SettingsSnapshotPush?
    private static var modelObserver: UserSettingObserver<String>?

    /// Installs the observers and reconciles the daemon now and on every
    /// reconnect. Call once at startup.
    public static func startObserving(service: any StenographerDaemonService) {
        guard push == nil else {
            logger.warning("startObserving called more than once; ignoring the repeat call")
            return
        }
        let engine = SettingsSnapshotPush(
            label: "Oversight prefs",
            logger: logger,
            snapshot: { currentBody() },
            send: { body in
                guard let request = try? StenographerWire.decoder().decode(
                    OversightPreferenceRequest.self, from: body
                ) else { return false }
                return await service.setOversightPreferences(request)
            },
            registerReconnect: { service.onReconnect($0) }
        )
        push = engine
        resubscribeModelObserver()
        engine.start { onChange -> [AnyObject] in
            [
                UserSettingObserver(UserSettings.stenographerAIOversightEnabled) { _ in onChange() },
                UserSettingObserver(UserSettings.stenographerAIOversightLLMEnabled) { _ in onChange() },
                UserSettingObserver(UserSettings.stenographerAIOversightProviderConfigId) { _ in
                    Self.resubscribeModelObserver()
                    onChange()
                }
            ]
        }
    }

    /// Tears the observers down (test isolation; production installs once).
    public static func stopObserving() {
        push?.stop()
        push = nil
        modelObserver = nil
    }

    /// Awaits the most recent push (test-only determinism hook).
    public static func awaitPendingPush() async {
        await push?.awaitPendingPush()
    }

    /// The configuration id the selection names, or nil for the sentinels.
    private static func selectedConfigurationId() -> UUID? {
        UUID(uuidString: UserSettings.stenographerAIOversightProviderConfigId.value)
    }

    private static func resubscribeModelObserver() {
        guard let id = selectedConfigurationId() else {
            modelObserver = nil
            return
        }
        modelObserver = UserSettingObserver(UserSettings.oversightModelSetting(config: id)) { _ in
            Self.push?.push()
        }
    }

    /// The full snapshot the daemon receives — pure so it is unit-testable. The
    /// model travels only when a dedicated configuration is selected; the
    /// sentinels push "" (= the configuration's own model / not applicable).
    static func makeRequest(
        enabled: Bool, llmEnabled: Bool, selectedConfigId: String, model: String
    ) -> OversightPreferenceRequest {
        OversightPreferenceRequest(
            enabled: enabled, llmEnabled: llmEnabled, selectedConfigId: selectedConfigId, model: model)
    }

    private static func currentBody() -> Data? {
        let model = selectedConfigurationId().map { UserSettings.oversightModelSetting(config: $0).value } ?? ""
        let request = makeRequest(
            enabled: UserSettings.stenographerAIOversightEnabled.value,
            llmEnabled: UserSettings.stenographerAIOversightLLMEnabled.value,
            selectedConfigId: UserSettings.stenographerAIOversightProviderConfigId.value,
            model: model
        )
        return try? StenographerWire.encoder().encode(request)
    }
}

extension StenographerOversightPrefsPush: Loggable {
    public static nonisolated let logger = makeLogger()
}
