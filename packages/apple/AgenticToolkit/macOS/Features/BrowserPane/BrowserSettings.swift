//
//  BrowserSettings.swift
//  AgenticToolkit
//

import Foundation
import AgenticToolkitCore

// MARK: - Choice types

/// How long the browser keeps a visit before forgetting it.
public enum BrowserHistoryRetention: String, Codable, Sendable, CaseIterable {
    case oneWeek
    case oneMonth
    case threeMonths
    case oneYear
    case forever

    public var label: String {
        switch self {
        case .oneWeek: "One week"
        case .oneMonth: "One month"
        case .threeMonths: "Three months"
        case .oneYear: "One year"
        case .forever: "Forever"
        }
    }

    /// Visits before this instant are forgotten; `nil` keeps everything.
    public func cutoff(from now: Date = Date()) -> Date? {
        let day: TimeInterval = 24 * 60 * 60
        switch self {
        case .oneWeek: return now.addingTimeInterval(-7 * day)
        case .oneMonth: return now.addingTimeInterval(-30 * day)
        case .threeMonths: return now.addingTimeInterval(-90 * day)
        case .oneYear: return now.addingTimeInterval(-365 * day)
        case .forever: return nil
        }
    }
}

/// What a page may do with the camera and microphone.
public enum BrowserMediaCapturePolicy: String, Codable, Sendable, CaseIterable {
    case ask
    case allow
    case deny

    public var label: String {
        switch self {
        case .ask: "Ask each time"
        case .allow: "Always allow"
        case .deny: "Never allow"
        }
    }
}

/// Whether a page may start playing media on its own.
public enum BrowserAutoplayPolicy: String, Codable, Sendable, CaseIterable {
    case allowed
    case mutedOnly
    case never

    public var label: String {
        switch self {
        case .allowed: "Allowed"
        case .mutedOnly: "Only without sound"
        case .never: "Never"
        }
    }
}

// MARK: - Keys

/// The browser pane's settings. Every key starts with `browser.`, which is
/// what `BrowserSettings.reset(in:)` leans on, and a key name is a storage
/// format once shipped: renaming one orphans the value under it.
extension UserSettings {

    // General
    public static let browserHomePage = UserSetting<String>("browser.home_page", default: "")
    public static let browserPageZoom = UserSetting<Double>("browser.page_zoom", default: 1.0)
    public static let browserMinimumFontSize = UserSetting<Int>("browser.minimum_font_size", default: 0)
    public static let browserJavaScriptEnabled = UserSetting<Bool>("browser.javascript_enabled", default: true)
    public static let browserBlocksPopups = UserSetting<Bool>("browser.blocks_popups", default: true)
    public static let browserCustomUserAgent = UserSetting<String>("browser.custom_user_agent", default: "")

    // History
    public static let browserRecordsHistory = UserSetting<Bool>("browser.records_history", default: true)
    public static let browserHistoryRetention = UserSetting<BrowserHistoryRetention>(
        "browser.history_retention", default: .forever
    )

    // Cookies and site data
    public static let browserAcceptsCookies = UserSetting<Bool>("browser.accepts_cookies", default: true)
    public static let browserPrivateBrowsing = UserSetting<Bool>("browser.private_browsing", default: false)

    // Privacy and security
    public static let browserFraudWarning = UserSetting<Bool>("browser.fraud_warning", default: true)
    public static let browserUpgradesToHTTPS = UserSetting<Bool>("browser.upgrades_to_https", default: true)
    public static let browserLockdownMode = UserSetting<Bool>("browser.lockdown_mode", default: false)

    // Media and permissions
    public static let browserAutoplay = UserSetting<BrowserAutoplayPolicy>("browser.autoplay", default: .mutedOnly)
    public static let browserAllowsAirPlay = UserSetting<Bool>("browser.allows_airplay", default: true)
    public static let browserMediaCapture = UserSetting<BrowserMediaCapturePolicy>(
        "browser.media_capture", default: .ask
    )

    // Downloads
    public static let browserDownloadDirectory = UserSetting<String>("browser.download_directory", default: "")
    public static let browserAsksDownloadLocation = UserSetting<Bool>("browser.asks_download_location", default: false)

    // Developer
    public static let browserWebInspectorEnabled = UserSetting<Bool>("browser.web_inspector_enabled", default: false)

    // Automation
    public static let browserAutomationEnabled = UserSetting<Bool>("browser.automation.enabled", default: true)
    public static let browserAutomationEvaluate = UserSetting<Bool>("browser.automation.evaluate", default: false)
}

// MARK: - Derived values and reset

/// Readers of the browser settings that need more than the raw value.
@MainActor
public enum BrowserSettings {

    /// Every browser key, so a reset forgets all of them and nothing else.
    /// Listed rather than discovered by prefix: `keys(withPrefix:)` sees only
    /// what has been written, and a reset must also answer "what *are* the
    /// browser settings" to the panel that shows them.
    ///
    /// The automation switches are not here on purpose. "Reset browser
    /// settings" means the browsing preferences; it must not turn model
    /// access back on for a user who turned it off, nor turn `browser_evaluate`
    /// off for one who turned it on. Those two are reset from their own panel.
    static let allKeys: [any BrowserSettingKey] = [
        UserSettings.browserHomePage, UserSettings.browserPageZoom, UserSettings.browserMinimumFontSize,
        UserSettings.browserJavaScriptEnabled, UserSettings.browserBlocksPopups,
        UserSettings.browserCustomUserAgent, UserSettings.browserRecordsHistory,
        UserSettings.browserHistoryRetention, UserSettings.browserAcceptsCookies,
        UserSettings.browserPrivateBrowsing, UserSettings.browserFraudWarning,
        UserSettings.browserUpgradesToHTTPS, UserSettings.browserLockdownMode,
        UserSettings.browserAutoplay, UserSettings.browserAllowsAirPlay, UserSettings.browserMediaCapture,
        UserSettings.browserDownloadDirectory, UserSettings.browserAsksDownloadLocation,
        UserSettings.browserWebInspectorEnabled
    ]

    /// The names of every browser key, for a test to hold the list to.
    public static var allKeyNames: [String] { allKeys.map(\.name) }

    /// Puts every browser setting back to its default by removing the stored
    /// value, so what the default *is* stays declared in one place.
    public static func reset(in store: SettingsStore) {
        for key in allKeys { key.remove(from: store) }
    }

    /// The home page the setting names, or `nil` when it is blank or not an
    /// address. Resolved the way the address bar resolves what is typed, so
    /// `example.com` works in both places.
    public static func homePage(in store: SettingsStore) -> URL? {
        let entry = store.get(UserSettings.browserHomePage)
        guard !entry.isEmpty else { return nil }
        return BrowserPaneViewController.resolveAddress(entry)
    }

    /// Where downloads land when the setting is blank.
    public static var defaultDownloadDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }

    /// The download folder: the setting when it names one, else `~/Downloads`.
    public static func downloadDirectory(in store: SettingsStore) -> URL {
        let path = store.get(UserSettings.browserDownloadDirectory)
        guard !path.isEmpty else { return defaultDownloadDirectory }
        return URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
    }

    /// The page-zoom range the panel offers and the pane clamps to.
    public static let pageZoomRange: ClosedRange<Double> = 0.5...3.0

    /// The minimum-font-size range, in points; 0 means WebKit's own.
    public static let minimumFontSizeRange: ClosedRange<Int> = 0...24
}

/// A key that can remove itself from a store without the caller knowing its
/// value type — what lets `reset(in:)` hold keys of mixed types in one list.
@MainActor
protocol BrowserSettingKey {
    var name: String { get }
    func remove(from store: SettingsStore)
}

extension UserSetting: BrowserSettingKey {
    func remove(from store: SettingsStore) { store.remove(self) }
}
