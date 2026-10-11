//
//  BrowserSettingsPanelViewController.swift
//  AgenticToolkit
//

import AppKit
import Combine
import WebKit

import AgenticDeveloperToolkitUI
import AgenticToolkitCore

/// Settings panel for the Browser pane: a topic list on the left — General,
/// History, Cookies and Site Data, Privacy and Security, Media and
/// Permissions, Downloads, Developer, Reset — and the chosen topic's controls
/// on the right, the shape the Language Servers panel has.
///
/// Every row here binds to the app's shared settings (`UserSettings.shared`),
/// which is what the rows' view models read, and what `BrowserPaneViewController`
/// follows. The two things that are not settings — the visit history and
/// WebKit's site data — are handed in, because they are stores with files
/// behind them and a test must be able to point them elsewhere
/// (`dependency-injection`).
///
/// **Every setting shown is one the pane honours.** The ones WebKit fixes when
/// a web view is created say "new browser panes" in their explanation, so the
/// panel never promises an effect the open pane cannot deliver
/// (`principle-of-least-astonishment`).
@MainActor
public final class BrowserSettingsPanelViewController: ComposableSettings.SettingsPanelSplitViewController {

    private let history: BrowserHistoryStore?
    private let siteData: BrowserSiteData

    /// - Parameters:
    ///   - history: where the pane records visits; `nil` means the host records
    ///     none, and the History topic says so.
    ///   - siteData: WebKit's persistent store, which every non-private pane
    ///     shares. A test hands in a non-persistent one.
    public init(history: BrowserHistoryStore?, siteData: BrowserSiteData = BrowserSiteData()) {
        self.history = history
        self.siteData = siteData
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Browser",
            icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shown while no topic is selected; each topic carries its own.
    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Browser",
                body: "The Browser pane is a web browser inside a project window: an address "
                    + "bar over a page. These topics decide how its pages load, what it "
                    + "remembers about where you have been, what sites may keep and do, "
                    + "and where downloads land. Pick a topic on the left."
            ),
            .init(
                title: "When a Change Takes Effect",
                body: "Most settings apply to every open browser pane as you change them. "
                    + "A few are fixed by WebKit when a pane is created — private "
                    + "browsing, the HTTPS upgrade, autoplay and AirPlay — and those say "
                    + "so beside the control: they apply to browser panes opened after "
                    + "the change. JavaScript and Lockdown Mode apply to the next page a "
                    + "pane loads."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addPanel(BrowserGeneralPanel())
        addPanel(BrowserHistoryPanel(history: history))
        addPanel(BrowserSiteDataPanel(siteData: siteData))
        addPanel(BrowserPrivacyPanel())
        addPanel(BrowserMediaPanel())
        addPanel(BrowserDownloadsPanel())
        addPanel(BrowserDeveloperPanel())
        addPanel(BrowserResetPanel())
    }
}

// MARK: - General

@MainActor
private final class BrowserGeneralPanel: ComposableSettings.SettingsPanelViewController {

    init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General",
            icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Home Page",
                body: "What a new browser pane opens on when it has no page to go back to. "
                    + "Blank opens an empty page, with the address bar ready. A bare host "
                    + "such as example.com gets https:// in front, exactly as it would in "
                    + "the address bar. A pane that was closed on a page reopens on that "
                    + "page, not the home page."
            ),
            .init(
                title: "Page",
                body: "Zoom scales every page, from half size to three times, and applies "
                    + "to open panes at once. Minimum font size stops a page using text "
                    + "smaller than this many points; zero lets the page decide. "
                    + "JavaScript off applies to the next page each pane loads, and most "
                    + "of the web stops working without it. Block pop-up windows refuses "
                    + "a window a page opens on its own; a link that opens a new window "
                    + "still loads, in the same pane."
            ),
            .init(
                title: "User Agent",
                body: "The name the browser gives sites. Blank uses WebKit's own, which is "
                    + "what Safari sends. A custom string applies to pages loaded after "
                    + "the change. Some sites serve a different page to a browser they "
                    + "do not recognise, which is the reason to change it and the reason "
                    + "to leave it alone."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["home page", "start page", "zoom", "font size", "javascript", "pop-up", "popup", "user agent"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeHomeGroup())
        settingsView.addGroup(makePageGroup())
        settingsView.addGroup(makeUserAgentGroup())
    }

    private func makeHomeGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Home Page")
        let home = ComposableSettings.ViewModel<String>(
            title: "Address",
            setting: UserSettings.browserHomePage,
            explanation: "Blank opens an empty page. A host without a scheme gets https:// in front."
        )
        let field = ComposableSettings.TextEditView(with: home)
        field.textField.placeholderString = "example.com"
        _ = field.textField.accessibilityID("settings.browser.general.home-page")
        group.addSettingSubview(field)
        return group
    }

    private func makePageGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Page")

        let zoom = ComposableSettings.RangeViewModel<Double>(
            title: "Zoom",
            setting: UserSettings.browserPageZoom,
            minValue: BrowserSettings.pageZoomRange.lowerBound,
            maxValue: BrowserSettings.pageZoomRange.upperBound
        )
        let zoomView = ComposableSettings.CaptionedSliderView(viewModel: zoom) { "\(Int(($0 * 100).rounded()))%" }
        _ = zoomView.slider.accessibilityID("settings.browser.general.zoom")
        group.addSettingSubview(zoomView)

        let fontSize = ComposableSettings.RangeViewModel<Int>(
            title: "Minimum font size",
            setting: UserSettings.browserMinimumFontSize,
            minValue: BrowserSettings.minimumFontSizeRange.lowerBound,
            maxValue: BrowserSettings.minimumFontSizeRange.upperBound,
            explanation: "In points. Zero lets each page choose its own."
        )
        let fontView = ComposableSettings.IntegerFieldView(viewModel: fontSize)
        _ = fontView.textField.accessibilityID("settings.browser.general.minimum-font-size")
        group.addSettingSubview(fontView)

        let javaScript = ComposableSettings.ViewModel<Bool>(
            title: "Enable JavaScript",
            setting: UserSettings.browserJavaScriptEnabled,
            explanation: "Applies to the next page each pane loads."
        )
        let javaScriptView = ComposableSettings.CheckboxView(with: javaScript)
        _ = javaScriptView.toggle.accessibilityID("settings.browser.general.javascript")
        group.addSettingSubview(javaScriptView)

        let popups = ComposableSettings.ViewModel<Bool>(
            title: "Block pop-up windows",
            setting: UserSettings.browserBlocksPopups
        )
        let popupsView = ComposableSettings.CheckboxView(with: popups)
        _ = popupsView.toggle.accessibilityID("settings.browser.general.block-popups")
        group.addSettingSubview(popupsView)

        return group
    }

    private func makeUserAgentGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "User Agent")
        let agent = ComposableSettings.ViewModel<String>(
            title: "Custom user agent",
            setting: UserSettings.browserCustomUserAgent,
            explanation: "Blank sends WebKit's own. Applies to pages loaded after the change."
        )
        let field = ComposableSettings.TextEditView(with: agent)
        field.textField.placeholderString = "Default"
        _ = field.textField.accessibilityID("settings.browser.general.user-agent")
        group.addSettingSubview(field)
        return group
    }
}

// MARK: - History

@MainActor
private final class BrowserHistoryPanel: ComposableSettings.SettingsPanelViewController {

    private let history: BrowserHistoryStore?
    private let searchField = NSSearchField()
    private let countRow = ComposableSettings.ValueRowView(title: "Visits recorded", value: "0")
    private var table: ComposableSettings.EditableTableCard?
    private var visits: [BrowserVisit] = []

    private static let whenFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    init(history: BrowserHistoryStore?) {
        self.history = history
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "History",
            icon: NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Recording",
                body: "With recording on, every page a browser pane finishes loading is "
                    + "written down: its address, its title and when. Off, nothing new is "
                    + "written and what is already recorded stays until you clear it. Keep "
                    + "visits for decides how long a visit is kept: anything older is "
                    + "forgotten the next time a browser pane opens."
            ),
            .init(
                title: "Visits",
                body: "How many visits are recorded, and a search over them — type part "
                    + "of an address or a title and the list below narrows to the "
                    + "matches, newest first."
            ),
            .init(
                title: "Recent Visits",
                body: "The latest two hundred visits, or the matches for the search. "
                    + "Select one and press − to forget it. Clear History forgets every "
                    + "visit at once; it does not touch cookies or site data, which "
                    + "have their own topic. The pages a pane can go back to are "
                    + "WebKit's own and are not listed here."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["history", "visits", "recent", "clear history", "forget"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeRecordingGroup())
        settingsView.addGroup(makeVisitsGroup())
        let table = makeTable()
        self.table = table
        settingsView.addGroup(table)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reload()
    }

    private func makeRecordingGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Recording")

        let records = ComposableSettings.ViewModel<Bool>(
            title: "Record history",
            setting: UserSettings.browserRecordsHistory,
            explanation: history == nil
                ? "This app has no history store, so nothing is recorded whatever this says."
                : nil
        )
        let recordsView = ComposableSettings.CheckboxView(with: records)
        _ = recordsView.toggle.accessibilityID("settings.browser.history.record")
        group.addSettingSubview(recordsView)

        let retention = ComposableSettings.ChoiceViewModel<BrowserHistoryRetention>(
            title: "Keep visits for",
            setting: UserSettings.browserHistoryRetention,
            choices: BrowserHistoryRetention.allCases.map { .init(label: $0.label, value: $0) },
            explanation: "Older visits are forgotten when a browser pane opens."
        )
        let retentionView = ComposableSettings.PopupMenuChoiceView(viewModel: retention)
        _ = retentionView.popUpButton.accessibilityID("settings.browser.history.retention")
        group.addSettingSubview(retentionView)

        return group
    }

    private func makeVisitsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Visits")
        _ = countRow.valueLabel.accessibilityID("settings.browser.history.count")
        group.addSettingSubview(countRow)

        searchField.placeholderString = "Search addresses and titles"
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.sendsSearchStringImmediately = true
        searchField.translatesAutoresizingMaskIntoConstraints = false
        _ = searchField.accessibilityID("settings.browser.history.search")
        group.addSettingSubview(searchField)
        return group
    }

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Recent Visits",
            columns: [
                .init(id: "when", title: "When", width: 130),
                .init(id: "title", title: "Title", width: 180),
                .init(id: "url", title: "Address", width: 260)
            ],
            emptyMessage: history == nil ? "No history store." : "No visits recorded.",
            visibleRows: 10,
            accessibilityPrefix: "settings.browser.history.visits"
        )
        // A history is removed from, never added to by hand.
        table.addButton.isHidden = true
        table.onRemove = { [weak self] rowID in
            guard let self, let history = self.history, let id = Int64(rowID) else { return }
            do {
                try history.remove(visit: id)
            } catch {
                ComposableSettings.Alerts.report(
                    "Could not forget that visit: \(error.localizedDescription)", on: self.view.window
                )
            }
            self.reload()
        }
        let clear = table.addFooterButton(
            title: "Clear History…", identifier: "settings.browser.history.clear"
        ) { [weak self] in
            self?.clearHistory()
        }
        clear.isEnabled = history != nil
        return table
    }

    @objc private func searchChanged() {
        reload()
    }

    private func clearHistory() {
        guard let history else { return }
        ComposableSettings.Alerts.confirmDestructive(
            "Clear all browsing history?",
            detail: "Every recorded visit is forgotten. Cookies and site data are not affected.",
            actionTitle: "Clear",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            do {
                try history.removeAll()
            } catch {
                ComposableSettings.Alerts.report(
                    "Could not clear history: \(error.localizedDescription)", on: self.view.window
                )
            }
            self.reload()
        }
    }

    private func reload() {
        guard let history else {
            visits = []
            table?.setRows([])
            countRow.value = "0"
            return
        }
        do {
            let text = searchField.stringValue.trimmingCharacters(in: .whitespaces)
            visits = text.isEmpty ? try history.recent() : try history.search(text)
            countRow.value = String(try history.count())
        } catch {
            ComposableSettings.Alerts.report("Could not read history: \(error.localizedDescription)", on: view.window)
            visits = []
        }
        table?.setRows(visits.map { visit in
            ComposableSettings.EditableTableRow(id: String(visit.id), cells: [
                "when": .text(Self.whenFormatter.string(from: visit.visitedAt)),
                "title": visit.title.isEmpty ? .placeholder("Untitled") : .text(visit.title),
                "url": .text(visit.url.absoluteString)
            ])
        })
    }
}

// MARK: - Cookies and site data

@MainActor
private final class BrowserSiteDataPanel: ComposableSettings.SettingsPanelViewController {

    private let siteData: BrowserSiteData
    private var table: ComposableSettings.EditableTableCard?
    private var records: [WKWebsiteDataRecord] = []

    init(siteData: BrowserSiteData) {
        self.siteData = siteData
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Cookies and Site Data",
            icon: NSImage(systemSymbolName: "tray.full", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Cookies",
                body: "Accept cookies is WebKit's one switch for whether sites may set "
                    + "cookies at all; there is no first-party-only middle, because WebKit "
                    + "offers none. Off, most sites cannot keep you signed in. Private "
                    + "browsing gives each new browser pane a store of its own that is "
                    + "thrown away when the pane closes — nothing it visits lands in the "
                    + "list below. It applies to panes opened after the change; a pane "
                    + "already open keeps the store it was made with."
            ),
            .init(
                title: "Site Data",
                body: "Everything WebKit is keeping for sites the browser has visited, one "
                    + "row per site: cookies, local storage, caches, service workers and "
                    + "the rest, named in the second column. Select a site and press − to "
                    + "remove what it kept, which signs you out of it. Remove All clears "
                    + "every site at once. Refresh re-reads the list, since pages write "
                    + "while it is open. Browsing history is separate and has its own "
                    + "topic."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["cookies", "site data", "local storage", "cache", "private browsing", "incognito", "sign out"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeCookiesGroup())
        let table = makeTable()
        self.table = table
        settingsView.addGroup(table)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reload()
    }

    private func makeCookiesGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Cookies")

        let accepts = ComposableSettings.ViewModel<Bool>(
            title: "Accept cookies",
            setting: UserSettings.browserAcceptsCookies,
            explanation: "Off, sites cannot keep you signed in."
        )
        let acceptsView = ComposableSettings.CheckboxView(with: accepts)
        _ = acceptsView.toggle.accessibilityID("settings.browser.site-data.accept-cookies")
        group.addSettingSubview(acceptsView)

        let privateBrowsing = ComposableSettings.ViewModel<Bool>(
            title: "Private browsing",
            setting: UserSettings.browserPrivateBrowsing,
            explanation: "New browser panes keep nothing once closed. Applies to panes opened after the change."
        )
        let privateView = ComposableSettings.CheckboxView(with: privateBrowsing)
        _ = privateView.toggle.accessibilityID("settings.browser.site-data.private-browsing")
        group.addSettingSubview(privateView)

        return group
    }

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Site Data",
            columns: [
                .init(id: "site", title: "Site", width: 220),
                .init(id: "kinds", title: "Data", width: 340)
            ],
            emptyMessage: "No site data stored.",
            visibleRows: 10,
            accessibilityPrefix: "settings.browser.site-data.sites"
        )
        table.addButton.isHidden = true
        table.onRemove = { [weak self] rowID in
            guard let self, let record = self.records.first(where: { $0.displayName == rowID }) else { return }
            Task {
                await self.siteData.remove([record])
                self.reload()
            }
        }
        table.addFooterButton(
            title: "Remove All…", identifier: "settings.browser.site-data.remove-all"
        ) { [weak self] in
            self?.removeAll()
        }
        table.addFooterButton(title: "Refresh", identifier: "settings.browser.site-data.refresh") { [weak self] in
            self?.reload()
        }
        return table
    }

    private func removeAll() {
        ComposableSettings.Alerts.confirmDestructive(
            "Remove all site data?",
            detail: "Cookies, caches and storage for every site are removed, and you are signed out everywhere. "
                + "History is not affected.",
            actionTitle: "Remove All",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            Task {
                await self.siteData.removeAll()
                self.reload()
            }
        }
    }

    private func reload() {
        Task {
            let records = await siteData.records()
            self.records = records
            table?.setRows(records.map { record in
                ComposableSettings.EditableTableRow(id: record.displayName, cells: [
                    "site": .text(record.displayName),
                    "kinds": .text(BrowserSiteData.labels(for: record))
                ])
            })
        }
    }
}

// MARK: - Privacy and security

@MainActor
private final class BrowserPrivacyPanel: ComposableSettings.SettingsPanelViewController {

    init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Privacy and Security",
            icon: NSImage(systemSymbolName: "lock.shield", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Protection",
                body: "Warn about fraudulent websites asks WebKit to check each page "
                    + "against Apple's list of known phishing and malware sites and show "
                    + "a warning page in place of a match. Upgrade to HTTPS loads a site "
                    + "WebKit knows supports HTTPS over HTTPS even when the address said "
                    + "http; it applies to browser panes opened after the change. "
                    + "Lockdown Mode is the same restricted mode Safari offers: certain "
                    + "web technologies, fonts and media formats are refused, which "
                    + "breaks some sites in exchange for a smaller attack surface. It "
                    + "applies to the next page each pane loads."
            ),
            .init(
                title: "What Is Not Here",
                body: "There is no Do Not Track switch, because WebKit sends no such "
                    + "header and the sites that honoured it have largely stopped. "
                    + "Passwords are not saved by the browser pane; the system keychain "
                    + "is not involved."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["privacy", "security", "fraud", "phishing", "https", "lockdown mode", "tracking"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Protection")

        let fraud = ComposableSettings.ViewModel<Bool>(
            title: "Warn about fraudulent websites",
            setting: UserSettings.browserFraudWarning
        )
        let fraudView = ComposableSettings.CheckboxView(with: fraud)
        _ = fraudView.toggle.accessibilityID("settings.browser.privacy.fraud-warning")
        group.addSettingSubview(fraudView)

        let https = ComposableSettings.ViewModel<Bool>(
            title: "Upgrade known sites to HTTPS",
            setting: UserSettings.browserUpgradesToHTTPS,
            explanation: "Applies to browser panes opened after the change."
        )
        let httpsView = ComposableSettings.CheckboxView(with: https)
        _ = httpsView.toggle.accessibilityID("settings.browser.privacy.upgrade-https")
        group.addSettingSubview(httpsView)

        let lockdown = ComposableSettings.ViewModel<Bool>(
            title: "Lockdown Mode",
            setting: UserSettings.browserLockdownMode,
            explanation: "Refuses some web technologies for a smaller attack surface. "
                + "Applies to the next page each pane loads."
        )
        let lockdownView = ComposableSettings.CheckboxView(with: lockdown)
        _ = lockdownView.toggle.accessibilityID("settings.browser.privacy.lockdown")
        group.addSettingSubview(lockdownView)

        settingsView.addGroup(group)
    }
}

// MARK: - Media and permissions

@MainActor
private final class BrowserMediaPanel: ComposableSettings.SettingsPanelViewController {

    init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Media and Permissions",
            icon: NSImage(systemSymbolName: "play.rectangle", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Playback",
                body: "Autoplay decides whether a page may start video or audio without a "
                    + "click: allowed, only without sound (the usual browser default — a "
                    + "muted video plays, one with sound waits), or never. AirPlay lets a "
                    + "page's video offer the AirPlay control. Both are fixed when a "
                    + "browser pane is created and apply to panes opened after the change."
            ),
            .init(
                title: "Camera and Microphone",
                body: "What happens when a page asks for the camera or microphone. Ask "
                    + "each time shows a sheet on the pane's window naming the site and "
                    + "the device, and the answer holds for that page. Always allow grants "
                    + "every request without asking; never allow refuses them all. macOS "
                    + "still asks once, the first time the app itself uses either device."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["autoplay", "video", "audio", "airplay", "camera", "microphone", "permissions", "webcam"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makePlaybackGroup())
        settingsView.addGroup(makeCaptureGroup())
    }

    private func makePlaybackGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Playback")

        let autoplay = ComposableSettings.ChoiceViewModel<BrowserAutoplayPolicy>(
            title: "Autoplay",
            setting: UserSettings.browserAutoplay,
            choices: BrowserAutoplayPolicy.allCases.map { .init(label: $0.label, value: $0) },
            explanation: "Applies to browser panes opened after the change."
        )
        let autoplayView = ComposableSettings.PopupMenuChoiceView(viewModel: autoplay)
        _ = autoplayView.popUpButton.accessibilityID("settings.browser.media.autoplay")
        group.addSettingSubview(autoplayView)

        let airPlay = ComposableSettings.ViewModel<Bool>(
            title: "Allow AirPlay",
            setting: UserSettings.browserAllowsAirPlay,
            explanation: "Applies to browser panes opened after the change."
        )
        let airPlayView = ComposableSettings.CheckboxView(with: airPlay)
        _ = airPlayView.toggle.accessibilityID("settings.browser.media.airplay")
        group.addSettingSubview(airPlayView)

        return group
    }

    private func makeCaptureGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Camera and Microphone")
        let capture = ComposableSettings.ChoiceViewModel<BrowserMediaCapturePolicy>(
            title: "When a page asks",
            setting: UserSettings.browserMediaCapture,
            choices: BrowserMediaCapturePolicy.allCases.map { .init(label: $0.label, value: $0) }
        )
        let captureView = ComposableSettings.PopupMenuChoiceView(viewModel: capture)
        _ = captureView.popUpButton.accessibilityID("settings.browser.media.capture")
        group.addSettingSubview(captureView)
        return group
    }
}

// MARK: - Downloads

@MainActor
private final class BrowserDownloadsPanel: ComposableSettings.SettingsPanelViewController {

    private let folderRow = ComposableSettings.ValueRowView(title: "Folder")
    private var cancellables: Set<AnyCancellable> = []

    init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Downloads",
            icon: NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Location",
                body: "Where a file a page offers — a zip, a disk image, anything the "
                    + "browser cannot show — is saved. Your Downloads folder unless you "
                    + "choose another; Use Downloads Folder puts it back. A file whose "
                    + "name is already taken is saved as name-2, name-3 and so on, the "
                    + "way Finder counts. Ask where to save each file shows a save sheet "
                    + "on the pane's window instead, starting in this folder."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["downloads", "download folder", "save", "where to save"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Location")

        _ = folderRow.valueLabel.accessibilityID("settings.browser.downloads.folder")
        group.addSettingSubview(folderRow)

        let choose = ComposableSettings.ButtonViewModel(title: "Choose Folder…") { [weak self] in
            self?.chooseFolder()
        }
        let chooseView = ComposableSettings.ButtonView(viewModel: choose, placement: .leading)
        _ = chooseView.button.accessibilityID("settings.browser.downloads.choose")
        group.addSettingSubview(chooseView)

        let useDefault = ComposableSettings.ButtonViewModel(title: "Use Downloads Folder") {
            UserSettings.browserDownloadDirectory.remove()
        }
        let useDefaultView = ComposableSettings.ButtonView(viewModel: useDefault, placement: .leading)
        _ = useDefaultView.button.accessibilityID("settings.browser.downloads.use-default")
        group.addSettingSubview(useDefaultView)

        let asks = ComposableSettings.ViewModel<Bool>(
            title: "Ask where to save each file",
            setting: UserSettings.browserAsksDownloadLocation
        )
        let asksView = ComposableSettings.CheckboxView(with: asks)
        _ = asksView.toggle.accessibilityID("settings.browser.downloads.ask")
        group.addSettingSubview(asksView)

        settingsView.addGroup(group)

        UserSettings.browserDownloadDirectory.$currentValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.showFolder() }
            .store(in: &cancellables)
        showFolder()
    }

    private func showFolder() {
        folderRow.value = (BrowserSettings.downloadDirectory(in: UserSettings.shared).path as NSString)
            .abbreviatingWithTildeInPath
    }

    private func chooseFolder() {
        ComposableSettings.Alerts.chooseFolder(
            on: view.window,
            prompt: "Choose",
            message: "Downloads from browser panes are saved here."
        ) { url in
            guard let url else { return }
            UserSettings.browserDownloadDirectory.value = url.path
        }
    }
}

// MARK: - Developer

@MainActor
private final class BrowserDeveloperPanel: ComposableSettings.SettingsPanelViewController {

    init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Developer",
            icon: NSImage(systemSymbolName: "hammer", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Web Inspector",
                body: "Safari's Web Inspector, attached to a browser pane's page. With it "
                    + "on, right-click a page and choose Inspect Element, or open Safari's "
                    + "Develop menu and find this app under your Mac's name. Off is the "
                    + "default because an inspectable page is one any process with "
                    + "Safari's privileges can read."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["developer", "web inspector", "inspect element", "devtools", "debug"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Web Inspector")
        let inspector = ComposableSettings.ViewModel<Bool>(
            title: "Allow Web Inspector",
            setting: UserSettings.browserWebInspectorEnabled,
            explanation: "Right-click a page and choose Inspect Element."
        )
        let inspectorView = ComposableSettings.CheckboxView(with: inspector)
        _ = inspectorView.toggle.accessibilityID("settings.browser.developer.inspector")
        group.addSettingSubview(inspectorView)
        settingsView.addGroup(group)
    }
}

// MARK: - Reset

@MainActor
private final class BrowserResetPanel: ComposableSettings.SettingsPanelViewController {

    init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Reset",
            icon: NSImage(systemSymbolName: "arrow.counterclockwise", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Reset",
                body: "Puts every setting in the Browser topics back to its default — the "
                    + "value each control shows on a fresh install. Settings only: "
                    + "history and site data are kept, and are cleared from their own "
                    + "topics. Open browser panes pick up the defaults the same way they "
                    + "pick up any other change."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["reset", "defaults", "restore"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Reset")
        group.addSettingSubview(ComposableSettings.ExplanationView(
            withText: "Returns every Browser setting to its default. History and site data are kept."
        ))
        let reset = ComposableSettings.ButtonViewModel(title: "Reset Browser Settings…") { [weak self] in
            self?.confirmReset()
        }
        let resetView = ComposableSettings.ButtonView(viewModel: reset, placement: .leading)
        _ = resetView.button.accessibilityID("settings.browser.reset.reset")
        group.addSettingSubview(resetView)
        settingsView.addGroup(group)
    }

    private func confirmReset() {
        ComposableSettings.Alerts.confirmDestructive(
            "Reset all Browser settings?",
            detail: "Every Browser setting returns to its default. History and site data are not affected.",
            actionTitle: "Reset",
            on: view.window
        ) { confirmed in
            guard confirmed else { return }
            BrowserSettings.reset(in: UserSettings.shared)
        }
    }
}
