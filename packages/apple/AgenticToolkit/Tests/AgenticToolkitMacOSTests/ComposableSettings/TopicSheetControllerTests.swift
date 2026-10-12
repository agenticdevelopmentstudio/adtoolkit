import AppKit
import XCTest
@testable import AgenticToolkitMacOS

@MainActor
final class TopicSheetControllerTests: XCTestCase {

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
    ) -> ComposableSettings.TopicSheetController {
        ComposableSettings.TopicSheetController(
            title: "Edit", panels: [StubPanel("One"), StubPanel("Two")],
            validate: validate, onFinish: finished)
    }

    func testTheSplitHoldsEveryPanelInTheOrderGiven() {
        let sheet = make()
        XCTAssertEqual(sheet.split.panels.count, 2)
        XCTAssertEqual(sheet.split.panels.map(\.descriptor.title), ["One", "Two"])
    }

    func testOKWithAProblemShowsItAndStaysOpen() {
        var finishes: [Bool] = []
        let sheet = make(validate: { "Name is empty." }, finished: { finishes.append($0) })
        sheet.ok()
        XCTAssertEqual(sheet.problem, "Name is empty.")
        XCTAssertTrue(finishes.isEmpty)
    }

    func testOKWithNoProblemFinishesTrueOnce() {
        var finishes: [Bool] = []
        let sheet = make(finished: { finishes.append($0) })
        sheet.ok()
        sheet.ok()
        sheet.cancel()
        XCTAssertEqual(finishes, [true])
        XCTAssertNil(sheet.problem)
    }

    func testCancelFinishesFalseWithoutValidating() {
        var finishes: [Bool] = []
        var validated = false
        let sheet = make(validate: { validated = true; return nil }, finished: { finishes.append($0) })
        sheet.cancel()
        sheet.ok()
        XCTAssertEqual(finishes, [false])
        XCTAssertFalse(validated)
    }

    func testShowProblemNilClearsTheLine() {
        let sheet = make()
        sheet.showProblem("Bad.")
        XCTAssertEqual(sheet.problem, "Bad.")
        sheet.showProblem(nil)
        XCTAssertNil(sheet.problem)
    }

    func testOnOKReplacesFinishingAndTheOwnerFinishesLater() {
        var finishes: [Bool] = []
        var okCalls = 0
        let sheet = make(finished: { finishes.append($0) })
        sheet.onOK = { okCalls += 1 }
        sheet.ok()
        XCTAssertEqual(okCalls, 1)
        XCTAssertTrue(finishes.isEmpty)
        sheet.finish(true)
        sheet.finish(false)
        XCTAssertEqual(finishes, [true])
    }

    func testOnOKIsNotCalledWhenValidationFails() {
        var okCalls = 0
        let sheet = make(validate: { "No." })
        sheet.onOK = { okCalls += 1 }
        sheet.ok()
        XCTAssertEqual(okCalls, 0)
        XCTAssertEqual(sheet.problem, "No.")
    }

    func testOKEnabledTogglesTheButton() {
        let sheet = make()
        _ = sheet.view
        XCTAssertTrue(sheet.okEnabled)
        sheet.okEnabled = false
        XCTAssertFalse(sheet.okEnabled)
        sheet.okEnabled = true
        XCTAssertTrue(sheet.okEnabled)
    }

    func testOKClearsAStaleProblemBeforeValidating() {
        var fail = true
        let sheet = make(validate: { fail ? "Bad." : nil })
        sheet.ok()
        XCTAssertEqual(sheet.problem, "Bad.")
        fail = false
        sheet.ok()
        XCTAssertNil(sheet.problem)
    }
}
