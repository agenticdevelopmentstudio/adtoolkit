import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class BrowserSettingsTests: XCTestCase {

    private func makeStore() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    // MARK: - Keys

    func testEveryBrowserKeyIsNamedUnderTheBrowserPrefix() {
        let names = BrowserSettings.allKeyNames
        XCTAssertEqual(names.count, 19)
        XCTAssertEqual(Set(names).count, names.count, "no two settings share a key")
        for name in names {
            XCTAssertTrue(name.hasPrefix("browser."), "\(name) is not a browser key")
        }
    }

    // MARK: - Reset

    func testResetRemovesEveryStoredBrowserValue() {
        let store = makeStore()
        store.set("example.com", for: UserSettings.browserHomePage)
        store.set(2.0, for: UserSettings.browserPageZoom)
        store.set(false, for: UserSettings.browserJavaScriptEnabled)
        store.set(BrowserHistoryRetention.oneWeek, for: UserSettings.browserHistoryRetention)
        store.set(BrowserMediaCapturePolicy.deny, for: UserSettings.browserMediaCapture)
        store.set("/tmp/downloads", for: UserSettings.browserDownloadDirectory)
        XCTAssertTrue(store.contains(UserSettings.browserPageZoom))

        BrowserSettings.reset(in: store)

        XCTAssertEqual(store.get(UserSettings.browserHomePage), "")
        XCTAssertEqual(store.get(UserSettings.browserPageZoom), 1.0)
        XCTAssertTrue(store.get(UserSettings.browserJavaScriptEnabled))
        XCTAssertEqual(store.get(UserSettings.browserHistoryRetention), .forever)
        XCTAssertEqual(store.get(UserSettings.browserMediaCapture), .ask)
        XCTAssertEqual(store.get(UserSettings.browserDownloadDirectory), "")
        XCTAssertFalse(store.contains(UserSettings.browserPageZoom),
                       "reset removes, so the default stays declared once")
        XCTAssertTrue(store.keys(withPrefix: "browser.").isEmpty)
    }

    func testResetLeavesOtherSettingsAlone() {
        let store = makeStore()
        let unrelated = UserSetting<String>("terminal.something", default: "")
        store.set("kept", for: unrelated)
        BrowserSettings.reset(in: store)
        XCTAssertEqual(store.get(unrelated), "kept")
    }

    // MARK: - Derived values

    func testTheHomePageResolvesLikeTheAddressBar() {
        let store = makeStore()
        XCTAssertNil(BrowserSettings.homePage(in: store), "blank is no home page")

        store.set("example.com", for: UserSettings.browserHomePage)
        XCTAssertEqual(BrowserSettings.homePage(in: store), URL(string: "https://example.com"))

        store.set("http://localhost:8080/", for: UserSettings.browserHomePage)
        XCTAssertEqual(BrowserSettings.homePage(in: store), URL(string: "http://localhost:8080/"))

        store.set("not a page", for: UserSettings.browserHomePage)
        XCTAssertNil(BrowserSettings.homePage(in: store), "an entry with inner whitespace is refused, as typed")
    }

    func testTheDownloadFolderFallsBackToDownloads() {
        let store = makeStore()
        XCTAssertEqual(BrowserSettings.downloadDirectory(in: store), BrowserSettings.defaultDownloadDirectory)

        store.set("~/Desktop/saved", for: UserSettings.browserDownloadDirectory)
        XCTAssertEqual(
            BrowserSettings.downloadDirectory(in: store).path,
            ("~/Desktop/saved" as NSString).expandingTildeInPath,
            "a tilde is expanded"
        )
    }

    func testRetentionCutoffs() {
        let now = Date(timeIntervalSince1970: 100 * 24 * 60 * 60)
        XCTAssertNil(BrowserHistoryRetention.forever.cutoff(from: now))
        XCTAssertEqual(BrowserHistoryRetention.oneWeek.cutoff(from: now), now.addingTimeInterval(-7 * 24 * 60 * 60))
        XCTAssertEqual(BrowserHistoryRetention.oneMonth.cutoff(from: now), now.addingTimeInterval(-30 * 24 * 60 * 60))
        XCTAssertEqual(BrowserHistoryRetention.threeMonths.cutoff(from: now),
                       now.addingTimeInterval(-90 * 24 * 60 * 60))
        XCTAssertEqual(BrowserHistoryRetention.oneYear.cutoff(from: now), now.addingTimeInterval(-365 * 24 * 60 * 60))
    }

    // MARK: - What the pane reads at creation

    func testPrivateBrowsingGivesTheConfigurationAThrowawayStore() {
        let store = makeStore()
        XCTAssertTrue(BrowserPaneViewController.makeConfiguration(settings: store).websiteDataStore.isPersistent)
        store.set(true, for: UserSettings.browserPrivateBrowsing)
        XCTAssertFalse(BrowserPaneViewController.makeConfiguration(settings: store).websiteDataStore.isPersistent)
    }

    func testAutoplayPolicyBecomesWebKitsPlaybackGate() {
        let store = makeStore()
        XCTAssertEqual(
            BrowserPaneViewController.makeConfiguration(settings: store).mediaTypesRequiringUserActionForPlayback,
            .audio, "the default lets muted video play"
        )
        store.set(BrowserAutoplayPolicy.never, for: UserSettings.browserAutoplay)
        XCTAssertEqual(
            BrowserPaneViewController.makeConfiguration(settings: store).mediaTypesRequiringUserActionForPlayback, .all
        )
        store.set(BrowserAutoplayPolicy.allowed, for: UserSettings.browserAutoplay)
        XCTAssertEqual(
            BrowserPaneViewController.makeConfiguration(settings: store).mediaTypesRequiringUserActionForPlayback, []
        )
    }

    func testUniqueDownloadDestinationsCountLikeFinder() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = BrowserPaneViewController.uniqueDestination(for: "file.zip", in: directory)
        XCTAssertEqual(first.lastPathComponent, "file.zip")
        FileManager.default.createFile(atPath: first.path, contents: Data())

        let second = BrowserPaneViewController.uniqueDestination(for: "file.zip", in: directory)
        XCTAssertEqual(second.lastPathComponent, "file-2.zip")
        FileManager.default.createFile(atPath: second.path, contents: Data())

        XCTAssertEqual(
            BrowserPaneViewController.uniqueDestination(for: "file.zip", in: directory).lastPathComponent, "file-3.zip"
        )
        XCTAssertEqual(
            BrowserPaneViewController.uniqueDestination(for: "", in: directory).lastPathComponent, "download",
            "a nameless download still gets a file"
        )
    }
}
