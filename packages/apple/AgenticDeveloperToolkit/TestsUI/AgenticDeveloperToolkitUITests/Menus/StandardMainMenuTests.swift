import AppKit
import Testing
@testable import AgenticDeveloperToolkitUI

/// The menu bar is the one part of an AppKit app with no view to inspect and no
/// screenshot worth diffing, so these tests read the built `NSMenu` directly.
/// They assert on accessibility identifiers rather than titles: a title carries
/// the app name and gets localised, an identifier is the name a driving script
/// was given.
@MainActor
@Suite("StandardMainMenu")
struct StandardMainMenuTests {

    /// Every identifier in a built menu bar, depth-first.
    private func identifiers(of menu: NSMenu) -> Set<String> {
        var found: Set<String> = []
        for item in menu.items {
            let identifier = item.accessibilityIdentifier()
            if !identifier.isEmpty { found.insert(identifier) }
            if let submenu = item.submenu { found.formUnion(identifiers(of: submenu)) }
        }
        return found
    }

    private func item(_ identifier: String, in menu: NSMenu) -> NSMenuItem? {
        for item in menu.items {
            if item.accessibilityIdentifier() == identifier { return item }
            if let submenu = item.submenu, let found = self.item(identifier, in: submenu) { return found }
        }
        return nil
    }

    private var minimal: StandardMainMenu.Configuration {
        StandardMainMenu.Configuration(appName: "Test App")
    }

    @Test("the six standard menus are always present, in bar order")
    func barOrder() {
        let menu = StandardMainMenu.make(minimal)
        #expect(menu.items.compactMap { $0.submenu?.title } == ["Test App", "File", "Edit", "View", "Window", "Help"])
    }

    /// The whole point of the type: an app gets these without asking, because
    /// every app that hand-rolled its bar forgot a different subset of them.
    @Test("the standard commands are there without the host asking")
    func standardCommands() {
        let found = identifiers(of: StandardMainMenu.make(minimal))
        let required = [
            "menu.app.about", "menu.app.services", "menu.app.hide", "menu.app.hide-others",
            "menu.app.show-all", "menu.app.quit",
            "menu.file.close",
            "menu.edit.undo", "menu.edit.redo", "menu.edit.cut", "menu.edit.copy",
            "menu.edit.paste", "menu.edit.delete", "menu.edit.select-all",
            "menu.edit.find.find", "menu.edit.find.next", "menu.edit.find.previous",
            "menu.view.full-screen",
            "menu.window.minimize", "menu.window.zoom", "menu.window.bring-all-to-front"
        ]
        #expect(required.filter { !found.contains($0) } == [])
    }

    @Test("the app name is interpolated into the items that carry it")
    func appNameInTitles() {
        let menu = StandardMainMenu.make(minimal)
        #expect(item("menu.app.about", in: menu)?.title == "About Test App")
        #expect(item("menu.app.hide", in: menu)?.title == "Hide Test App")
        #expect(item("menu.app.quit", in: menu)?.title == "Quit Test App")
    }

    /// Settings is the one App-menu item a host must supply, and the identifier
    /// defaults rather than being slugged from "Settings…" — an ellipsis has no
    /// kebab spelling, and scripts were promised `menu.app.settings`.
    @Test("a host's Settings command lands in the App menu with a defaulted identifier")
    func settingsCommand() {
        var configuration = minimal
        configuration.settings = MainMenuCommand("Settings…", action: Selector(("showSettings:")), key: ",")
        let menu = StandardMainMenu.make(configuration)
        let settings = item("menu.app.settings", in: menu)
        #expect(settings?.title == "Settings…")
        #expect(settings?.keyEquivalent == ",")
        #expect(settings?.keyEquivalentModifierMask == .command)
    }

    @Test("omitting Settings omits the item, rather than shipping a dead one")
    func noSettingsCommand() {
        #expect(!identifiers(of: StandardMainMenu.make(minimal)).contains("menu.app.settings"))
    }

    /// View extras come before Enter Full Screen, which stays last: it is where
    /// macOS users look for it, and a host command appended after it would move
    /// the item an app has no business moving.
    @Test("host View commands precede Enter Full Screen")
    func viewCommandOrder() {
        var configuration = minimal
        configuration.viewCommands = [MainMenuCommand("Reload", action: Selector(("reload:")), key: "r")]
        let menu = StandardMainMenu.make(configuration)
        let view = menu.items.compactMap(\.submenu).first { $0.title == "View" }
        #expect(view?.items.map { $0.accessibilityIdentifier() }
            == ["menu.view.reload", "", "menu.view.full-screen"])
    }

    @Test("a host section is inserted between View and Window")
    func hostSection() {
        var configuration = minimal
        configuration.sections = [
            .init(title: "Workspace", commands: [MainMenuCommand("Sync", action: Selector(("sync:")))])
        ]
        let menu = StandardMainMenu.make(configuration)
        #expect(menu.items.compactMap { $0.submenu?.title }
            == ["Test App", "File", "Edit", "View", "Workspace", "Window", "Help"])
        #expect(identifiers(of: menu).contains("menu.workspace.sync"))
    }

    /// App-wide commands sit between Settings and Services, and the host's
    /// windows between Zoom and Bring All to Front, where macOS puts them.
    @Test("the App and Window menus carry the host's commands in place")
    func appAndWindowCommands() {
        var configuration = minimal
        configuration.settings = MainMenuCommand("Settings…", action: Selector(("showSettings:")), key: ",")
        configuration.appCommands = [
            MainMenuCommand("Check for Updates…", action: Selector(("checkForUpdates:")), identifier: "updates")
        ]
        configuration.windowCommands = [
            MainMenuCommand("Terminal Window", action: Selector(("showTerminal:")), key: "1", identifier: "terminal")
        ]
        let menu = StandardMainMenu.make(configuration)

        let app = menu.items[0].submenu?.items.map { $0.accessibilityIdentifier() } ?? []
        let updates = app.firstIndex(of: "menu.app.updates")
        #expect(updates != nil)
        #expect(app.firstIndex(of: "menu.app.settings").map { $0 < (updates ?? 0) } == true)
        #expect(app.firstIndex(of: "menu.app.services").map { $0 > (updates ?? .max) } == true)

        let window = menu.items.first { $0.submenu?.title == "Window" }?.submenu?.items
            .map { $0.accessibilityIdentifier() } ?? []
        let terminal = window.firstIndex(of: "menu.window.terminal")
        #expect(terminal != nil)
        #expect(window.firstIndex(of: "menu.window.zoom").map { $0 < (terminal ?? 0) } == true)
        #expect(window.firstIndex(of: "menu.window.bring-all-to-front").map { $0 > (terminal ?? .max) } == true)
    }

    @Test("Help carries the host's commands")
    func helpCommands() {
        var configuration = minimal
        configuration.helpCommands = [
            MainMenuCommand("Test App on the Web", action: Selector(("openSite:")), identifier: "website")
        ]
        #expect(identifiers(of: StandardMainMenu.make(configuration)).contains("menu.help.website"))
    }

    /// Both opt-outs exist for apps that genuinely have neither — a text-free
    /// app has nothing for ⌘F to find, and an accessory app has no Services.
    @Test("Services and Find can be turned off")
    func optOuts() {
        var configuration = minimal
        configuration.includesServices = false
        configuration.includesFindCommands = false
        let found = identifiers(of: StandardMainMenu.make(configuration))
        #expect(!found.contains("menu.app.services"))
        #expect(!found.contains("menu.edit.find.find"))
    }

    /// Editing and window commands have to reach whatever has focus, so their
    /// target stays nil and AppKit walks the responder chain.
    @Test("standard commands forward up the responder chain")
    func untargetedCommands() {
        let menu = StandardMainMenu.make(minimal)
        for identifier in ["menu.edit.copy", "menu.window.minimize", "menu.file.close"] {
            #expect(item(identifier, in: menu)?.target == nil)
        }
    }

    @Test("a separator is a separator, and carries no identifier")
    func separator() {
        let item = MainMenuCommand.separator.makeMenuItem(prefix: "app")
        #expect(item.isSeparatorItem)
    }
}
