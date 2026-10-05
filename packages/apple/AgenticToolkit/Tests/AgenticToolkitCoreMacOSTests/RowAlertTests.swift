import AppKit
import Testing
@testable import AgenticToolkitCoreMacOS

@MainActor
private func yesNoCancel() -> NSAlert {
    let alert = NSAlert()
    alert.messageText = "Remove installed tools before first run?"
    alert.informativeText = "Removes only the tools. No data is removed."
    alert.addButton(withTitle: "Yes")
    alert.addButton(withTitle: "No")
    alert.addButton(withTitle: "Cancel")
    return alert
}

@MainActor @Suite struct RowAlertTests {
    @Test func twoButtonsStayANativeAlert() {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        #expect(!RowAlert.usesPanel(for: alert))
        #expect(RowAlert.usesPanel(for: yesNoCancel()))
    }

    @Test func threeButtonsShareOneRow() {
        let panel = RowAlertPanel(yesNoCancel())
        panel.window.contentView?.layoutSubtreeIfNeeded()
        let rows = Set(panel.buttons.map { Int($0.convert($0.bounds, to: nil).midY) })
        #expect(rows.count == 1)
    }

    /// Don't Save … Cancel Save: the default rightmost, Cancel just left of
    /// it, the other button at the far left.
    @Test func defaultRightmostCancelBesideItOtherFarLeft() {
        let panel = RowAlertPanel(yesNoCancel())
        panel.window.contentView?.layoutSubtreeIfNeeded()
        let left = panel.buttons.map { $0.convert($0.bounds, to: nil).minX }
        let (yesX, noX, cancelX) = (left[0], left[1], left[2])
        #expect(noX < cancelX)
        #expect(cancelX < yesX)
        // The far-left button lines up with the text, not with Cancel.
        #expect(cancelX - noX > RowAlertPanelSpacing.betweenGroups)
    }

    @Test func returnIsTheDefaultAndEscapeCancels() {
        let panel = RowAlertPanel(yesNoCancel())
        #expect(panel.buttons[0].keyEquivalent == "\r")
        #expect(panel.buttons[1].keyEquivalent == "")
        #expect(panel.buttons[2].keyEquivalent == "\u{1b}")
    }

    @Test func eachButtonAnswersInTheOrderItWasAdded() {
        let panel = RowAlertPanel(yesNoCancel())
        var answers: [NSApplication.ModalResponse] = []
        panel.respond = { answers.append($0) }
        panel.buttons.forEach { $0.performClick(nil) }
        #expect(answers == [.alertFirstButtonReturn, .alertSecondButtonReturn, .alertThirdButtonReturn])
    }

    @Test func showsTheAlertsText() {
        let panel = RowAlertPanel(yesNoCancel())
        let labels = allSubviews(of: panel.window.contentView).compactMap { ($0 as? NSTextField)?.stringValue }
        #expect(labels.contains("Remove installed tools before first run?"))
        #expect(labels.contains("Removes only the tools. No data is removed."))
    }

    private func allSubviews(of view: NSView?) -> [NSView] {
        guard let view else { return [] }
        return view.subviews + view.subviews.flatMap { allSubviews(of: $0) }
    }
}

/// The gap the test expects between the left button and the right-hand pair:
/// wider than the 12pt between paired buttons.
private enum RowAlertPanelSpacing {
    static let betweenGroups: CGFloat = 82 + 24
}
