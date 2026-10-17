import AppKit
import XCTest
@testable import AgenticToolkitMacOS

@MainActor
final class TopicDialogWindowTests: XCTestCase {

    private final class StubPanel: NSViewController, ComposableSettingsPanel {
        let descriptor: ComposableSettings.SettingsPanelDescriptor
        var hostsOwnScroll: Bool { false }
        var helpContent: ComposableSettings.PanelHelp? { nil }
        var effectiveHelpContent: ComposableSettings.PanelHelp? { nil }
        init(_ title: String) {
            descriptor = ComposableSettings.SettingsPanelDescriptor(title: title)
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError() }
        override func loadView() { view = NSView() }
    }

    private func make(
        validate: @escaping () -> String? = { nil },
        finished: @escaping (Bool) -> Void = { _ in }
    ) -> ComposableSettings.TopicDialogWindow {
        let dialog = ComposableSettings.TopicDialogWindow(
            windowID: "test.topic-dialog.\(UUID().uuidString)", title: "Edit",
            panels: [StubPanel("Zebra"), StubPanel("Apple")],
            validate: validate, onFinish: finished)
        addTeardownBlock { @MainActor in dialog.finish(false) }
        return dialog
    }

    func testTheTopicsKeepTheOrderGiven() {
        let dialog = make()
        XCTAssertEqual(dialog.split.panels.map(\.descriptor.title), ["Zebra", "Apple"])
        XCTAssertFalse(dialog.split.showsSidebarSearch)
    }

    func testTheWindowIsAResizableDialogWithTheHelpDrawerAndToolbar() {
        let dialog = make()
        guard let window = dialog.prepare() else { return XCTFail("no window") }
        XCTAssertTrue(window.styleMask.contains(.resizable))
        XCTAssertTrue(window.styleMask.contains(.closable))
        XCTAssertFalse(window.styleMask.contains(.miniaturizable))
        XCTAssertNotNil(window.toolbar)
        XCTAssertNotNil(dialog.split.helpPresenter)
        XCTAssertEqual(dialog.split.selectedPanel?.descriptor.title, "Zebra")
        XCTAssertEqual(dialog.toolbarTitle(forPanel: "Zebra"), "Edit — Zebra")
    }

    func testAnOwnerCanGiveTheFirstSize() {
        let dialog = make()
        dialog.windowSpec = WindowSpec(defaultSize: NSSize(width: 1000, height: 640),
                                       minSize: NSSize(width: 900, height: 500),
                                       defaultPosition: .center, persistsFrame: false)
        guard let window = dialog.prepare() else { return XCTFail("no window") }
        XCTAssertEqual(window.frame.size, NSSize(width: 1000, height: 640))
        // The minimum is the spec's, with the toolbar's height added to the frame.
        XCTAssertEqual(window.minSize.width, 900)
        XCTAssertGreaterThanOrEqual(window.minSize.height, 500)
    }

    func testTheButtonsAreStandardPushButtonsUnderThePanels() {
        let dialog = make()
        guard let window = dialog.prepare() else { return XCTFail("no window") }
        window.layoutIfNeeded()
        for button in [dialog.cancelButton, dialog.okButton] {
            XCTAssertEqual(button.bezelStyle, .push)
            XCTAssertEqual(button.controlSize, .regular)
            XCTAssertGreaterThanOrEqual(button.frame.height, 20)
        }
        XCTAssertEqual(dialog.okButton.keyEquivalent, "\r")
        XCTAssertEqual(dialog.cancelButton.keyEquivalent, "\u{1b}")
        // The buttons sit at the bottom right and the panels take the height.
        guard let footer = dialog.split.detailFooterView, let content = window.contentView else {
            return XCTFail("no footer")
        }
        XCTAssertLessThan(footer.frame.height, 100)
        XCTAssertGreaterThan(content.frame.height - footer.frame.height, 300)
        let okFrame = dialog.okButton.convert(dialog.okButton.bounds, to: nil)
        let cancelFrame = dialog.cancelButton.convert(dialog.cancelButton.bounds, to: nil)
        XCTAssertGreaterThan(okFrame.minX, cancelFrame.maxX)
        XCTAssertLessThan(okFrame.minY, 60)
    }

    func testOKWithAProblemShowsItAndStaysOpen() {
        var finishes: [Bool] = []
        let dialog = make(validate: { "Name is empty." }, finished: { finishes.append($0) })
        dialog.ok()
        XCTAssertEqual(dialog.problem, "Name is empty.")
        XCTAssertFalse(dialog.problemLabel.isHidden)
        XCTAssertTrue(finishes.isEmpty)
    }

    func testOKWithNoProblemFinishesTrueOnce() {
        var finishes: [Bool] = []
        let dialog = make(finished: { finishes.append($0) })
        dialog.ok()
        dialog.ok()
        dialog.cancel()
        XCTAssertEqual(finishes, [true])
        XCTAssertNil(dialog.problem)
    }

    func testCancelFinishesFalseWithoutValidating() {
        var finishes: [Bool] = []
        var validated = false
        let dialog = make(validate: { validated = true; return nil }, finished: { finishes.append($0) })
        dialog.cancel()
        dialog.ok()
        XCTAssertEqual(finishes, [false])
        XCTAssertFalse(validated)
    }

    func testTheCloseButtonCancels() {
        var finishes: [Bool] = []
        let dialog = make(finished: { finishes.append($0) })
        guard let window = dialog.prepare() else { return XCTFail("no window") }
        XCTAssertFalse(dialog.windowShouldClose(window))
        XCTAssertEqual(finishes, [false])
        XCTAssertFalse(window.isVisible)
    }

    func testOnOKReplacesFinishingAndDisablesOK() {
        var finishes: [Bool] = []
        var okCalls = 0
        let dialog = make(finished: { finishes.append($0) })
        dialog.onOK = { okCalls += 1 }
        dialog.ok()
        dialog.ok()
        XCTAssertEqual(okCalls, 1)
        XCTAssertFalse(dialog.okEnabled)
        XCTAssertTrue(finishes.isEmpty)
        dialog.showProblem("Save failed.")
        dialog.okEnabled = true
        XCTAssertTrue(dialog.okButton.isEnabled)
        dialog.finish(true)
        dialog.finish(false)
        XCTAssertEqual(finishes, [true])
    }

    func testOKClearsAStaleProblemBeforeValidating() {
        var fail = true
        let dialog = make(validate: { fail ? "Bad." : nil })
        dialog.ok()
        XCTAssertEqual(dialog.problem, "Bad.")
        fail = false
        dialog.ok()
        XCTAssertNil(dialog.problem)
        XCTAssertTrue(dialog.problemLabel.isHidden)
    }

    /// An owner presents the dialog and keeps no reference to it; the dialog
    /// must still be there when its modal session starts, and gone once finished.
    func testAPresentedDialogKeepsItselfUntilFinished() {
        weak var held: ComposableSettings.TopicDialogWindow?
        autoreleasepool {
            let dialog = ComposableSettings.TopicDialogWindow(
                windowID: "test.topic-dialog.\(UUID().uuidString)", title: "Edit",
                panels: [StubPanel("Only")], validate: { nil }, onFinish: { _ in })
            held = dialog
            dialog.present()
        }
        guard let dialog = held else { return XCTFail("the dialog was released before it was shown") }
        // Finishing before the session starts also stops it from starting.
        dialog.finish(false)
        XCTAssertFalse(dialog.window?.isVisible ?? false)
    }

    func testAFooterCanBeRemovedAndThePanelsTakeTheHeightBack() {
        let split = ComposableSettings.SplitViewController()
        split.setPanels([StubPanel("One")])
        let footer = NSView()
        split.detailFooterView = footer
        _ = split.view
        XCTAssertNotNil(footer.superview)
        split.detailFooterView = nil
        XCTAssertNil(footer.superview)
    }
}
