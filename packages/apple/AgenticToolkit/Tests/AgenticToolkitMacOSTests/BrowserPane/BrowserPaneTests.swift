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
        let pane = BrowserPaneViewController(store: store, settings: makeSettings())
        XCTAssertEqual(pane.restorationURL, BrowserPaneViewController.blankPage)
    }

    /// The Home Page setting is the user's; the registration's `homeURL` is
    /// the host's. The user's wins, and a remembered page beats both.
    func testTheHomePageSettingBeatsTheRegistrationsHome() {
        let settings = makeSettings()
        settings.set("example.com", for: UserSettings.browserHomePage)
        let hostHome = URL(string: "https://host.example/start")!

        let fresh = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings, homeURL: hostHome)
        XCTAssertEqual(fresh.restorationURL, URL(string: "https://example.com"))

        let store = EphemeralPaneStateStore()
        store.setPaneStateValue("https://example.com/remembered", forKey: BrowserPaneViewController.addressKey)
        let remembered = BrowserPaneViewController(store: store, settings: settings, homeURL: hostHome)
        XCTAssertEqual(remembered.restorationURL, URL(string: "https://example.com/remembered"))
    }

    // MARK: - Following the settings

    func testThePaneFollowsLiveSettingsAsTheyChange() {
        let settings = makeSettings()
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        XCTAssertEqual(pane.webView.pageZoom, 1.0)
        XCTAssertNil(pane.webView.customUserAgent)
        XCTAssertFalse(pane.webView.isInspectable)

        settings.set(1.5, for: UserSettings.browserPageZoom)
        settings.set("Kitchen/1.0", for: UserSettings.browserCustomUserAgent)
        settings.set(true, for: UserSettings.browserWebInspectorEnabled)
        settings.set(12, for: UserSettings.browserMinimumFontSize)
        settings.set(false, for: UserSettings.browserBlocksPopups)
        settle()

        XCTAssertEqual(pane.webView.pageZoom, 1.5)
        XCTAssertEqual(pane.webView.customUserAgent, "Kitchen/1.0")
        XCTAssertTrue(pane.webView.isInspectable)
        XCTAssertEqual(pane.webView.configuration.preferences.minimumFontSize, 12)
        XCTAssertTrue(pane.webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically)
    }

    func testZoomIsClampedToTheOfferedRange() {
        let settings = makeSettings()
        settings.set(10.0, for: UserSettings.browserPageZoom)
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        XCTAssertEqual(pane.webView.pageZoom, BrowserSettings.pageZoomRange.upperBound)
    }

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    /// Settings changes reach the pane through `receive(on: .main)`; one turn
    /// of the run loop delivers them.
    private func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
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
        registry.registerBrowser(preferredAxis: .horizontal, settings: makeSettings())
        XCTAssertEqual(ComposableTabsViewID.browser.rawValue, "browser",
                       "the raw value is persisted in layout_nodes")
        XCTAssertTrue(registry.isRegistered(.browser))
        XCTAssertEqual(registry.descriptor(for: .browser).displayName, "Browser")
    }
}
