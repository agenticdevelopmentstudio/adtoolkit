import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class BrowserPaneTests: XCTestCase {

    // MARK: - Resolving what was typed

    func testAnEntryWithASchemeLoadsAsWritten() {
        XCTAssertEqual(
            BrowserPaneViewController.resolveAddress("http://example.com/path?q=1"),
            URL(string: "http://example.com/path?q=1")
        )
        XCTAssertEqual(
            BrowserPaneViewController.resolveAddress("about:blank"),
            BrowserPaneViewController.blankPage
        )
    }

    func testABareHostGetsHTTPS() {
        XCTAssertEqual(
            BrowserPaneViewController.resolveAddress("example.com"),
            URL(string: "https://example.com")
        )
        XCTAssertEqual(
            BrowserPaneViewController.resolveAddress("  example.com/docs  "),
            URL(string: "https://example.com/docs"),
            "surrounding whitespace is trimmed, not refused"
        )
    }

    /// `localhost:8080` parses as scheme `localhost`, which is not a scheme
    /// anyone meant; it is a host and a port.
    func testAHostWithAPortIsAHostNotAScheme() {
        XCTAssertEqual(
            BrowserPaneViewController.resolveAddress("localhost:8080"),
            URL(string: "https://localhost:8080")
        )
    }

    func testAnEntryWithInnerWhitespaceIsRefused() {
        XCTAssertNil(BrowserPaneViewController.resolveAddress("how do I"),
                     "a search is a choice the pane does not make")
        XCTAssertNil(BrowserPaneViewController.resolveAddress(""))
        XCTAssertNil(BrowserPaneViewController.resolveAddress("   "))
    }

    // MARK: - Remembering where it was

    func testAFreshPaneOpensOnTheHomePage() {
        let home = URL(string: "https://example.com/home")!
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), homeURL: home)
        XCTAssertEqual(pane.restorationURL, home)
    }

    func testAPaneRestoresTheAddressItsStoreRemembers() {
        let store = EphemeralPaneStateStore()
        store.setPaneStateValue("https://example.com/remembered", forKey: BrowserPaneViewController.addressKey)
        let pane = BrowserPaneViewController(store: store, homeURL: BrowserPaneViewController.blankPage)
        XCTAssertEqual(pane.restorationURL, URL(string: "https://example.com/remembered"))
    }

    func testAnUnparsableRememberedAddressFallsBackToHome() {
        let store = EphemeralPaneStateStore()
        store.setPaneStateValue("not a url", forKey: BrowserPaneViewController.addressKey)
        let pane = BrowserPaneViewController(store: store)
        XCTAssertEqual(pane.restorationURL, BrowserPaneViewController.blankPage)
    }

    // MARK: - Naming itself

    func testAPaneOnNothingIsCalledBrowser() {
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore())
        XCTAssertEqual(pane.paneTitle, "Browser")
        XCTAssertEqual(pane.paneMinimizedSymbolName, "globe")
    }

    // MARK: - Registration

    func testRegisterBrowserVendsTheBrowserPane() {
        let registry = ComposableTabsViewRegistry()
        registry.registerBrowser(preferredAxis: .horizontal)
        XCTAssertEqual(ComposableTabsViewID.browser.rawValue, "browser",
                       "the raw value is persisted in layout_nodes")
        XCTAssertTrue(registry.isRegistered(.browser))
        XCTAssertEqual(registry.descriptor(for: .browser).displayName, "Browser")
    }
}
