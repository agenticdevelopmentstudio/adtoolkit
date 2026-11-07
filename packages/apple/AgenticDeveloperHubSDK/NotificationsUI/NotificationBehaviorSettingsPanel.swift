import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// Notifications › Behavior: the toast stack, escalation and flood
/// thresholds, screen sharing and Focus —
/// everything about presentation that is not one urgency's style.
@MainActor
final class NotificationBehaviorSettingsPanel: ComposableSettings.SettingsPanelViewController {

    private let controls: NoticeRulesControls

    init(store: SettingsStore) {
        self.controls = NoticeRulesControls(store: store)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Behavior",
            icon: NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Behavior")))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var searchKeywords: [String] {
        ["stack", "escalation", "flood", "screen sharing", "focus"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(thresholdsGroup())
        addGroup(privacyGroup())
        let focus = ComposableSettings.GroupView(withTitle: "Focus")
        focus.addSettingSubview(ComposableSettings.ValueRowView(
            title: "Hold notices during Focus", value: "Unavailable — needs the Focus Status entitlement"))
        addGroup(focus)
    }

    private func thresholdsGroup() -> ComposableSettings.GroupView {
        let controls = controls
        let group = ComposableSettings.GroupView(withTitle: "Stacks, escalation and floods")
        let rules = controls.rules
        group.addSettingSubview(controls.row("Toasts shown per stack", controls.popup(
            Array(1...8), selected: rules.toastStackLimit, title: { "\($0)" },
            onChange: { limit in controls.mutate { $0.toastStackLimit = limit } })))
        let waits: [TimeInterval] = [0, 300, 900, 1800, 3600]
        group.addSettingSubview(controls.row("Raise Soon to Now after", controls.popup(
            Self.including(rules.escalation.soonToNowAfter, in: waits),
            selected: rules.escalation.soonToNowAfter, title: Self.waitTitle) { wait in
                controls.mutate { $0.escalation.soonToNowAfter = wait }
            }))
        group.addSettingSubview(controls.row("Raise Eventually to Soon after", controls.popup(
            Self.including(rules.escalation.eventuallyToSoonAfter, in: waits),
            selected: rules.escalation.eventuallyToSoonAfter, title: Self.waitTitle) { wait in
                controls.mutate { $0.escalation.eventuallyToSoonAfter = wait }
            }))
        group.addSettingSubview(controls.row("Fold a source after", controls.popup(
            Self.including(rules.flood.threshold, in: [3, 5, 10, 20]),
            selected: rules.flood.threshold, title: { "\($0) notices" },
            onChange: { threshold in controls.mutate { $0.flood.threshold = threshold } })))
        group.addSettingSubview(controls.row("Within", controls.popup(
            Self.including(rules.flood.window, in: [5, 10, 30, 60]),
            selected: rules.flood.window, title: { "\(Int($0)) seconds" },
            onChange: { window in controls.mutate { $0.flood.window = window } })))
        return group
    }

    private func privacyGroup() -> ComposableSettings.GroupView {
        let controls = controls
        let group = ComposableSettings.GroupView(withTitle: "Sharing")
        let rules = controls.rules
        group.addSettingSubview(controls.row("Hide from screen sharing", controls.checkbox(
            rules.hideFromScreenSharing) { isOn in
                controls.mutate { $0.hideFromScreenSharing = isOn }
            }))
        return group
    }

    private static func including<Value: Comparable>(_ value: Value, in values: [Value]) -> [Value] {
        values.contains(value) ? values : (values + [value]).sorted()
    }

    private static func waitTitle(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "Never" }
        return seconds >= 3600 && seconds.truncatingRemainder(dividingBy: 3600) == 0
            ? "\(Int(seconds / 3600)) hour\(seconds == 3600 ? "" : "s")"
            : "\(Int(seconds / 60)) minutes"
    }
}
