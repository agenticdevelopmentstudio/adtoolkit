import Foundation
import OSLog
import AgenticToolkitCore

/// The single owner of the "AI summaries → daemon" contract.
///
/// The AI Summaries pane and the Sessions window's gear dialog edit the switch,
/// the provider selection and seven tuning prefs. One set of observers lives
/// here; on any change, at startup and on every daemon reconnect the full
/// idempotent snapshot is pushed through `POST /preferences/summaries`. The
/// engine is Core's `SettingsSnapshotPush`.
///
/// **The first push is preceded by a one-time seed.** The daemon holds the only
/// copy of what the user chose before these panes moved to a new app, so a store
/// that has not yet been seeded reads `GET /preferences/summaries` and writes
/// every field into its settings before the observers are installed and the
/// first snapshot goes out. If the daemon is down, nothing is pushed until a
/// reconnect lets the seed run.
@MainActor
public enum StenographerSummaryPrefsPush {

    private static var push: SettingsSnapshotPush?

    /// Installs the observers and reconciles the daemon now and on every
    /// reconnect. Call once at startup.
    public static func startObserving(service: any StenographerDaemonService) {
        guard push == nil else {
            logger.warning("startObserving called more than once; ignoring the repeat call")
            return
        }
        let engine = SettingsSnapshotPush(
            label: "Summary prefs",
            logger: logger,
            snapshot: { currentBody() },
            send: { body in
                guard let request = try? StenographerWire.decoder().decode(
                    SummaryPreferenceRequest.self, from: body
                ) else { return false }
                return await service.setSummaryPreferences(request)
            },
            registerReconnect: { service.onReconnect($0) },
            seed: { await seedFromDaemon(service: service) }
        )
        push = engine
        engine.start { onChange -> [AnyObject] in
            let strings: [AnyObject] = [
                UserSettings.stenographerAISummaryPrompt,
                UserSettings.stenographerAISummariesProviderConfigId
            ].map { setting in UserSettingObserver(setting) { _ in onChange() } }
            let bools: [AnyObject] = [
                UserSettingObserver(UserSettings.stenographerAISummariesEnabled) { _ in onChange() }
            ]
            let ints: [AnyObject] = [
                UserSettings.stenographerAISummaryMaxWords,
                UserSettings.stenographerAISummaryActivityLines,
                UserSettings.stenographerAISummaryDetailChars,
                UserSettings.stenographerAISummaryIntervalMinutes,
                UserSettings.stenographerAISummaryMaxPerRun,
                UserSettings.stenographerAISummaryTimeoutSeconds
            ].map { setting in UserSettingObserver(setting) { _ in onChange() } }
            return strings + bools + ints
        }
    }

    /// Takes the daemon's stored values into the local settings once (marker
    /// `stenographerAISummariesSeededFromDaemon`). True when the store is now
    /// current or needs no seeding; false when the daemon could not be reached.
    static func seedFromDaemon(service: any StenographerDaemonService) async -> Bool {
        if UserSettings.stenographerAISummariesSeededFromDaemon.value { return true }
        guard let stored = await service.summaryPreferences() else { return false }
        UserSettings.stenographerAISummariesEnabled.value = stored.enabled
        UserSettings.stenographerAISummariesProviderConfigId.value = stored.selectedConfigId
        // An unmodified (or never configured) prompt stays at the default, which
        // is not stored, so a later release's wording still applies.
        if stored.prompt.isEmpty || stored.prompt == SummaryDefaults.prompt {
            UserSettings.stenographerAISummaryPrompt.remove()
        } else {
            UserSettings.stenographerAISummaryPrompt.value = stored.prompt
        }
        UserSettings.stenographerAISummaryMaxWords.value = stored.maxWords
        UserSettings.stenographerAISummaryActivityLines.value = stored.activityLines
        UserSettings.stenographerAISummaryDetailChars.value = stored.detailChars
        UserSettings.stenographerAISummaryIntervalMinutes.value = stored.intervalMinutes
        UserSettings.stenographerAISummaryMaxPerRun.value = stored.maxPerRun
        UserSettings.stenographerAISummaryTimeoutSeconds.value = stored.timeoutSeconds
        UserSettings.stenographerAISummariesSeededFromDaemon.value = true
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

    /// The full snapshot the daemon receives — pure so it is unit-testable.
    /// Values travel as the user set them; the daemon clamps through `SummaryLimits`.
    static func makeRequest(
        enabled: Bool, selectedConfigId: String, prompt: String, maxWords: Int, activityLines: Int,
        detailChars: Int, intervalMinutes: Int, maxPerRun: Int, timeoutSeconds: Int
    ) -> SummaryPreferenceRequest {
        SummaryPreferenceRequest(
            enabled: enabled, selectedConfigId: selectedConfigId, prompt: prompt, maxWords: maxWords,
            activityLines: activityLines, detailChars: detailChars, intervalMinutes: intervalMinutes,
            maxPerRun: maxPerRun, timeoutSeconds: timeoutSeconds)
    }

    private static func currentBody() -> Data? {
        // An unmodified prompt travels blank: the daemon reads a blank prompt as
        // "never configured" and uses its own `SummaryDefaults.prompt`, so a
        // future release's wording applies instead of this build's copy being
        // pinned on the daemon side forever.
        let prompt = UserSettings.stenographerAISummaryPrompt.value
        let request = makeRequest(
            enabled: UserSettings.stenographerAISummariesEnabled.value,
            selectedConfigId: UserSettings.stenographerAISummariesProviderConfigId.value,
            prompt: prompt == SummaryDefaults.prompt ? "" : prompt,
            maxWords: UserSettings.stenographerAISummaryMaxWords.value,
            activityLines: UserSettings.stenographerAISummaryActivityLines.value,
            detailChars: UserSettings.stenographerAISummaryDetailChars.value,
            intervalMinutes: UserSettings.stenographerAISummaryIntervalMinutes.value,
            maxPerRun: UserSettings.stenographerAISummaryMaxPerRun.value,
            timeoutSeconds: UserSettings.stenographerAISummaryTimeoutSeconds.value
        )
        return try? StenographerWire.encoder().encode(request)
    }
}

extension StenographerSummaryPrefsPush: Loggable {
    public static nonisolated let logger = makeLogger()
}
