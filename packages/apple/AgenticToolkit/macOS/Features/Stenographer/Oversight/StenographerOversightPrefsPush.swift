import Foundation
import OSLog
import AgenticToolkitCore

/// The single owner of the "oversight preferences → daemon" contract.
///
/// The settings pane and the AI Oversight window's options dialog edit the same
/// prefs (enabled, LLM judgment, provider selection; never a model). One set
/// of observers lives here; on any change, at startup and on every daemon
/// reconnect the full idempotent snapshot is pushed, so a daemon restart cannot
/// strand a stale value. The engine is Core's `SettingsSnapshotPush`.
///
/// **The first push is preceded by a one-time seed.** The daemon holds the only
/// copy of what the user chose before these panes moved to a new app, so a store
/// that has not yet been seeded reads `GET /preferences/oversight` and writes
/// the fields into its settings before the observers are installed and the
/// first snapshot goes out. If the daemon is down, nothing is pushed until a
/// reconnect lets the seed run.
@MainActor
public enum StenographerOversightPrefsPush {

    private static var push: SettingsSnapshotPush?

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
            registerReconnect: { service.onReconnect($0) },
            seed: { await seedFromDaemon(service: service) }
        )
        push = engine
        engine.start { onChange -> [AnyObject] in
            [
                UserSettingObserver(UserSettings.stenographerAIOversightEnabled) { _ in onChange() },
                UserSettingObserver(UserSettings.stenographerAIOversightLLMEnabled) { _ in onChange() },
                UserSettingObserver(UserSettings.stenographerAIOversightProviderConfigId) { _ in onChange() }
            ]
        }
    }

    /// Takes the daemon's stored values into the local settings once (marker
    /// `stenographerAIOversightSeededFromDaemon`). True when the store is now
    /// current or needs no seeding; false when the daemon could not be reached.
    /// The response's `contextThresholdPct` has no local setting and is ignored, and so
    /// is its `model`: no toolkit pane shows or edits a model override, so copying the
    /// daemon's would pin a hidden value that outlives the configuration's own model.
    static func seedFromDaemon(service: any StenographerDaemonService) async -> Bool {
        if UserSettings.stenographerAIOversightSeededFromDaemon.value { return true }
        guard let stored = await service.oversightPreferences() else { return false }
        UserSettings.stenographerAIOversightEnabled.value = stored.enabled
        UserSettings.stenographerAIOversightLLMEnabled.value = stored.llmEnabled
        UserSettings.stenographerAIOversightProviderConfigId.value = stored.selectedConfigId
        UserSettings.stenographerAIOversightSeededFromDaemon.value = true
        return true
    }

    /// Tears the observers down (test isolation; production installs once).
    public static func stopObserving() {
        push?.stop()
        push = nil
    }

    /// Awaits the most recent push (test-only determinism hook).
    public static func awaitPendingPush() async {
        await push?.awaitPendingPush()
    }

    /// The full snapshot the daemon receives — pure so it is unit-testable. The
    /// model is always "" (= the configuration's own model): the toolkit has no model
    /// override to send, so the daemon configuration's model is the one oversight uses.
    static func makeRequest(
        enabled: Bool, llmEnabled: Bool, selectedConfigId: String, model: String
    ) -> OversightPreferenceRequest {
        OversightPreferenceRequest(
            enabled: enabled, llmEnabled: llmEnabled, selectedConfigId: selectedConfigId, model: model)
    }

    private static func currentBody() -> Data? {
        let request = makeRequest(
            enabled: UserSettings.stenographerAIOversightEnabled.value,
            llmEnabled: UserSettings.stenographerAIOversightLLMEnabled.value,
            selectedConfigId: UserSettings.stenographerAIOversightProviderConfigId.value,
            model: ""
        )
        return try? StenographerWire.encoder().encode(request)
    }
}

extension StenographerOversightPrefsPush: Loggable {
    public static nonisolated let logger = makeLogger()
}
