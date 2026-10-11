//
//  BrowserPane.swift
//  AgenticToolkit
//

import AppKit
import AgenticToolkitCore

extension ComposableTabsViewID {
    /// A pane holding a web browser. The raw value is persisted in
    /// `layout_nodes`, so it is a storage format: changing it orphans every
    /// saved layout that holds a browser.
    public static let browser = ComposableTabsViewID("browser")
}

extension ComposableTabsViewRegistry {

    /// Registers the browser pane: an address bar over a web view, reopening
    /// on the page it was last on.
    ///
    /// The same shape as `registerTerminal(preferredAxis:)`, so a host adds a
    /// browser the way it adds a shell — one call, no factory to write.
    ///
    /// - Parameters:
    ///   - preferredAxis: Which way the Split menu proposes adding another
    ///     browser. Side by side suits a pane that wants width.
    ///   - homeURL: What a fresh pane opens on when the Home Page setting is
    ///     blank. Blank by default: the address field is right there, and a
    ///     start page is a choice the host or the user makes.
    ///   - settings: The browser settings every pane honours. The app's
    ///     shared store by default — the same one the settings panel edits.
    ///   - history: Where panes record visits; `nil` records nothing. The
    ///     host hands the same store to `BrowserSettingsPanelViewController`,
    ///     so the panel lists what the panes wrote.
    @MainActor
    public func registerBrowser(
        preferredAxis: ComposableTabsAxis,
        homeURL: URL = BrowserPaneViewController.blankPage,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil
    ) {
        register(
            .browser,
            descriptor: .init(
                displayName: "Browser",
                symbolName: "globe",
                preferredAxis: preferredAxis,
                // Room for the address bar's three buttons plus an address
                // worth reading, and for a page laid out for a narrow window.
                minimumThickness: 360
            )
        ) { context in
            BrowserPaneViewController(
                store: context.makeStateStore(prefix: "browser."),
                settings: settings,
                history: history,
                homeURL: homeURL
            )
        }
    }
}
