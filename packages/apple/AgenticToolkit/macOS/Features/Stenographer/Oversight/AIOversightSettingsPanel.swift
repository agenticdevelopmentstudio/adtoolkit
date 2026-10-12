import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// "AI Oversight" settings: whether the daemon watches live sessions, whether it
/// asks a model for judgment, and which provider/model it asks.
@MainActor
public final class AIOversightSettingsPanel: ComposableSettings.SettingsPanelViewController {

    private let service: any StenographerDaemonService

    /// Retained: the picker owns the setting observers that keep the provider list
    /// and model row live. (Pushing to the daemon is owned centrally by
    /// `StenographerOversightPrefsPush`, not by this panel.)
    private var picker: DaemonProviderPickerView?

    public init(service: any StenographerDaemonService) {
        self.service = service
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "AI Oversight",
            icon: NSImage(systemSymbolName: "eye", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "AI Oversight",
                body: "When enabled, the always-on daemon periodically watches your live "
                    + "sessions and records findings when one needs attention — for now, "
                    + "when a session's context window is filling up and should be "
                    + "compacted at a clean breakpoint. Findings appear in the AI "
                    + "Oversight window (Window menu). AI judgment asks the selected "
                    + "provider whether now is a good moment; off, the deterministic rules "
                    + "run alone. The provider defaults to the AI Summaries selection."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(oversightGroup())
    }

    private func oversightGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "AI Oversight")

        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: AIOversightProviderControls.enableToggleTitle,
                setting: UserSettings.stenographerAIOversightEnabled
            )
        ))

        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: AIOversightProviderControls.llmToggleTitle,
                setting: UserSettings.stenographerAIOversightLLMEnabled
            )
        ))

        let picker = AIOversightProviderControls.makePicker(service: service)
        self.picker = picker
        group.addSettingSubview(picker)

        return group
    }
}
