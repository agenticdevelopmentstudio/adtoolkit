import AppKit

import AgenticToolkitCore

/// Attention tab: how long done items stay, and which kinds also post a system notification.
@MainActor
public final class PartnerAttentionSettingsViewController: ComposableSettings.SettingsPanelViewController {

    private let settings: SettingsStore

    public init(settings: SettingsStore = UserSettings.shared) {
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Attention", icon: NSImage(systemSymbolName: "bell", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["attention", "needs you", "notification", "retention", "question", "blocked"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Attention",
                  body: "Items the partner raises appear in the Needs-you pane. Done items stay for the "
                      + "retention period, then are removed. A kind that is checked also posts a macOS "
                      + "notification when an item of that kind is raised.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let settings = self.settings

        let keep = ComposableSettings.GroupView(withTitle: "Done Items")
        keep.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Keep done items (days)", minValue: 1, maxValue: 365,
                get: { settings.get(UserSettings.partnerAttentionRetentionDays) },
                set: { settings.set($0, for: UserSettings.partnerAttentionRetentionDays) })))
        addGroup(keep)

        let notify = ComposableSettings.GroupView(withTitle: "System Notifications")
        for kind in AttentionKind.allCases {
            let view = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
                title: "Notify for \(kind.rawValue)",
                get: { settings.get(UserSettings.partnerNotifyKinds).contains(kind.rawValue) },
                set: { isOn in
                    var kinds = settings.get(UserSettings.partnerNotifyKinds)
                    if isOn { kinds.insert(kind.rawValue) } else { kinds.remove(kind.rawValue) }
                    settings.set(kinds, for: UserSettings.partnerNotifyKinds)
                }))
            _ = view.toggle.accessibilityID("settings.partner.notify.\(kind.rawValue)")
            notify.addSettingSubview(view)
        }
        addGroup(notify)
    }
}
