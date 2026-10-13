import XCTest
import WebKit
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class BrowserPaneAutomationTests: XCTestCase {

    private func makePane() -> BrowserPaneViewController {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        _ = pane.view
        return pane
    }

    private func load(_ html: String, into pane: BrowserPaneViewController) async {
        pane.webView.loadHTMLString(html, baseURL: nil)
        for _ in 0..<200 where pane.webView.isLoading { try? await Task.sleep(nanoseconds: 10_000_000) }
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    /// The `[ref=...]` on the first snapshot line that names `role`.
    private func ref(ofRole role: String, in snapshot: BrowserSnapshot) -> String? {
        for line in snapshot.text.split(separator: "\n") where line.contains("- \(role)") {
            guard let start = line.range(of: "[ref=") else { continue }
            let rest = line[start.upperBound...]
            if let end = rest.firstIndex(of: "]") { return String(rest[..<end]) }
        }
        return nil
    }

    func testConsoleScriptIsInstalledOnThePane() async {
        let pane = makePane()
        await load("<script>console.warn('hello pane')</script>", into: pane)
        XCTAssertEqual(pane.consoleLog.messages(level: nil).map(\.text), ["hello pane"])
    }

    func testConsoleIsClearedOnNavigation() async {
        let pane = makePane()
        await load("<script>console.log('first')</script>", into: pane)
        await load("<p>second</p>", into: pane)
        XCTAssertTrue(pane.consoleLog.messages(level: nil).isEmpty)
    }

    func testBadgeShowsWhileDrivingAndHidesAfterTheHold() async throws {
        let pane = makePane()
        await load("<button id='b'>Go</button>", into: pane)
        XCTAssertFalse(pane.drivenBadge.isShowing)
        await pane.automation.drive { }
        XCTAssertTrue(pane.drivenBadge.isShowing, "the badge stays up through the hold")
        try await Task.sleep(nanoseconds: 2_300_000_000)
        XCTAssertFalse(pane.drivenBadge.isShowing)
    }

    func testBadgeHasTheAccessibilityIdentifier() {
        let pane = makePane()
        XCTAssertEqual(pane.drivenBadge.accessibilityIdentifier(), "browser.driven")
        XCTAssertEqual(pane.drivenBadge.toolTip, "A model is driving this pane")
    }

    func testAlertDuringAnActionIsDismissedAndReported() async throws {
        let pane = makePane()
        await load("<button id='b' onclick=\"alert('careful')\">Go</button>", into: pane)
        let snapshot = try await pane.automation.snapshot(BrowserSnapshotOptions())
        let button = try XCTUnwrap(ref(ofRole: "button", in: snapshot))
        let delta = try await pane.automation.click(ref: button, generation: snapshot.generation, native: false)
        XCTAssertEqual(delta.dialog?.kind, .alert)
        XCTAssertEqual(delta.dialog?.message, "careful")
    }

    func testConfirmOutsideAnActionIsDismissedWithFalse() async {
        let pane = makePane()
        await load("<script>window.answer = null</script>", into: pane)
        _ = try? await pane.webView.evaluateJavaScript("window.answer = confirm('sure?')")
        try? await Task.sleep(nanoseconds: 100_000_000)
        let answer = try? await pane.webView.evaluateJavaScript("String(window.answer)") as? String
        XCTAssertEqual(answer, "false")
    }
}
