import AppKit

import AgenticToolkitCore

/// How a project window looks: how much room its panes are given, around them
/// and between them. Filed under Appearance; how a project window *behaves* —
/// the active pane, and which directories hold projects — is
/// `ProjectsSettingsPanelViewController`, under Workspace.
@MainActor
public final class ProjectsAppearancePanelViewController: ComposableSettings.SettingsPanelViewController {

    /// Held so the panel can join their Tab orders end to end — see
    /// `joinTabOrder()`.
    private var frameSpacing: SpacingControl?
    private var dividerSpacing: SpacingControl?

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Projects",
            icon: NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The sidebar's search only reads the controls of a panel that has already
    /// been opened, so this panel names what it is about for the search that
    /// happens before anyone opens it.
    public override var searchKeywords: [String] {
        ["project", "spacing", "frame", "divider", "gutter", "pane"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Frame Spacing",
                body: "The room between the panes and the tab bars framing them, in points, "
                    + "set per side. Each number stands outside the diagram, in line with "
                    + "the edge it belongs to. Every arrow stands against that edge and "
                    + "points the way it travels, so the arrow pointing into the view is "
                    + "the one that adds space. Hold an arrow down to "
                    + "keep going, or type a number and press Return. The stepper beside "
                    + "each number adjusts it a point at a time."
            ),
            .init(
                title: "Pane Divider Spacing",
                body: "The gaps between panes: one number for panes side by side, one for "
                    + "panes stacked, each sitting on the divider it opens. The arrows "
                    + "pointing at the divider close the gap; the ones pointing away open "
                    + "it. Each number is the whole gap, not each pane's half — ten means "
                    + "ten points between two panes. A gap of zero still drags: the divider "
                    + "keeps a few points of grab area whatever it is drawn at. Spacing "
                    + "belongs to the app, so every project window is spaced the same way."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(createFrameGroup())
        addGroup(createDividerGroup())
        joinTabOrder()
    }

    // MARK: - Groups

    /// The same two pictures the project window's own Spacing sheet shows,
    /// bound to the same app-wide keys — one pair of controls, two places they
    /// are reachable from.
    ///
    /// Two groups rather than one, because they answer two questions: how much
    /// room around the panes, and how much room between them. One diagram
    /// carrying both put six numbers on one picture and made the reader work
    /// out which four were the outside.
    private func createFrameGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Frame Spacing")
        let control = SpacingControl.boundToSettings(style: .frame, edges: PaneSpacing.edgeSettings)
        frameSpacing = control
        group.addSettingSubview(control)
        return group
    }

    private func createDividerGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Pane Divider Spacing")
        let control = SpacingControl.boundToSettings(
            style: .paneDividers,
            gutters: PaneSpacing.gutterSettings
        )
        dividerSpacing = control
        group.addSettingSubview(control)
        return group
    }

    /// Tab out of the last number in one group and into the first number of the
    /// next.
    ///
    /// Each control answers Tab within itself and hands the key back at either
    /// end, which is where AppKit takes over — and AppKit works the key view
    /// loop out from where subviews *are*. These are placed by frame, so left
    /// to itself Tab out of the bottom number went somewhere that looked like
    /// nowhere. Which control follows which is the panel's knowledge, so the
    /// panel is what says it. `nextKeyView` sets the back link too, so
    /// Shift-Tab walks the same chain the other way.
    private func joinTabOrder() {
        frameSpacing?.lastNumberField?.nextKeyView = dividerSpacing?.firstNumberField
    }
}
