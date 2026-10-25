import AppKit
import Foundation
import SwiftUI

extension ComposableSettings {

    /// Base class for every settings panel. One instance is hosted in the
    /// right-hand detail pane of a `SplitViewController`; the sidebar metadata
    /// lives on the panel itself via the open overrides below. The panel *is* the
    /// list item — no wrapper struct.
    @MainActor
    open class SettingsPanelViewController: NSViewController, ComposableSettingsPanel {

        /// This is what is user for the settings panel list
        public let descriptor: SettingsPanelDescriptor

        public let settingsView = PanelView()

        /// Reference prose for the detail pane's help drawer; `nil` means this
        /// panel offers none, and the drawer shows its empty state rather than
        /// the help button disappearing. See `ComposableSettingsPanel.helpContent`.
        ///
        /// Redeclared here (rather than left to the protocol's extension default)
        /// so subclass overrides are actually reached: a protocol extension's
        /// default is bound at the point of conformance — this class — and a
        /// subclass property that merely shadows it is invisible through the
        /// `any ComposableSettingsPanel` the split holds. `hostsOwnScroll` below
        /// is redeclared for the same reason.
        open var helpContent: PanelHelp? { nil }

        /// A plain panel holds no selection, so what it shows is its own help —
        /// plus the explanations its settings carry, which `GroupView` hands
        /// here rather than drawing under the controls (see
        /// `ExplainedSettingsView`). Redeclared for the same dispatch reason as
        /// `helpContent`.
        open var effectiveHelpContent: PanelHelp? {
            Self.help(helpContent, adding: isViewLoaded ? Self.groups(in: view) : [])
        }

        /// Every group in `root`'s tree, top to bottom — found by walking rather
        /// than asked of `settingsView`, because a panel may lay its groups out
        /// in a stack of its own.
        static func groups(in root: NSView) -> [GroupView] {
            root.subviews.flatMap { subview -> [GroupView] in
                if let group = subview as? GroupView { return [group] }
                return groups(in: subview)
            }
        }

        /// `help` with each group's notes filed under the topic of the same
        /// title, or under a new topic after the authored ones. A note whose text
        /// the authored help already says is left out, so a panel that wrote its
        /// help by hand is not told everything twice.
        static func help(_ help: PanelHelp?, adding groups: [GroupView]) -> PanelHelp? {
            var topics = help?.topics ?? []
            for group in groups where !group.helpNotes.isEmpty {
                let title = group.title ?? "Settings"
                let index = topics.firstIndex { $0.title == title }
                let said = index.map { topics[$0].body } ?? ""
                let fresh = group.helpNotes.filter { !said.contains($0.text) }.map(\.paragraph)
                guard !fresh.isEmpty else { continue }
                let body = ([said].filter { !$0.isEmpty } + fresh).joined(separator: "\n\n")
                if let index {
                    topics[index] = .init(title: title, body: body)
                } else {
                    topics.append(.init(title: title, body: body))
                }
            }
            return topics.isEmpty ? nil : PanelHelp(topics: topics)
        }

        open var hostsOwnScroll: Bool { false }

        /// Nothing by default: a panel built from `GroupView`s is read off
        /// its own labels once it has been opened. Override on a panel whose
        /// content is SwiftUI, or one worth finding before its first visit.
        /// Redeclared for the same dispatch reason as `helpContent`.
        open var searchKeywords: [String] { [] }

        open override func loadView() {
            self.view = settingsView
        }

        public init(with descriptor: SettingsPanelDescriptor? = nil) {
            if let descriptor {
                self.descriptor = descriptor
            } else {
                self.descriptor = SettingsPanelDescriptor()
            }
            super.init(nibName: nil, bundle: nil)
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func addGroup(_ group: GroupView) {
            self.settingsView.addGroup(group)
        }

        /// Hosts SwiftUI `content` as this panel's view, in the one configuration
        /// that cannot resize the settings window.
        ///
        /// `NSHostingView` defaults to `.standardBounds`, which installs *required*
        /// min- and max-size constraints derived from the SwiftUI content's own
        /// sizing. The detail pane pins a panel to its edges, so those constraints
        /// are the window's: a panel whose content is a stack of cards has a finite
        /// ideal height, and selecting it collapsed the window to that height and
        /// held it there.
        ///
        /// Only `.intrinsicContentSize` survives. `PanelScrollView`'s document
        /// still reads it, so content taller than the pane scrolls instead of being
        /// clipped — but an intrinsic size is a hugging-priority preference, not a
        /// limit the window has to obey. Panel content never sizes this window;
        /// the window sizes the panel.
        public static func hostingView(for content: some View) -> NSView {
            let hosting = NSHostingView(rootView: content)
            hosting.sizingOptions = [.intrinsicContentSize]
            hosting.translatesAutoresizingMaskIntoConstraints = false
            return hosting
        }
    }
}
