import AppKit
import XCTest
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NotificationStylesSettingsPanelTests: XCTestCase {

    func testSampleCarriesTheUrgency() {
        for urgency in Notice.Urgency.allCases {
            let sample = NotificationStylesSettingsPanel.sample(for: urgency)
            XCTAssertEqual(sample.urgency, urgency)
            XCTAssertTrue(sample.state.isActive)
            XCTAssertFalse(sample.title.isEmpty)
        }
        XCTAssertNotEqual(
            NotificationStylesSettingsPanel.sample(for: .fyi).id,
            NotificationStylesSettingsPanel.sample(for: .fyi).id,
            "each test is a new notice, so it is never deduplicated away")
    }

    func testSendTestGoesThroughTheHandler() {
        _ = NSApplication.shared
        let handler = RecordingHandler()
        let styles = NotificationStylesSettingsPanel(handler: handler)
        guard let panel = styles.panel(for: .now) else { return XCTFail("no Now style") }
        panel.sendTest()
        XCTAssertEqual(handler.calls.count, 1)
        guard case .sendTest = handler.calls.first else {
            return XCTFail("expected sendTest, got \(handler.calls)")
        }
        XCTAssertEqual(panel.lastSentTest?.urgency, .now)
    }

    /// Styles is only the list of styles: one topic per urgency, in order,
    /// each with the same set of properties and its own Send test.
    func testStylesIsOnlyOneTopicPerUrgency() {
        _ = NSApplication.shared
        let styles = NotificationStylesSettingsPanel(handler: RecordingHandler())
        styles.loadViewIfNeeded()
        XCTAssertEqual(styles.descriptor.title, "Styles")
        XCTAssertEqual(
            styles.panels.map(\.descriptor.title),
            Notice.Urgency.allCases.map(NotificationStylesSettingsPanel.title(for:)))
        var rowSets: [[String]] = []
        for panel in styles.urgencyPanels {
            panel.loadViewIfNeeded()
            let text = Self.strings(in: panel.view)
            XCTAssertEqual(Self.buttons(in: panel.view, titled: "Send test").count, 1, "\(panel.urgency)")
            XCTAssertFalse(text.contains("Overrides"), "\(panel.urgency)")
            XCTAssertFalse(text.contains("Stacks, escalation and floods"), "\(panel.urgency)")
            rowSets.append(text.filter(Self.propertyLabels.contains))
        }
        for rows in rowSets {
            XCTAssertEqual(rows, Self.propertyLabels, "every style has the same properties")
        }
    }

    /// The Notifications topic lists the host's General first, then the
    /// shared Styles, Overrides and Behavior; what is not a style lives
    /// outside Styles.
    func testNotificationsTopicHoldsGeneralStylesOverridesAndBehavior() {
        _ = NSApplication.shared
        let general = ComposableSettings.SettingsPanelViewController(
            with: ComposableSettings.SettingsPanelDescriptor(title: "General"))
        let topic = NotificationsSettingsTopicPanel(general: general, handler: RecordingHandler())
        topic.loadViewIfNeeded()
        XCTAssertEqual(topic.descriptor.title, "Notifications")
        XCTAssertEqual(topic.panels.map(\.descriptor.title), ["General", "Styles", "Crawl", "Overrides", "Behavior"])
        XCTAssertTrue(topic.panels.first === general)

        topic.behavior.loadViewIfNeeded()
        let behavior = Self.strings(in: topic.behavior.view).joined(separator: "\n")
        XCTAssertTrue(behavior.contains("Stacks, escalation and floods"))
        XCTAssertTrue(behavior.contains("Hide from screen sharing"))
        XCTAssertFalse(behavior.contains("hotkeys"), "moved to the Keyboard topic")
        XCTAssertFalse(behavior.contains("Crawl direction"), "moved to the Crawl topic")
        XCTAssertTrue(behavior.contains("Unavailable — needs the Focus Status entitlement"))
        topic.overrides.loadViewIfNeeded()
        XCTAssertEqual(Self.buttons(in: topic.overrides.view, titled: "Add").count, 1)
    }

    func testTopicOrderWithExtras() {
        _ = NSApplication.shared
        let general = ComposableSettings.SettingsPanelViewController(
            with: ComposableSettings.SettingsPanelDescriptor(title: "General"))
        let keyboard = ComposableSettings.SettingsPanelViewController(
            with: ComposableSettings.SettingsPanelDescriptor(title: "Keyboard"))
        let topic = NotificationsSettingsTopicPanel(
            general: general, handler: RecordingHandler(), store: makeTestStore(), extraTopics: [keyboard])
        topic.loadViewIfNeeded()
        XCTAssertEqual(
            topic.panels.map(\.descriptor.title),
            ["General", "Styles", "Crawl", "Overrides", "Behavior", "Keyboard"])
    }

    func testOverrideTargetChoices() {
        _ = NSApplication.shared
        let panel = NotificationOverridesSettingsPanel(store: makeTestStore())
        panel.loadViewIfNeeded()
        XCTAssertEqual(
            panel.targetPopup.itemTitles,
            Notice.Urgency.allCases.map { "Use \(NotificationStylesSettingsPanel.title(for: $0)) style" }
                + ["Don't show"])
    }

    private static let propertyLabels = [
        "Dismiss after", "Can be snoozed"
    ]

    /// An urgency's row shows that urgency's own style set: an override that
    /// happens to match the sample notice must not leak into it.
    func testUrgencyRowsIgnoreOverrides() {
        var rules = NoticeRoutingRules.defaults
        let base = NotificationStylesSettingsPanel.baseStyle(for: .fyi, in: rules)
        rules.overrides = [.init(category: "test", target: .style(.emergency))]
        XCTAssertEqual(
            rules.style(for: NotificationStylesSettingsPanel.sample(for: .fyi)),
            NoticeRoutingRules.defaultStyle(for: .emergency))
        XCTAssertEqual(NotificationStylesSettingsPanel.baseStyle(for: .fyi, in: rules), base)

        rules.styles[.fyi] = nil
        XCTAssertEqual(
            NotificationStylesSettingsPanel.baseStyle(for: .fyi, in: rules),
            NoticeRoutingRules.defaultStyle(for: .fyi))
    }

    func testOverrideTargetsDescribeTheUrgencyOrHiding() {
        XCTAssertEqual(
            NotificationStylesSettingsPanel.describe(.init(source: "ci", target: .style(.now))),
            "source ci → Now style")
        XCTAssertEqual(
            NotificationStylesSettingsPanel.describe(.init(category: "spam", target: .hide)),
            "category spam → Don't show")
    }

    private static func strings(in view: NSView) -> [String] {
        var found: [String] = []
        if let field = view as? NSTextField { found.append(field.stringValue) }
        if let button = view as? NSButton { found.append(button.title) }
        return found + view.subviews.flatMap { strings(in: $0) }
    }

    private static func buttons(in view: NSView, titled title: String) -> [NSButton] {
        var found: [NSButton] = []
        if let button = view as? NSButton, button.title == title { found.append(button) }
        return found + view.subviews.flatMap { buttons(in: $0, titled: title) }
    }
}
