import AppKit
import Testing
@testable import AgenticToolkitCoreMacOS

@MainActor
private func removeSkipCancel() -> NSAlert {
    let alert = NSAlert()
    alert.messageText = "Remove installed tools before first run?"
    alert.informativeText = "Removes only the tools. No data is removed."
    alert.addButton(withTitle: "Remove Tools")
    alert.addButton(withTitle: "Skip")
    alert.addButton(withTitle: "Cancel")
    return alert
}

@MainActor @Suite struct RowAlertTests {
    @Test func twoButtonsStayANativeAlert() {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        #expect(!RowAlert.usesPanel(for: alert))
        #expect(RowAlert.usesPanel(for: removeSkipCancel()))
    }

    @Test func threeButtonsShareOneRow() {
        let panel = RowAlertPanel(removeSkipCancel())
        panel.window.contentView?.layoutSubtreeIfNeeded()
        let rows = Set(panel.buttons.map { Int($0.convert($0.bounds, to: nil).midY) })
        #expect(rows.count == 1)
    }

    /// Cancel … Skip Remove Tools: Cancel alone at the far left, the default
    /// rightmost, the other button just left of it.
    @Test func cancelFarLeftDefaultRightmostOtherBesideIt() {
        let panel = RowAlertPanel(removeSkipCancel())
        panel.window.contentView?.layoutSubtreeIfNeeded()
        let left = panel.buttons.map { $0.convert($0.bounds, to: nil).minX }
        let (removeX, skipX, cancelX) = (left[0], left[1], left[2])
        #expect(cancelX < skipX)
        #expect(skipX < removeX)
        // Cancel lines up with the text, apart from the pair on the right.
        #expect(skipX - cancelX > RowAlertPanelSpacing.betweenGroups)
    }

    @Test func returnIsTheDefaultAndEscapeCancels() {
        let panel = RowAlertPanel(removeSkipCancel())
        #expect(panel.buttons[0].keyEquivalent == "\r")
        #expect(panel.buttons[1].keyEquivalent == "")
        #expect(panel.buttons[2].keyEquivalent == "\u{1b}")
    }

    @Test func eachButtonAnswersInTheOrderItWasAdded() {
        let panel = RowAlertPanel(removeSkipCancel())
        var answers: [NSApplication.ModalResponse] = []
        panel.respond = { answers.append($0) }
        panel.buttons.forEach { $0.performClick(nil) }
        #expect(answers == [.alertFirstButtonReturn, .alertSecondButtonReturn, .alertThirdButtonReturn])
    }

    @Test func buttonsKeepTheirKeyEquivalentsAndModifiers() {
        let alert = removeSkipCancel()
        alert.buttons[1].keyEquivalent = "s"
        alert.buttons[1].keyEquivalentModifierMask = [.command]
        let panel = RowAlertPanel(alert)
        #expect(panel.buttons[1].keyEquivalent == "s")
        #expect(panel.buttons[1].keyEquivalentModifierMask == [.command])
    }

    @Test func escapeGoesToTheButtonThatClaimsIt() {
        let alert = removeSkipCancel()
        alert.buttons[2].keyEquivalent = ""
        alert.buttons[1].keyEquivalent = "\u{1b}"
        let panel = RowAlertPanel(alert)
        #expect(panel.buttons[1].keyEquivalent == "\u{1b}")
        #expect(panel.buttons[2].keyEquivalent == "")
    }

    @Test func escapeFallsBackToTheButtonTitledCancel() {
        let alert = NSAlert()
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")
        let panel = RowAlertPanel(alert)
        #expect(panel.buttons[1].keyEquivalent == "\u{1b}")
        #expect(panel.buttons[2].keyEquivalent == "")
    }

    @Test func aNonzeroTagIsTheResponseAndZeroFallsBackToPosition() {
        let alert = removeSkipCancel()
        alert.buttons[0].tag = 77
        alert.buttons[1].tag = 0
        let panel = RowAlertPanel(alert)
        var answers: [NSApplication.ModalResponse] = []
        panel.respond = { answers.append($0) }
        panel.buttons.forEach { $0.performClick(nil) }
        #expect(answers == [NSApplication.ModalResponse(rawValue: 77),
                            .alertSecondButtonReturn,
                            NSApplication.ModalResponse(rawValue: alert.buttons[2].tag)])
    }

    @Test func showsTheAlertsText() {
        let panel = RowAlertPanel(removeSkipCancel())
        let labels = allSubviews(of: panel.window.contentView).compactMap { ($0 as? NSTextField)?.stringValue }
        #expect(labels.contains("Remove installed tools before first run?"))
        #expect(labels.contains("Removes only the tools. No data is removed."))
    }

    private func allSubviews(of view: NSView?) -> [NSView] {
        guard let view else { return [] }
        return view.subviews + view.subviews.flatMap { allSubviews(of: $0) }
    }
}

/// The gap the test expects between Cancel and the right-hand pair: wider
/// than the 12pt between paired buttons.
private enum RowAlertPanelSpacing {
    static let betweenGroups: CGFloat = 82 + 24
}
