import AppKit
import AgenticToolkitCore

/// The oversight flavor of the toolkit's ``DaemonProviderPickerView``, plus the titles
/// the oversight UI uses in both the settings panel and the AI Oversight window's
/// gear dialog.
///
/// Its own selection pref leads with "Same as AI Summaries" (the "" default) and
/// the CLI sentinel, and its model row is backed by a per-configuration *oversight*
/// model pref — distinct from the summaries model, so one provider can run the two
/// features on different models. Pushing to the daemon is owned by
/// `StenographerOversightPrefsPush`.
@MainActor
enum AIOversightProviderControls {

    static let enableToggleTitle = "Watch live sessions"
    static let llmToggleTitle = "Use AI judgment"
    static let sameAsSummariesLabel = "Same as AI Summaries"
    static let sameAsSummariesValue = ""
    static let claudeCLILabel = "Default (Claude CLI)"
    /// Shared with the daemon's wire contract so the two can't drift.
    static let claudeCLIValue = OversightProviderSelection.claudeCLISentinel

    /// A picker bound to the oversight prefs. The caller must retain it: it owns
    /// the setting observers that keep the provider list and model row live.
    static func makePicker(service: any StenographerDaemonService) -> DaemonProviderPickerView {
        DaemonProviderPickerView(
            service: service,
            selectedSetting: UserSettings.stenographerAIOversightProviderConfigId,
            leadingChoices: [
                .init(label: sameAsSummariesLabel, value: sameAsSummariesValue),
                .init(label: claudeCLILabel, value: claudeCLIValue)
            ]
        )
    }
}
