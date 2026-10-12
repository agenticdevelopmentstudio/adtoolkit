//
//  BrowserPaneViewController.swift
//  AgenticToolkit
//

import AppKit
import Combine
import os
import UniformTypeIdentifiers
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
/// What it remembers in its own state store is one key, `url`. Everything
/// else it honours comes from the Browser settings (`BrowserSettings.swift`):
/// read once where WebKit fixes a value at construction, and followed live
/// everywhere WebKit lets a value change under a page.
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
    private let settings: SettingsStore
    private let history: BrowserHistoryStore?
    private let siteData: BrowserSiteData
    private let fallbackHomeURL: URL
    private let logger = Logger(subsystem: "AgenticToolkit", category: "BrowserPane")

    public let webView: WKWebView
    let addressField = NSTextField()
    let backButton = NSButton()
    let forwardButton = NSButton()
    let reloadButton = NSButton()

    private var observations: [NSKeyValueObservation] = []
    private var cancellables: Set<AnyCancellable> = []
    private var downloads: [WKDownload] = []
    /// The history row for the page on screen, so a title that arrives after
    /// the load is filed against it rather than lost.
    private var currentVisitID: Int64?
    /// Counts page loads, so a visit row that comes back from the file after
    /// the pane has moved on to the next page is not filed as the current one.
    private var visitGeneration = 0

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours. The app's shared
    ///     store by default; a test hands in an in-memory one.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    public init(
        store: PaneStateStore,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        homeURL: URL = BrowserPaneViewController.blankPage
    ) {
        self.store = store
        self.settings = settings
        self.history = history
        self.fallbackHomeURL = homeURL
        let configuration = Self.makeConfiguration(settings: settings)
        self.siteData = BrowserSiteData(dataStore: configuration.websiteDataStore)
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 480), configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.keepPaintingUnderQuietPresentation()
        applyLiveSettings()
        applyCookiePolicy()
        observeSettings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public var onPaneTitleChange: (() -> Void)?

    /// The address the pane will restore to: what the store remembers, else
    /// the Home Page setting, else the registration's home.
    var restorationURL: URL {
        if let remembered = store.paneStateValue(forKey: Self.addressKey),
           let url = URL(string: remembered) {
            return url
        }
        return BrowserSettings.homePage(in: settings) ?? fallbackHomeURL
    }

    // MARK: - Settings

    /// The configuration WebKit fixes when the web view is made. The settings
    /// read here take effect for the *next* browser pane, and the panel says
    /// so beside each of them.
    static func makeConfiguration(settings: SettingsStore) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        // Private browsing is a data store that lives only as long as the
        // pane; otherwise the default store, shared with every other browser
        // pane, so a login in one pane is a login in the next.
        configuration.websiteDataStore = settings.get(UserSettings.browserPrivateBrowsing)
            ? .nonPersistent()
            : .default()
        configuration.upgradeKnownHostsToHTTPS = settings.get(UserSettings.browserUpgradesToHTTPS)
        configuration.allowsAirPlayForMediaPlayback = settings.get(UserSettings.browserAllowsAirPlay)
        configuration.mediaTypesRequiringUserActionForPlayback = switch settings.get(UserSettings.browserAutoplay) {
        case .allowed: []
        case .mutedOnly: .audio
        case .never: .all
        }
        return configuration
    }

    /// Every setting WebKit lets change under a page, applied from the store.
    /// Called once at construction and again whenever a browser key changes.
    private func applyLiveSettings() {
        let zoom = settings.get(UserSettings.browserPageZoom)
        let zoomRange = BrowserSettings.pageZoomRange
        webView.pageZoom = min(max(zoom, zoomRange.lowerBound), zoomRange.upperBound)
        let agent = settings.get(UserSettings.browserCustomUserAgent)
        webView.customUserAgent = agent.isEmpty ? nil : agent
        webView.isInspectable = settings.get(UserSettings.browserWebInspectorEnabled)

        let preferences = webView.configuration.preferences
        let fontSize = settings.get(UserSettings.browserMinimumFontSize)
        let fontRange = BrowserSettings.minimumFontSizeRange
        preferences.minimumFontSize = CGFloat(min(max(fontSize, fontRange.lowerBound), fontRange.upperBound))
        preferences.javaScriptCanOpenWindowsAutomatically = !settings.get(UserSettings.browserBlocksPopups)
        preferences.isFraudulentWebsiteWarningEnabled = settings.get(UserSettings.browserFraudWarning)
    }

    /// The cookie policy belongs to the data store, not the web view, and the
    /// persistent store is shared by every non-private pane. The pane still
    /// applies it, because a private pane's store has no other owner — but
    /// only when the cookie setting itself changes, not on every browser
    /// change: a zoom slider drag is not a reason for every open pane to
    /// rewrite the shared store's policy once per tick.
    private func applyCookiePolicy() {
        let acceptsCookies = settings.get(UserSettings.browserAcceptsCookies)
        Task { await siteData.setAcceptsCookies(acceptsCookies) }
    }

    private func observeSettings() {
        settings.changes
            .filter { $0.hasPrefix("browser.") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] key in
                self?.applyLiveSettings()
                if key == UserSettings.browserAcceptsCookies.name { self?.applyCookiePolicy() }
            }
            .store(in: &cancellables)
    }

    /// Forgets visits older than the retention setting allows. Run as the
    /// pane comes up, so an old history shrinks without anyone opening the
    /// panel to ask it to.
    private func pruneHistory() {
        guard let history, let cutoff = settings.get(UserSettings.browserHistoryRetention).cutoff() else { return }
        Task { [logger] in
            do {
                try await history.perform { try $0.removeVisits(before: cutoff) }
            } catch {
                logger.error("browser history prune failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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
        pruneHistory()
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
                MainActor.assumeIsolated { self?.titleDidChange() }
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

    private func titleDidChange() {
        onPaneTitleChange?()
        guard let visitID = currentVisitID, let title = webView.title, !title.isEmpty else { return }
        file(title, againstVisit: visitID)
    }

    private func file(_ title: String, againstVisit visitID: Int64) {
        guard let history else { return }
        Task { [logger] in
            do {
                try await history.perform { try $0.updateTitle(ofVisit: visitID, to: title) }
            } catch {
                logger.error("browser history title update failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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
        onPaneTitleChange?()
    }

    /// Writes the address the pane will reopen on. Once per committed
    /// navigation rather than on every change of `webView.url` — a redirect
    /// chain or a fragment change reports several — and only when it differs
    /// from what is remembered, since the store is a database write.
    private func rememberAddress() {
        let address = webView.url.flatMap { $0 == Self.blankPage ? nil : $0.absoluteString }
        guard address != store.paneStateValue(forKey: Self.addressKey) else { return }
        store.setPaneStateValue(address, forKey: Self.addressKey)
    }

    /// Files the page that just finished loading. Only pages, only when the
    /// setting says so, and never the blank page.
    private func recordVisit() {
        currentVisitID = nil
        visitGeneration += 1
        guard let history, settings.get(UserSettings.browserRecordsHistory),
              let url = webView.url, url != Self.blankPage else { return }
        let generation = visitGeneration
        let title = webView.title ?? ""
        Task { [weak self, logger] in
            do {
                let visitID = try await history.perform { try $0.record(url, title: title) }
                guard let self, self.visitGeneration == generation else { return }
                self.currentVisitID = visitID
                // A title that arrived while the row was being written found
                // no row to be filed against; file it now.
                if let later = self.webView.title, !later.isEmpty, later != title {
                    self.file(later, againstVisit: visitID)
                }
            } catch {
                logger.error("browser history record failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Actions

    @objc private func navigateToTypedAddress() {
        guard let url = Self.resolveAddress(addressField.stringValue) else {
            // What was typed is the user's, and may be anything; it stays out
            // of the public log.
            logger.info("browser pane refused address: \(self.addressField.stringValue, privacy: .private)")
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

    /// Stops the page, cancels its downloads and drops the delegates: a
    /// navigation or a transfer that completes into a discarded pane would
    /// otherwise call back into it.
    public func paneContentWillBeDiscarded() {
        observations.removeAll()
        cancellables.removeAll()
        downloads.forEach { $0.cancel() }
        downloads.removeAll()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
}

// MARK: - Navigation

extension BrowserPaneViewController: WKNavigationDelegate {

    /// Per navigation, and read off the settings each time, so switching
    /// JavaScript or Lockdown Mode takes effect on the next page rather than
    /// the next pane. WebKit picks **one** `decidePolicyFor` overload, so the
    /// download decision lives here too.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        preferences.allowsContentJavaScript = settings.get(UserSettings.browserJavaScriptEnabled)
        preferences.isLockdownModeEnabled = settings.get(UserSettings.browserLockdownMode)
        return (navigationAction.shouldPerformDownload ? .download : .allow, preferences)
    }

    /// A response the web view cannot show — a zip, a disk image — is a
    /// download, which is what every browser does with one.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        navigationResponse.canShowMIMEType ? .allow : .download
    }

    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        adopt(download)
    }

    public func webView(
        _ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload
    ) {
        adopt(download)
    }

    /// The visit on record is the page being left. WebKit publishes the
    /// new page's title before `didFinish` files its visit, so a title that
    /// lands while a load is in flight would otherwise be written onto the
    /// previous page's row.
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        currentVisitID = nil
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        rememberAddress()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        recordVisit()
    }

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

// MARK: - Downloads

extension BrowserPaneViewController: WKDownloadDelegate {

    private func adopt(_ download: WKDownload) {
        download.delegate = self
        downloads.append(download)
    }

    /// A file name that does not collide with one already in `directory`:
    /// `name.ext`, then `name 2.ext`, `name 3.ext` — `UniqueName`'s count,
    /// the one every "New Project" and renamed record uses (`dry`).
    static func uniqueDestination(for suggestedName: String, in directory: URL) -> URL {
        let name = suggestedName.isEmpty ? "download" : suggestedName
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let taken = ((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? [])
            .filter { ($0 as NSString).pathExtension == ext }
            .map { ($0 as NSString).deletingPathExtension }
        let stem = UniqueName.next(base: base, taken: taken)
        return directory.appendingPathComponent(ext.isEmpty ? stem : "\(stem).\(ext)")
    }

    public func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        if settings.get(UserSettings.browserAsksDownloadLocation) {
            // Asking needs a window to ask on. A pane with none is not a
            // reason to save somewhere the user was never shown
            // (`explicit-over-implicit`): refuse the download instead.
            guard let window = view.window else {
                logger.error("browser download refused: asked to choose a location with no window to ask on")
                return nil
            }
            let panel = NSSavePanel()
            panel.nameFieldStringValue = suggestedFilename
            panel.directoryURL = BrowserSettings.downloadDirectory(in: settings)
            panel.canCreateDirectories = true
            let response = await panel.beginSheetModal(for: window)
            guard response == .OK, let chosen = panel.url else { return nil }
            // Replace was answered on the sheet. `WKDownload` refuses to write
            // over an existing file, so the file goes first, and if it will
            // not go the download fails here rather than after the transfer.
            if FileManager.default.fileExists(atPath: chosen.path) {
                do {
                    try FileManager.default.removeItem(at: chosen)
                } catch {
                    logger.error(
                        "browser download could not replace the file: \(error.localizedDescription, privacy: .public)")
                    return nil
                }
            }
            return chosen
        }
        let directory = BrowserSettings.downloadDirectory(in: settings)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            logger.error("browser download folder unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        return Self.uniqueDestination(for: suggestedFilename, in: directory)
    }

    public func downloadDidFinish(_ download: WKDownload) {
        downloads.removeAll { $0 === download }
        // The host says which site it came from; the path and query can carry
        // a token or a name, and stay out of the public log.
        let host = download.originalRequest?.url?.host ?? ""
        logger.info("browser download finished from \(host, privacy: .public)")
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeAll { $0 === download }
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        logger.error("browser download failed: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - UI delegate

extension BrowserPaneViewController: WKUIDelegate {

    /// A `target="_blank"` link asks for a new window. A pane has no windows to
    /// give it, so the link opens here instead — in the pane the user is
    /// looking at, which is where a click goes everywhere else.
    ///
    /// A script's `window.open()` with no address asks for a blank window to
    /// write into later. There is nothing to open for that, and loading the
    /// blank page here would throw away the page on screen and the address
    /// the pane remembers, so it is refused.
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url, url != Self.blankPage else { return nil }
        webView.load(navigationAction.request)
        return nil
    }

    /// Camera and microphone, decided by the Media setting: granted or refused
    /// outright, or asked about — on the pane's window, naming the site, so
    /// the answer is given to the page that asked and nothing else.
    public func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        switch settings.get(UserSettings.browserMediaCapture) {
        case .allow: return .grant
        case .deny: return .deny
        case .ask: break
        }
        guard let window = view.window else { return .prompt }
        let device = switch type {
        case .camera: "camera"
        case .microphone: "microphone"
        case .cameraAndMicrophone: "camera and microphone"
        @unknown default: "camera or microphone"
        }
        let alert = NSAlert()
        alert.messageText = "\(origin.host) wants to use your \(device)."
        alert.informativeText = "Browser settings decide whether sites ask, are always allowed, or never are."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don’t Allow")
        let response = await alert.beginSheetModal(for: window)
        return response == .alertFirstButtonReturn ? .grant : .deny
    }
}
