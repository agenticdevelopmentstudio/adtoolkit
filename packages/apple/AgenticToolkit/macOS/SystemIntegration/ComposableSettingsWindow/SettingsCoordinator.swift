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

        /// The sidebar row each section is shown as, by section title.
        private let sectionIcons: [String: NSImage]

        /// Every panel handed over, before sections are folded into tabs.
        private var panels: [any ComposableSettingsPanel]

        /// One topic per section, kept across `addPanel` so the tab a reader
        /// is on survives a panel arriving late.
        private var sectionTopics: [String: SectionTabsPanel] = [:]

        /// The ids this feature's actions answer to.
        public enum CommandID {
            public static let showSettings = "settings.action.showSettings"
        }

        /// - Parameter sectionOrder: The order of the sidebar's sections, by the
        ///   titles panels carry in `descriptor.section`. Empty (the default)
        ///   leaves one alphabetical list for apps whose panels have no sections.
        /// - Parameter sectionIcons: The icon of each section's sidebar row, by
        ///   section title. A section left out takes its first panel's icon.
        /// - Parameter commandRegistry: See `ProjectsCoordinator.init` —
        ///   required, so a dropped registry is a compile error rather than a
        ///   palette that silently lost this feature.
        public init(
            windowTitle: String = "Settings",
            settingsPanels: [any ComposableSettingsPanel],
            sectionOrder: [String] = [],
            sectionIcons: [String: NSImage] = [:],
            commandRegistry registry: CommandRegistry
        ) {
            let settingsWindow = ComposableSettings.SettingsWindow()
            settingsWindow.windowTitle = windowTitle
            // The topics arrive already in the order `sortedForSidebar` gives
            // them, sections included; an alphabetical pass on top would mix the
            // sections in among the unsectioned panels.
            settingsWindow.viewController?.sortsPanelsByTitle = false
            self.sectionOrder = sectionOrder
            self.sectionIcons = sectionIcons
            self.panels = settingsPanels

            settingsWindow.windowSpec = WindowSpec(
                defaultSize: NSSize(width: 720, height: 480),
                minSize: NSSize(width: 550, height: 420),
                defaultPosition: .center,
                persistsFrame: true
            )

            self.settingsWindow = settingsWindow
            super.init()
            publishTopics()

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
            panels.append(panel)
            publishTopics()
        }

        /// Hands the window its sidebar: each unsectioned panel as a topic of
        /// its own, and each section as one topic whose tabs are its panels.
        private func publishTopics() {
            var topics: [any ComposableSettingsPanel] = []
            var members: [String: [any ComposableSettingsPanel]] = [:]
            for panel in Self.sortedForSidebar(panels, sectionOrder: sectionOrder) {
                guard let section = panel.descriptor.section else {
                    topics.append(panel)
                    continue
                }
                if members[section] == nil {
                    let topic = sectionTopics[section]
                        ?? SectionTabsPanel(section: section, icon: sectionIcons[section] ?? panel.descriptor.icon)
                    sectionTopics[section] = topic
                    topics.append(topic)
                }
                members[section, default: []].append(panel)
            }
            sectionTopics = sectionTopics.filter { members[$0.key] != nil }
            for (section, topic) in sectionTopics {
                topic.setPanels(members[section] ?? [])
            }
            settingsWindow.settingPanels = topics
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
