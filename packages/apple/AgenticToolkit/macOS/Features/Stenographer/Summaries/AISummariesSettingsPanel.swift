import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// "AI Summaries" settings: whether the daemon titles sessions with a model,
/// which model, what it is told, and how often it is asked.
///
/// Everything below the provider picker is a knob the daemon reads at request
/// time — `StenographerSummaryPrefsPush` mirrors them into the daemon's settings
/// table, so an edit here changes the *next* summarization without a restart.
@MainActor
public final class AISummariesSettingsPanel: ComposableSettings.SettingsPanelViewController {

    private let service: any StenographerDaemonService

    /// Retained: the picker owns the setting observers that keep the provider list
    /// and model row live. (Pushing to the daemon is owned centrally by
    /// `StenographerSummaryPrefsPush`, not by this panel.)
    private var picker: DaemonProviderPickerView?

    public init(service: any StenographerDaemonService) {
        self.service = service
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "AI Summaries",
            icon: NSImage(systemSymbolName: "text.quote", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "AI Summaries",
                body: "When enabled, the always-on daemon summarizes sessions with the "
                    + "selected provider and model, so a running history accrues even when "
                    + "this app isn't open. The Default (Claude CLI) provider needs no "
                    + "setup. Other providers are configured in Stenographer's LLM "
                    + "Providers settings pane — an API key entered there is stored in "
                    + "your login Keychain (never in the database)."
            ),
            .init(
                title: "Prompt",
                body: "\(SummaryDefaults.maxWordsPlaceholder) is replaced with the word "
                    + "limit below. Remove it and the model is simply never told the "
                    + "limit — the reply is still trimmed to it. Edits take effect on the "
                    + "next summary."
            ),
            .init(
                title: "What the Model Sees",
                body: "Each session's most recent events are described to the model, one "
                    + "line per event, truncated to the detail length. More of either "
                    + "gives a better title, sends more of your session's content to the "
                    + "provider, and costs more tokens — a small local model can also lose "
                    + "the thread on a long list."
            ),
            .init(
                title: "Schedule",
                body: "Each pass titles at most this many sessions, so a backlog drains "
                    + "gently instead of firing a pile of requests at once. A local model "
                    + "loading cold needs a generous timeout; a cloud API rarely needs "
                    + "more than 30 seconds."
            ),
            .init(
                title: "Defaults",
                body: "Restores the prompt and the tuning settings below it to their "
                    + "shipped values. Whether summaries are generated at all, and the "
                    + "provider and model they use, are left as you set them."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(providerGroup())
        addGroup(promptGroup())
        addGroup(contextGroup())
        addGroup(scheduleGroup())
        addGroup(resetGroup())
    }

    // MARK: - Groups

    private func providerGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "AI Summaries")

        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: AISummariesPluginControls.enableToggleTitle,
                setting: UserSettings.stenographerAISummariesEnabled
            )
        ))

        let picker = AISummariesPluginControls.makePicker(service: service)
        self.picker = picker
        group.addSettingSubview(picker)

        return group
    }

    private func promptGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Prompt")

        group.addSettingSubview(ComposableSettings.TextAreaEditView(
            with: ComposableSettings.ViewModel<String>(
                title: "Instructions sent to the model",
                setting: UserSettings.stenographerAISummaryPrompt
            ),
            visibleLines: 8,
            monospaced: true
        ))

        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<Int>(
                title: "Word limit",
                setting: UserSettings.stenographerAISummaryMaxWords,
                choices: SummaryLimits.maxWords.map {
                    .init(label: "\($0) words", value: $0)
                }
            )
        ))

        return group
    }

    private func contextGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "What the Model Sees")

        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<Int>(
                title: "Activity lines",
                setting: UserSettings.stenographerAISummaryActivityLines,
                choices: [20, 40, 60, 80, 120, 160, 200, 300, 400].map {
                    .init(label: "\($0) events", value: $0)
                }
            )
        ))

        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<Int>(
                title: "Detail per line",
                setting: UserSettings.stenographerAISummaryDetailChars,
                choices: [40, 80, 120, 200, 300, 500].map {
                    .init(label: "\($0) characters", value: $0)
                }
            )
        ))

        return group
    }

    private func scheduleGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Schedule")

        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<Int>(
                title: "Look for work every",
                setting: UserSettings.stenographerAISummaryIntervalMinutes,
                choices: [1, 2, 5, 10, 15, 30, 60, 120, 240].map {
                    .init(label: Self.minutesLabel($0), value: $0)
                }
            )
        ))

        group.addSettingSubview(ComposableSettings.StepperView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Sessions per pass",
                setting: UserSettings.stenographerAISummaryMaxPerRun,
                minValue: SummaryLimits.maxPerRun.lowerBound,
                maxValue: SummaryLimits.maxPerRun.upperBound
            )
        ))

        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<Int>(
                title: "Give up after",
                setting: UserSettings.stenographerAISummaryTimeoutSeconds,
                choices: [10, 15, 30, 60, 120, 300, 600].map {
                    .init(label: "\($0) seconds", value: $0)
                }
            )
        ))

        return group
    }

    private func resetGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Defaults")

        group.addSettingSubview(ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(
                title: "Reset to Defaults",
                wasPressedCallback: { UserSettings.resetAISummaryTuning() }
            )
        ))

        return group
    }

    /// "1 minute" / "5 minutes" / "2 hours" — an interval reads better in the
    /// largest unit that divides it evenly.
    private static func minutesLabel(_ minutes: Int) -> String {
        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
}
