import AppKit

extension ComposableSettings {

    /// A panel that holds other panels and shows one of them at a time — what
    /// the window's search, toolbar title, help and back/forward look *through*
    /// to find the panel the reader is actually looking at.
    @MainActor
    public protocol SettingsPanelContainer: ComposableSettingsPanel {
        var containedPanels: [any ComposableSettingsPanel] { get }
        var selectedContainedPanel: (any ComposableSettingsPanel)? { get }
        func selectContainedPanel(_ panel: any ComposableSettingsPanel)
    }

    /// One sidebar topic for a whole section: a row of horizontal tabs, one per
    /// panel in the section, over the selected panel.
    ///
    /// The settings window used to list a section's panels as rows under a
    /// heading. Now the section is the row, and its panels are the tabs:
    ///
    ///     Workspace  | [Browser] [Git] [Projects] [Terminal]
    ///
    /// The tabs keep the order they are handed over in; `AppCoordinator` hands
    /// them over alphabetised. The selected tab survives `setPanels` when its
    /// panel is still among the new ones, so a panel added late never moves
    /// the reader off the tab they were on.
    @MainActor
    public final class SectionTabsPanel: NSViewController, SettingsPanelContainer {

        public let descriptor: SettingsPanelDescriptor

        public private(set) var containedPanels: [any ComposableSettingsPanel] = []

        public var selectedContainedPanel: (any ComposableSettingsPanel)? { shown }

        /// It hosts each tab in its own scroll view, the way the split hosts a
        /// panel; a second scroll view around the tab bar would scroll the tabs
        /// away with the content.
        public var hostsOwnScroll: Bool { true }

        /// The selected tab's help: the tab is the panel the reader is reading.
        public var effectiveHelpContent: PanelHelp? { shown?.effectiveHelpContent }

        private let tabs = NSSegmentedControl(
            labels: [], trackingMode: .selectOne, target: nil, action: nil)
        private let content = NSView()
        private var shown: (any ComposableSettingsPanel)?

        public init(section: String, icon: NSImage?) {
            descriptor = SettingsPanelDescriptor(title: section, icon: icon)
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError() }

        public override func loadView() {
            let root = NSView()
            tabs.translatesAutoresizingMaskIntoConstraints = false
            tabs.target = self
            tabs.action = #selector(tabChanged(_:))
            tabs.setAccessibilityIdentifier("settings.section-tabs.\(descriptor.title)")
            content.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(tabs)
            root.addSubview(content)
            NSLayoutConstraint.activate([
                tabs.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
                tabs.centerXAnchor.constraint(equalTo: root.centerXAnchor),
                tabs.leadingAnchor.constraint(greaterThanOrEqualTo: root.leadingAnchor, constant: 12),
                content.topAnchor.constraint(equalTo: tabs.bottomAnchor, constant: 8),
                content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                content.bottomAnchor.constraint(equalTo: root.bottomAnchor)
            ])
            view = root
        }

        public override func viewDidLoad() {
            super.viewDidLoad()
            rebuildTabs()
            show(shown ?? containedPanels.first)
        }

        /// Replaces the tabs, keeping the selected one when it is still here.
        public func setPanels(_ panels: [any ComposableSettingsPanel]) {
            containedPanels = panels
            guard isViewLoaded else { return }
            rebuildTabs()
            if let shown, panels.contains(where: { $0 === shown }) {
                selectTab(for: shown)
            } else {
                show(panels.first)
            }
        }

        public func selectContainedPanel(_ panel: any ComposableSettingsPanel) {
            guard containedPanels.contains(where: { $0 === panel }) else { return }
            if !isViewLoaded {
                shown = panel
                return
            }
            show(panel)
        }

        private func rebuildTabs() {
            tabs.segmentCount = containedPanels.count
            for (index, panel) in containedPanels.enumerated() {
                tabs.setLabel(panel.descriptor.title, forSegment: index)
                tabs.setWidth(0, forSegment: index)
                tabs.setEnabled(!panel.descriptor.isDisabled, forSegment: index)
            }
            if let shown { selectTab(for: shown) }
        }

        private func selectTab(for panel: any ComposableSettingsPanel) {
            tabs.selectedSegment = containedPanels.firstIndex { $0 === panel } ?? -1
        }

        @objc private func tabChanged(_ sender: NSSegmentedControl) {
            guard containedPanels.indices.contains(sender.selectedSegment) else { return }
            show(containedPanels[sender.selectedSegment])
        }

        private func show(_ panel: (any ComposableSettingsPanel)?) {
            if let shown, shown !== panel {
                shown.removeFromParent()
            }
            content.subviews.forEach { $0.removeFromSuperview() }
            shown = panel
            guard let panel else {
                tabs.selectedSegment = -1
                enclosingSettingsSplit?.containedSelectionDidChange()
                return
            }
            if panel.parent !== self { addChild(panel) }
            selectTab(for: panel)
            // Hosted exactly as the split hosts a panel of its own: a nested
            // split or a self-scrolling panel directly, anything else in a
            // `PanelScrollView`, so its content never sizes the window.
            let hosted: NSView
            if panel is SplitViewController || panel.hostsOwnScroll {
                hosted = panel.view
            } else {
                let scroll = PanelScrollView()
                scroll.setContent(panel.view)
                hosted = scroll
            }
            hosted.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(hosted)
            NSLayoutConstraint.activate([
                hosted.topAnchor.constraint(equalTo: content.topAnchor),
                hosted.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                hosted.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                hosted.bottomAnchor.constraint(equalTo: content.bottomAnchor)
            ])
            enclosingSettingsSplit?.containedSelectionDidChange()
        }
    }
}
