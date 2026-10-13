import XCTest
import AppKit
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class AutomationSettingsPanelTests: XCTestCase {

    private func field(_ id: String, in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField, field.accessibilityIdentifier() == id { return field }
        for sub in view.subviews { if let found = field(id, in: sub) { return found } }
        return nil
    }

    private func button(_ id: String, in view: NSView) -> NSButton? {
        if let button = view as? NSButton, button.accessibilityIdentifier() == id { return button }
        for sub in view.subviews { if let found = button(id, in: sub) { return found } }
        return nil
    }

    /// Only the selected topic is in the view tree, and a split selects its
    /// first topic when it appears in a window, which these tests have none
    /// of — so the topic is chosen here: 0 is Browser, 1 is Endpoint.
    private func makePanel(status: AutomationServerStatus,
                           topic: Int) -> AutomationSettingsPanelViewController {
        let settings = UserSettings(with: InMemorySettingsStorageProvider(),
                                    secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let panel = AutomationSettingsPanelViewController(status: status, settings: settings)
        _ = panel.view
        panel.selectPanel(at: topic)
        return panel
    }

    func testStatusLineNamesThePortAndRegistration() {
        let status = AutomationServerStatus()
        status.port = 51477
        status.isRegistered = false
        let panel = makePanel(status: status, topic: 1)
        let line = field("settings.automation.status", in: panel.view)
        XCTAssertEqual(line?.stringValue, "Listening on port 51477. Not registered with Claude Code.")
        status.isRegistered = true
        XCTAssertEqual(line?.stringValue, "Listening on port 51477. Registered with Claude Code.")
    }

    func testFailureReasonIsTheStatusLine() {
        let status = AutomationServerStatus()
        status.failureReason = "could not write /x/mcp-token: Permission denied"
        let panel = makePanel(status: status, topic: 1)
        XCTAssertEqual(field("settings.automation.status", in: panel.view)?.stringValue,
                       "Not running: could not write /x/mcp-token: Permission denied")
    }

    func testCopyPutsTheClaudeCommandOnThePasteboard() {
        let status = AutomationServerStatus()
        status.port = 51477
        status.token = "tok"
        let panel = makePanel(status: status, topic: 1)
        let copy = button("settings.automation.copy-command", in: panel.view)
        XCTAssertNotNil(copy)
        copy?.performClick(nil)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string),
                       MCPRegistration.claudeCommand(port: 51477, token: "tok"))
    }

    func testCheckboxesCarryTheirIdentifiers() {
        let panel = makePanel(status: AutomationServerStatus(), topic: 0)
        XCTAssertNotNil(button("settings.automation.enabled", in: panel.view))
        XCTAssertNotNil(button("settings.automation.evaluate", in: panel.view))
    }
}
