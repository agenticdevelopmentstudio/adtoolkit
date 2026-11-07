import XCTest
@preconcurrency import KeyboardShortcuts
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NoticeHotkeysTests: XCTestCase {

    private static let ids = ["notice.act", "notice.archive", "notice.snooze", "notice.history"]
    private static let chordModifiers: NSEvent.ModifierFlags = [.control, .option, .command]

    private var suiteNames: [String] = []
    private var defaults = UserDefaults.standard
    private var store: SettingsStore!

    override func setUp() async throws {
        try await super.setUp()
        resetSharedBindings()
        freshDomain()
    }

    override func tearDown() async throws {
        resetSharedBindings()
        for name in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        try await super.tearDown()
    }

    /// The registry keeps what the user authored in the shared `UserSettings`,
    /// so each test starts and ends with none of these ids authored.
    private func resetSharedBindings() {
        let registry = KeyCommandRegistry()
        Self.ids.forEach(registry.resetBinding(for:))
    }

    private func freshDomain() {
        let name = "NoticeHotkeysTests.\(UUID().uuidString)"
        suiteNames.append(name)
        defaults = UserDefaults(suiteName: name) ?? .standard
        store = SettingsStore(
            with: UserDefaultsSettingsStorageProvider(defaults: defaults),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    private final class Rules {
        var value = NoticeRoutingRules.defaults
    }

    private struct Env {
        let center: NoticePresentationCenter
        let handler: RecordingHandler
        let clock: Clock
        let registry: KeyCommandRegistry
        let rules: Rules
    }

    private func makeEnv() -> Env {
        let handler = RecordingHandler()
        let clock = Clock()
        let rules = Rules()
        let center = NoticePresentationCenter(
            handler: handler, rules: { rules.value }, filter: { NoticeFilter() },
            idle: IdleMonitor(idleSeconds: { 0 }), clock: { clock.now })
        center.presenters = [.toast: RecordingPresenter(), .alert: RecordingPresenter()]
        let registry = KeyCommandRegistry()
        NoticeHotkeys.install(center: center, registry: registry)
        return Env(center: center, handler: handler, clock: clock, registry: registry, rules: rules)
    }

    private func post(_ env: Env, _ ids: [String]) {
        for id in ids {
            env.center.receive(Notice(id: id, timestamp: env.clock.now, source: "ci", title: id, urgency: .soon))
        }
    }

    private func press(_ env: Env, _ id: String) -> Bool {
        env.registry.descriptor(for: id)?.perform() ?? false
    }

    // MARK: The section

    func testSectionHasFourGlobalCommandsWithSpecDefaults() throws {
        let env = makeEnv()
        let section = try XCTUnwrap(env.registry.sections.first { $0.title == NoticeHotkeys.sectionTitle })
        XCTAssertEqual(NoticeHotkeys.sectionTitle, "Notifications")
        XCTAssertEqual(section.scope, .global)
        XCTAssertEqual(section.caption, "Act on the newest notification from any app.")
        XCTAssertEqual(section.allCommands.map(\.id), Self.ids)
        XCTAssertEqual(section.allCommands.map(\.title), [
            "Act on newest notification", "Archive newest notification",
            "Snooze newest notification", "Show notification history"
        ])
        XCTAssertEqual(section.allCommands.map(\.defaultShortcut), [
            KeyboardShortcuts.Shortcut(.return, modifiers: Self.chordModifiers),
            KeyboardShortcuts.Shortcut(.delete, modifiers: Self.chordModifiers),
            KeyboardShortcuts.Shortcut(.s, modifiers: Self.chordModifiers),
            KeyboardShortcuts.Shortcut(.h, modifiers: Self.chordModifiers)
        ])
    }

    func testCommandsOffByDefault() {
        let env = makeEnv()
        for id in Self.ids {
            XCTAssertFalse(env.registry.binding(for: id).isEnabled, id)
            XCTAssertNil(env.registry.shortcut(for: id), id)
        }
    }

    // MARK: Behavior

    func testActArchiveHistoryReachCenter() {
        let env = makeEnv()
        post(env, ["a", "b"])

        XCTAssertTrue(press(env, "notice.archive")) // b
        XCTAssertTrue(press(env, "notice.act")) // a: no action, so it is marked read
        XCTAssertTrue(press(env, "notice.history"))
        XCTAssertEqual(env.handler.calls, [.setState("b", .archived), .setState("a", .read), .showHistory])
    }

    func testNothingShownDeclinesEverythingButHistory() {
        let env = makeEnv()
        XCTAssertFalse(press(env, "notice.act"))
        XCTAssertFalse(press(env, "notice.archive"))
        XCTAssertFalse(press(env, "notice.snooze"))
        XCTAssertTrue(env.handler.calls.isEmpty)
        XCTAssertTrue(press(env, "notice.history"))
        XCTAssertEqual(env.handler.calls, [.showHistory])
    }

    func testSnoozePrefersFifteenMinutesElseFirstOfferedElseDeclines() {
        let env = makeEnv()
        post(env, ["a"])
        XCTAssertTrue(press(env, "notice.snooze"))
        XCTAssertEqual(env.handler.calls, [.snooze("a", env.clock.now.addingTimeInterval(15 * 60))])

        env.handler.calls = []
        env.rules.value.styles[.soon]?.snooze = SnoozeSettings(isEnabled: true, options: [.oneHour, .untilBack])
        post(env, ["b"])
        XCTAssertTrue(press(env, "notice.snooze"))
        XCTAssertEqual(env.handler.calls, [.snooze("b", env.clock.now.addingTimeInterval(60 * 60))],
                       "15 minutes is not offered, so the first offered option is used")

        env.handler.calls = []
        env.rules.value.styles[.soon]?.snooze = SnoozeSettings(isEnabled: false, options: SnoozeOption.allCases)
        post(env, ["c"])
        XCTAssertFalse(press(env, "notice.snooze"), "not snoozable")
        XCTAssertTrue(env.handler.calls.isEmpty)
    }

    // MARK: Migration

    private var authored: [String: KeyCommandBinding] { store.get(UserSettings.keyCommandBindings) }

    private func migrate(_ enabled: Bool?) {
        NoticeHotkeys.migrateLegacyHotkeys(enabled: enabled, store: store, defaults: defaults)
    }

    func testLegacyEnabledMigratesBindingsOnceAndKeepsUserEdits() {
        let edited = KeyCommandBinding(
            shortcut: KeyboardShortcuts.Shortcut(.k, modifiers: .command), isEnabled: true)
        store.set(["notice.snooze": edited], for: UserSettings.keyCommandBindings)

        migrate(true)
        XCTAssertEqual(Set(authored.keys), Set(Self.ids))
        XCTAssertEqual(authored["notice.snooze"], edited, "an id already authored is skipped")
        XCTAssertEqual(authored["notice.act"], KeyCommandBinding(
            shortcut: KeyboardShortcuts.Shortcut(.return, modifiers: Self.chordModifiers), isEnabled: true))
        XCTAssertEqual(authored["notice.history"]?.isEnabled, true)
        XCTAssertTrue(defaults.bool(forKey: "notice_hotkeys_migrated_v1"))

        // The user switches one off; a second run must not turn it back on.
        var off = authored["notice.act"] ?? edited
        off.isEnabled = false
        store.set(authored.merging(["notice.act": off]) { $1 }, for: UserSettings.keyCommandBindings)
        migrate(true)
        XCTAssertEqual(authored["notice.act"]?.isEnabled, false)
    }

    func testLegacyNilOrFalseWritesNothing() {
        migrate(nil)
        XCTAssertTrue(authored.isEmpty)
        XCTAssertTrue(defaults.bool(forKey: "notice_hotkeys_migrated_v1"), "the marker is set either way")

        freshDomain()
        migrate(false)
        XCTAssertTrue(authored.isEmpty)

        migrate(true)
        XCTAssertTrue(authored.isEmpty, "a decision already made is not revisited")
    }
}
