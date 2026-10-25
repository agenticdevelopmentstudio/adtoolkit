import AppKit
import OSLog
import AgenticToolkitCore

extension ComposableSettings {
    /// Owns the Whippet settings window and the gear-button bridge from the
    /// session-watcher panel. Whippet-local because the window is Whippet-local.
    @MainActor
    open class AppCoordinator: AppFeature {

        public let settingsWindow: ComposableSettings.SettingsWindow

        /// The sidebar's section titles, top to bottom. See `sortedForSidebar`.
        private let sectionOrder: [String]

        /// The ids this feature's actions answer to.
        public enum CommandID {
            public static let showSettings = "settings.action.showSettings"
        }

        /// - Parameter sectionOrder: The order of the sidebar's sections, by the
        ///   titles panels carry in `descriptor.section`. Empty (the default)
        ///   leaves one alphabetical list for apps whose panels have no sections.
        /// - Parameter commandRegistry: See `ProjectsCoordinator.init` —
        ///   required, so a dropped registry is a compile error rather than a
        ///   palette that silently lost this feature.
        public init(
            windowTitle: String = "Settings",
            settingsPanels: [any ComposableSettingsPanel],
            sectionOrder: [String] = [],
            commandRegistry registry: CommandRegistry
        ) {
            let settingsWindow = ComposableSettings.SettingsWindow()
            settingsWindow.windowTitle = windowTitle
            settingsWindow.settingPanels = Self.sortedForSidebar(settingsPanels, sectionOrder: sectionOrder)
            self.sectionOrder = sectionOrder

            settingsWindow.windowSpec = WindowSpec(
                defaultSize: NSSize(width: 720, height: 480),
                minSize: NSSize(width: 550, height: 420),
                defaultPosition: .center,
                persistsFrame: true
            )

            self.settingsWindow = settingsWindow
            super.init()

            registry.register(AppCommand(
                id: CommandID.showSettings,
                title: "Settings…",
                category: "Settings",
                run: { [weak self] in self?.showWindow() }
            ))

            self.menuContributions = [
                MenuContribution(
                    slot: .app,
                    title: "Settings…",
                    commandID: CommandID.showSettings,
                    registry: registry,
                    order: 10,
                    key: ","
                )
            ]

            self.scriptingKeys = [
                "scriptingSettingsVisible"
            ]
        }

        public func showWindow() {
            NSApp.activateUnlessQuiet()
            settingsWindow.showWindow()
        }

        /// Append a panel to the settings sidebar after construction. Used for
        /// panels whose dependencies (plugin managers, coordinators) aren't
        /// available when `SettingsCoordinator` is built.
        public func addPanel(_ panel: any ComposableSettingsPanel) {
            settingsWindow.settingPanels = Self.sortedForSidebar(
                settingsWindow.settingPanels + [panel], sectionOrder: sectionOrder)
        }

        /// The sidebar is grouped by section and alphabetical within each one, so a
        /// panel added late lands where its section and name say rather than at the
        /// bottom. Unsectioned panels come first, then the sections in
        /// `sectionOrder`, then any section that list does not name, alphabetically
        /// — a panel is never dropped for carrying a title nobody listed. The list
        /// builds one sidebar section per run of equal titles, so this sort is what
        /// keeps each section in one piece.
        ///
        /// Sorting lives here and not in `SplitViewController` because that class
        /// also backs *nested* topic lists (a theme's Details/Colors/Typography),
        /// where authored order is meaning.
        static func sortedForSidebar(
            _ panels: [any ComposableSettingsPanel],
            sectionOrder: [String]
        ) -> [any ComposableSettingsPanel] {
            func rank(_ section: String?) -> (Int, String) {
                guard let section else { return (0, "") }
                if let index = sectionOrder.firstIndex(of: section) { return (1 + index, "") }
                return (1 + sectionOrder.count, section)
            }
            return panels.sorted {
                let lhs = rank($0.descriptor.section), rhs = rank($1.descriptor.section)
                if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
                if lhs.1 != rhs.1 { return lhs.1.localizedStandardCompare(rhs.1) == .orderedAscending }
                return $0.descriptor.title.localizedStandardCompare($1.descriptor.title) == .orderedAscending
            }
        }

        public override func value(forScriptingKey key: String) -> Any? {
            switch key {
            case "scriptingSettingsVisible": return settingsWindow.isVisible
            default: return nil
            }
        }

        public override func setValue(_ value: Any?, forScriptingKey key: String) {
            switch key {
            case "scriptingSettingsVisible":
                if (value as? Bool) == true {
                    settingsWindow.showWindow()
                } else {
                    settingsWindow.dismiss()
                }
            default:
                break
            }
        }
    }

}
