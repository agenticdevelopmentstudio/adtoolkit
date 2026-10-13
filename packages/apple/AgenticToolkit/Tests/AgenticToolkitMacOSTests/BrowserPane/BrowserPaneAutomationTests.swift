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

    private var loads = 0

    /// Loads `html` and waits, with a deadline, until the page on screen is
    /// this one and has finished loading, and then until `until` holds.
    ///
    /// Polls for the page itself rather than for `isLoading`: right after
    /// `loadHTMLString` the web view can still report `false`, so a loop on
    /// `isLoading` could exit before the load had even started. A marker that
    /// changes on every load tells this page from the one before it.
    private func load(
        _ html: String,
        into pane: BrowserPaneViewController,
        until: () -> Bool = { true }
    ) async {
        loads += 1
        let marker = "load-\(loads)"
        pane.webView.loadHTMLString("<meta name=\"test-load\" content=\"\(marker)\">" + html, baseURL: nil)
        let probe = "document.readyState === 'complete' && "
            + "document.querySelector('meta[name=test-load]')?.content === '\(marker)'"
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let loaded = (try? await pane.webView.evaluateJavaScript(probe) as? Bool) ?? false
            if loaded && !pane.webView.isLoading && until() { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
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
        await load("<script>console.warn('hello pane')</script>", into: pane) {
            !pane.consoleLog.messages(level: nil).isEmpty
        }
        XCTAssertEqual(pane.consoleLog.messages(level: nil).map(\.text), ["hello pane"])
    }

    func testConsoleIsClearedOnNavigation() async {
        let pane = makePane()
        await load("<script>console.log('first')</script>", into: pane) {
            !pane.consoleLog.messages(level: nil).isEmpty
        }
        XCTAssertFalse(pane.consoleLog.messages(level: nil).isEmpty, "the first page must have logged")
        await load("<p>second</p>", into: pane)
        XCTAssertTrue(pane.consoleLog.messages(level: nil).isEmpty)
    }

    func testBadgeShowsWhileDrivingAndHidesAfterTheHold() async throws {
        let pane = makePane()
        await load("<button id='b'>Go</button>", into: pane)
        XCTAssertFalse(pane.drivenBadge.isShowing)
        try await pane.automation.drive { }
        XCTAssertTrue(pane.drivenBadge.isShowing, "the badge stays up through the hold")
        let deadline = Date().addingTimeInterval(6)
        while pane.drivenBadge.isShowing && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertFalse(pane.drivenBadge.isShowing, "the badge must hide once the hold is over")
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
        let automation = pane.automation
        let delta = try await automation.drive {
            try await automation.click(ref: button, generation: snapshot.generation, native: false)
        }
        XCTAssertEqual(delta.dialog?.kind, .alert)
        XCTAssertEqual(delta.dialog?.message, "careful")
    }

    /// WebKit raises on a second handler under a name still registered, so
    /// adding the name again without a crash proves teardown removed it.
    func testTeardownRemovesTheConsoleMessageHandler() {
        let pane = makePane()
        pane.paneContentWillBeDiscarded()
        let controller = pane.webView.configuration.userContentController
        controller.add(pane.consoleLog, name: BrowserConsoleLog.handlerName)
        controller.removeScriptMessageHandler(forName: BrowserConsoleLog.handlerName)
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
