import AppKit

/// Builds the menu bar every AppKit app is expected to have — App, File, Edit,
/// View, Window, Help — and splices the host's own commands into it.
///
/// An app without a nib gets no menu bar for free, so each of our apps had
/// hand-rolled one, and each hand-rolled a different subset: one shipped
/// without Services, another without Hide Others, a third without the Find
/// commands that make ⌘F work in any text view. The parts that differ between
/// apps are the ones the host passes in (its About and Settings commands, its
/// File/View extras, its own menus); everything else is the same in every app
/// and is built here once.
///
/// ```swift
/// StandardMainMenu.install(.init(
///     appName: "Agentic Developer Hub",
///     settings: MainMenuCommand("Settings…", action: #selector(…), target: self, key: ",")
/// ))
/// ```
///
/// Call it once per process, after `NSApplication.shared` exists. Menu items
/// hold their target weakly, so whatever object the host names in a command
/// has to outlive the menu — usually the app delegate.
@MainActor
public enum StandardMainMenu {

    /// A menu of the host's own, inserted between View and Window — where
    /// macOS apps put their document- or feature-specific menus.
    public struct Section {
        public var title: String
        public var commands: [MainMenuCommand]
        public var identifier: String?

        public init(title: String, commands: [MainMenuCommand], identifier: String? = nil) {
            self.title = title
            self.commands = commands
            self.identifier = identifier
        }
    }

    public struct Configuration {
        /// Interpolated into "About X", "Hide X" and "Quit X".
        public var appName: String

        /// The About command. `nil` uses AppKit's standard About panel, which
        /// is the right answer unless the app has an About window of its own.
        public var about: MainMenuCommand?

        /// The Settings command, conventionally ⌘,. `nil` omits the item —
        /// correct only for an app with nothing to configure.
        public var settings: MainMenuCommand?

        /// The App menu's own commands, after Settings and before Services —
        /// where macOS apps put app-wide items such as Check for Updates.
        public var appCommands: [MainMenuCommand]

        /// Appended to File, after Close Window.
        public var fileCommands: [MainMenuCommand]

        /// Appended to View, before Enter Full Screen.
        public var viewCommands: [MainMenuCommand]

        /// The host's own menus, in bar order, between View and Window.
        public var sections: [Section]

        /// The app's own windows, between Zoom and Bring All to Front. AppKit
        /// lists the open windows below all of them.
        public var windowCommands: [MainMenuCommand]

        /// Appended to Help. The menu is built either way: AppKit shows its own
        /// search field there.
        public var helpCommands: [MainMenuCommand]

        /// Whether the App menu carries the system Services submenu.
        public var includesServices: Bool

        /// Whether Edit carries the Find submenu (⌘F / ⌘G / ⇧⌘G, routed through
        /// `NSResponder.performTextFinderAction`). Off for an app with no text.
        public var includesFindCommands: Bool

        public init(
            appName: String,
            about: MainMenuCommand? = nil,
            settings: MainMenuCommand? = nil,
            appCommands: [MainMenuCommand] = [],
            fileCommands: [MainMenuCommand] = [],
            viewCommands: [MainMenuCommand] = [],
            sections: [Section] = [],
            windowCommands: [MainMenuCommand] = [],
            helpCommands: [MainMenuCommand] = [],
            includesServices: Bool = true,
            includesFindCommands: Bool = true
        ) {
            self.appName = appName
            self.about = about
            self.settings = settings
            self.appCommands = appCommands
            self.fileCommands = fileCommands
            self.viewCommands = viewCommands
            self.sections = sections
            self.windowCommands = windowCommands
            self.helpCommands = helpCommands
            self.includesServices = includesServices
            self.includesFindCommands = includesFindCommands
        }
    }

    /// Builds the menu bar and makes it the app's. Also hands AppKit the three
    /// menus it populates itself — Services, Window and Help — which is what
    /// makes the window list, the services list and Help's search field appear.
    @discardableResult
    public static func install(_ configuration: Configuration) -> NSMenu {
        let built = build(configuration)
        NSApp.mainMenu = built.menu
        NSApp.servicesMenu = built.services
        NSApp.windowsMenu = built.windows
        NSApp.helpMenu = built.help
        return built.menu
    }

    /// The menu bar, unattached. Exposed for tests and for a host that wants to
    /// inspect or further edit the result before installing it.
    public static func make(_ configuration: Configuration) -> NSMenu {
        build(configuration).menu
    }

    private struct Built {
        var menu: NSMenu
        var services: NSMenu?
        var windows: NSMenu
        var help: NSMenu
    }

    private static func build(_ configuration: Configuration) -> Built {
        let menu = NSMenu()
        let app = appMenu(configuration)
        menu.addItem(container(app.item))
        menu.addItem(container(fileMenu(configuration)))
        menu.addItem(container(editMenu(configuration)))
        menu.addItem(container(viewMenu(configuration)))

        for section in configuration.sections {
            let identifier = section.identifier ?? AccessibilityID.slug(section.title)
            menu.addItem(container(submenu(title: section.title,
                                           prefix: identifier,
                                           commands: section.commands)))
        }

        let windows = windowMenu(configuration)
        menu.addItem(container(windows))
        let help = helpMenu(configuration)
        menu.addItem(container(help))

        return Built(menu: menu, services: app.services, windows: windows, help: help)
    }

    /// AppKit wants each top-level menu hung off an otherwise empty item.
    private static func container(_ submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem()
        item.submenu = submenu
        return item
    }

    private static func submenu(title: String, prefix: String, commands: [MainMenuCommand]) -> NSMenu {
        let menu = NSMenu(title: title)
        for command in commands {
            menu.addItem(command.makeMenuItem(prefix: prefix))
        }
        return menu
    }

    // MARK: - App

    private static func appMenu(_ configuration: Configuration) -> (item: NSMenu, services: NSMenu?) {
        let name = configuration.appName
        var leading: [MainMenuCommand] = [
            configuration.about ?? MainMenuCommand(
                "About \(name)",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                identifier: "about"
            ),
            .separator
        ]

        if var settings = configuration.settings {
            settings.identifier = settings.identifier ?? "settings"
            leading.append(settings)
            leading.append(.separator)
        }

        if !configuration.appCommands.isEmpty {
            leading.append(contentsOf: configuration.appCommands)
            leading.append(.separator)
        }

        let trailing: [MainMenuCommand] = [
            MainMenuCommand("Hide \(name)",
                            action: #selector(NSApplication.hide(_:)),
                            key: "h",
                            identifier: "hide"),
            MainMenuCommand("Hide Others",
                            action: #selector(NSApplication.hideOtherApplications(_:)),
                            key: "h",
                            modifiers: [.command, .option],
                            identifier: "hide-others"),
            MainMenuCommand("Show All",
                            action: #selector(NSApplication.unhideAllApplications(_:)),
                            identifier: "show-all"),
            .separator,
            MainMenuCommand("Quit \(name)",
                            action: #selector(NSApplication.terminate(_:)),
                            key: "q",
                            identifier: "quit")
        ]

        let menu = submenu(title: name, prefix: "app", commands: leading)

        // Services is built directly rather than described as a command: AppKit
        // fills the submenu itself, and only once it has been handed the menu.
        var services: NSMenu?
        if configuration.includesServices {
            let servicesMenu = NSMenu(title: "Services")
            let item = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
            item.submenu = servicesMenu
            item.accessibilityID("menu.app.services")
            menu.addItem(item)
            menu.addItem(.separator())
            services = servicesMenu
        }

        for command in trailing {
            menu.addItem(command.makeMenuItem(prefix: "app"))
        }
        return (menu, services)
    }

    // MARK: - File

    private static func fileMenu(_ configuration: Configuration) -> NSMenu {
        var commands: [MainMenuCommand] = [
            MainMenuCommand("Close Window",
                            action: #selector(NSWindow.performClose(_:)),
                            key: "w",
                            identifier: "close")
        ]
        if !configuration.fileCommands.isEmpty {
            commands.append(.separator)
            commands.append(contentsOf: configuration.fileCommands)
        }
        return submenu(title: "File", prefix: "file", commands: commands)
    }

    // MARK: - Edit

    /// Every action here has a `nil` target so it forwards up the responder
    /// chain to whatever text view has focus. Undo and Redo are spelled as raw
    /// selectors because `NSUndoManager`'s are not exposed to Swift.
    private static func editMenu(_ configuration: Configuration) -> NSMenu {
        var commands: [MainMenuCommand] = [
            MainMenuCommand("Undo", action: Selector(("undo:")), key: "z", identifier: "undo"),
            MainMenuCommand("Redo", action: Selector(("redo:")), key: "z",
                            modifiers: [.command, .shift], identifier: "redo"),
            .separator,
            MainMenuCommand("Cut", action: #selector(NSText.cut(_:)), key: "x", identifier: "cut"),
            MainMenuCommand("Copy", action: #selector(NSText.copy(_:)), key: "c", identifier: "copy"),
            MainMenuCommand("Paste", action: #selector(NSText.paste(_:)), key: "v", identifier: "paste"),
            MainMenuCommand("Delete", action: #selector(NSText.delete(_:)), identifier: "delete"),
            MainMenuCommand("Select All", action: #selector(NSText.selectAll(_:)), key: "a",
                            identifier: "select-all")
        ]

        if configuration.includesFindCommands {
            let find = #selector(NSResponder.performTextFinderAction(_:))
            commands.append(.separator)
            commands.append(MainMenuCommand(submenu: "Find", [
                MainMenuCommand("Find…", action: find, key: "f", identifier: "find"),
                MainMenuCommand("Find Next", action: find, key: "g", identifier: "next"),
                MainMenuCommand("Find Previous", action: find, key: "g",
                                modifiers: [.command, .shift], identifier: "previous")
            ], identifier: "find"))
        }

        return submenu(title: "Edit", prefix: "edit", commands: commands)
    }

    // MARK: - View

    private static func viewMenu(_ configuration: Configuration) -> NSMenu {
        var commands = configuration.viewCommands
        if !commands.isEmpty { commands.append(.separator) }
        commands.append(MainMenuCommand("Enter Full Screen",
                                        action: #selector(NSWindow.toggleFullScreen(_:)),
                                        key: "f",
                                        modifiers: [.command, .control],
                                        identifier: "full-screen"))
        return submenu(title: "View", prefix: "view", commands: commands)
    }

    // MARK: - Window

    /// AppKit appends the app's windows below these, once the menu is installed
    /// as `NSApp.windowsMenu`.
    private static func windowMenu(_ configuration: Configuration) -> NSMenu {
        var commands: [MainMenuCommand] = [
            MainMenuCommand("Minimize", action: #selector(NSWindow.performMiniaturize(_:)),
                            key: "m", identifier: "minimize"),
            MainMenuCommand("Zoom", action: #selector(NSWindow.performZoom(_:)), identifier: "zoom"),
            .separator
        ]
        if !configuration.windowCommands.isEmpty {
            commands.append(contentsOf: configuration.windowCommands)
            commands.append(.separator)
        }
        commands.append(MainMenuCommand("Bring All to Front",
                                        action: #selector(NSApplication.arrangeInFront(_:)),
                                        identifier: "bring-all-to-front"))
        return submenu(title: "Window", prefix: "window", commands: commands)
    }

    // MARK: - Help

    private static func helpMenu(_ configuration: Configuration) -> NSMenu {
        submenu(title: "Help", prefix: "help", commands: configuration.helpCommands)
    }
}
