//
//  BrowserPaneViewController.swift
//  AgenticToolkit
//

import AppKit
import os
import WebKit
import AgenticDeveloperToolkitUI
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// A web browser in a pane: an address bar over a `WKWebView`, remembering
/// where it was so a project window reopens on the same page.
///
/// Deliberately *not* the extension webview. That one shows HTML an extension
/// hands it behind a custom scheme and opens every link in the user's default
/// browser; this one navigates the open web in place, which is what the word
/// "browser" means to the person who split a pane off for it
/// (`principle-of-least-astonishment`). The two share a `WKWebView` and the
/// quiet-presentation helper, and nothing else, so neither has to carry the
/// other's rules (`separation-of-concerns`).
///
/// What it remembers is one key, `url`, in the pane's state store. History
/// stays WebKit's own and dies with the pane: persisting a back stack is a
/// serialization format to maintain for a feature nobody asked for (`yagni`).
@MainActor
public final class BrowserPaneViewController: NSViewController {

    /// Turns what the user typed into something WebKit can load.
    ///
    /// A string with a scheme loads as written. Anything else is taken to be a
    /// host, and `https` is put in front of it — the user who types
    /// `example.com` means the site, not a file named that. Whitespace around
    /// the entry is trimmed; whitespace inside it means it was not an address,
    /// and the entry is refused rather than searched for, because a search
    /// engine is a choice this pane does not make (`explicit-over-implicit`).
    /// Returns `nil` for an entry that resolves to nothing loadable.
    public static func resolveAddress(_ entry: String) -> URL? {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return nil
        }
        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty,
           // `localhost:8080` parses as scheme `localhost` with no host; a real
           // scheme carries `//` or is one of the few that never does.
           trimmed.contains("://") || ["about", "mailto", "data", "javascript"].contains(scheme.lowercased()) {
            return url
        }
        return URL(string: "https://" + trimmed)
    }

    /// The state-store key the current address lives under.
    static let addressKey = "url"

    /// The page shown when the store remembers nothing and no home was given.
    public static let blankPage = URL(string: "about:blank")!

    private let store: PaneStateStore
    private let homeURL: URL
    private let logger = Logger(subsystem: "AgenticToolkit", category: "BrowserPane")

    public let webView: WKWebView
    let addressField = NSTextField()
    let backButton = NSButton()
    let forwardButton = NSButton()
    let reloadButton = NSButton()

    private var observations: [NSKeyValueObservation] = []

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - homeURL: What a pane with nothing remembered opens on.
    public init(store: PaneStateStore, homeURL: URL = BrowserPaneViewController.blankPage) {
        self.store = store
        self.homeURL = homeURL
        let configuration = WKWebViewConfiguration()
        // The default data store, shared with every other browser pane: a login
        // in one pane is a login in the next, which is what a browser does.
        configuration.websiteDataStore = .default()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 480), configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.keepPaintingUnderQuietPresentation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public var onPaneTitleChange: (() -> Void)?

    /// The address the pane will restore to: what the store remembers, else
    /// the home page.
    var restorationURL: URL {
        if let remembered = store.paneStateValue(forKey: Self.addressKey),
           let url = URL(string: remembered) {
            return url
        }
        return homeURL
    }

    // MARK: - View

    public override func loadView() {
        let root = ThemedBackgroundView(role: .windowBackground)
        view = root

        configureButton(backButton, symbol: "chevron.left", label: "Back", action: #selector(goBack))
        configureButton(forwardButton, symbol: "chevron.right", label: "Forward", action: #selector(goForward))
        configureButton(reloadButton, symbol: "arrow.clockwise", label: "Reload", action: #selector(reload))

        addressField.placeholderString = "Enter an address"
        addressField.target = self
        addressField.action = #selector(navigateToTypedAddress)
        // Enter navigates; clicking elsewhere must not, or a half-typed address
        // would load the moment the user reached for the page.
        (addressField.cell as? NSTextFieldCell)?.sendsActionOnEndEditing = false
        addressField.lineBreakMode = .byTruncatingTail
        addressField.usesSingleLineMode = true
        addressField.setAccessibilityIdentifier("browser.address")
        addressField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let bar = NSStackView(views: [backButton, forwardButton, reloadButton, addressField])
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.spacing = 4
        bar.edgeInsets = NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        bar.translatesAutoresizingMaskIntoConstraints = false

        webView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bar)
        root.addSubview(webView)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor),
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            webView.topAnchor.constraint(equalTo: bar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        observeWebView()
        webView.load(URLRequest(url: restorationURL))
    }

    private func configureButton(_ button: NSButton, symbol: String, label: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.imagePosition = .imageOnly
        button.bezelStyle = .texturedRounded
        button.isBordered = true
        button.toolTip = label
        button.target = self
        button.action = action
        button.setAccessibilityIdentifier("browser." + label.lowercased())
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    /// Title, address and the back/forward affordances all follow the web view
    /// rather than being set by whichever code path happened to navigate —
    /// a link click, a redirect and a typed address all land here the same way.
    private func observeWebView() {
        observations = [
            webView.observe(\.title, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.onPaneTitleChange?() }
            },
            webView.observe(\.url, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.addressDidChange() }
            },
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.backButton.isEnabled = self?.webView.canGoBack ?? false }
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.forwardButton.isEnabled = self?.webView.canGoForward ?? false }
            }
        ]
    }

    private func addressDidChange() {
        guard let url = webView.url else { return }
        // A field being edited is the user's; overwriting it mid-keystroke
        // because a redirect landed would throw away what they typed. A field
        // has an editor exactly while it is being edited, so that is the test
        // -- not a comparison against the window's first responder, which is
        // nil on both sides before the pane is in a window, as it is when the
        // restoration load lands.
        if addressField.currentEditor() == nil {
            addressField.stringValue = url == Self.blankPage ? "" : url.absoluteString
        }
        store.setPaneStateValue(url == Self.blankPage ? nil : url.absoluteString, forKey: Self.addressKey)
        onPaneTitleChange?()
    }

    // MARK: - Actions

    @objc private func navigateToTypedAddress() {
        guard let url = Self.resolveAddress(addressField.stringValue) else {
            logger.info("browser pane refused address: \(self.addressField.stringValue, privacy: .public)")
            return
        }
        load(url)
    }

    /// Navigates the pane. Public so a host — a link in a note, a scripting
    /// command — can point it somewhere without going through the field.
    public func load(_ url: URL) {
        webView.load(URLRequest(url: url))
        view.window?.makeFirstResponder(webView)
    }

    @objc private func goBack() { webView.goBack() }
    @objc private func goForward() { webView.goForward() }
    @objc private func reload() { webView.reload() }
}

// MARK: - Pane capabilities

extension BrowserPaneViewController: PaneTitleProviding {

    /// The page's title; its host while the title is still blank; "Browser"
    /// for a pane that is on nothing yet.
    public var paneTitle: String {
        if let title = webView.title, !title.isEmpty { return title }
        if let host = webView.url?.host, !host.isEmpty { return host }
        return "Browser"
    }
}

extension BrowserPaneViewController: PaneMinimizedRepresenting {
    public var paneMinimizedSymbolName: String { "globe" }
    public var paneMinimizedTooltip: String { paneTitle }
}

extension BrowserPaneViewController: PaneContentTeardown {

    /// Stops the page and drops the delegates: a navigation that completes
    /// into a discarded pane would otherwise call back into it.
    public func paneContentWillBeDiscarded() {
        observations.removeAll()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
}

// MARK: - WebKit delegates

extension BrowserPaneViewController: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        // A cancelled load is the next navigation starting, not a failure.
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        logger.error("browser pane failed to load: \(error.localizedDescription, privacy: .public)")
    }
}

extension BrowserPaneViewController: WKUIDelegate {

    /// A `target="_blank"` link asks for a new window. A pane has no windows to
    /// give it, so the link opens here instead — in the pane the user is
    /// looking at, which is where a click goes everywhere else.
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
