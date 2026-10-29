import AppKit

import AgenticToolkitCore

/// How project windows behave and where projects come from: how a pane shows
/// it is the active one, which directories the project scan walks, which it
/// stays out of, and what it leaves out inside them. Filed under Workspace; how
/// a project window *looks* is `ProjectsAppearancePanelViewController`,
/// under Appearance.
///
/// Every change here is written straight to its setting, and
/// `ProjectsCoordinator` observes all four scan settings: the project list
/// drops what they now leave out at once and a quiet scan picks up what they
/// newly cover. The panel does not ask for a rescan itself — a change made
/// anywhere else takes the identical path (`dry`).
@MainActor
public final class ProjectsSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    private var directoriesCard: ComposableSettings.EditableTableCard?
    private var skippedCard: ComposableSettings.EditableTableCard?
    private var observers: [AnyObject] = []

    private static let pathColumn = "path"

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Projects",
            icon: NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The sidebar's search only reads the controls of a panel that has already
    /// been opened, so this panel names what it is about for the search that
    /// happens before anyone opens it.
    public override var searchKeywords: [String] {
        ["project", "active pane", "outline", "highlight", "follows mouse",
         "project directories", "folder", "skipped", "exclude", "scan",
         "hidden", "invisible", "submodule"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Active Pane",
                body: "A project window is split into panes, and one of them is the one you "
                    + "are working in. With this on, that pane is drawn with a border in a "
                    + "tone one step lighter than the others — enough to find it, not enough "
                    + "to compete with what is inside it."
            ),
            .init(
                title: "Active Pane Follows the Mouse",
                body: "With this on, the pane under the pointer becomes the active one as "
                    + "soon as the pointer is over it, and the keyboard goes with it — so a "
                    + "window that is already in front can be typed into without clicking "
                    + "first. Only the front window follows the pointer: passing over a "
                    + "window behind it changes nothing, because that window is not the one "
                    + "taking the keys. The keys land where a click at that spot would have "
                    + "put them, which is the terminal, the list or the field the pointer is "
                    + "actually over rather than the pane as a whole. Off, the active pane "
                    + "is the one you last clicked in."
            ),
            .init(
                title: "Themes Override This",
                body: "A theme can carry its own answer for whether the active pane is "
                    + "outlined, and in what color, under the theme's Project topic in Theme "
                    + "settings. When it does, the theme wins over the switch here. A theme "
                    + "has no project options until you set them."
            ),
            .init(
                title: "Project Directories",
                body: "The directories the project scan looks through for git repositories. "
                    + "Nothing is scanned until you add one: press + and choose one or more "
                    + "directories, select one and press − to stop scanning it. Every "
                    + "repository anywhere inside is a project, except what the two sections "
                    + "below leave out. A change takes effect at once — the project list "
                    + "updates and a quiet scan runs."
            ),
            .init(
                title: "Skipped Directories",
                body: "Directories the scan never looks inside, wherever they are. Projects "
                    + "already found under one stay registered, so their window layouts "
                    + "survive, but they are not listed; remove the directory here and they "
                    + "come straight back."
            ),
            .init(
                title: "Options",
                body: "Skip invisible directories keeps the scan out of every directory whose "
                    + "name starts with a dot — tool caches, virtual environments and the "
                    + "worktrees an agent makes. Skip submodule directories leaves out the "
                    + "submodules of the repositories found; off, each checked-out submodule "
                    + "is listed as a project of its own. Both are on to begin with."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addGroup(createActivePaneGroup())

        let directories = makeDirectoryCard(
            title: "Project Directories",
            emptyMessage: "No project directories. Press + to choose one.",
            accessibilityPrefix: "settings.projects.directories",
            setting: UserSettings.projectDirectories,
            prompt: "Add"
        )
        directoriesCard = directories
        addGroup(directories)

        let skipped = makeDirectoryCard(
            title: "Skipped Directories",
            emptyMessage: "Nothing is being skipped.",
            accessibilityPrefix: "settings.projects.skipped",
            setting: UserSettings.projectSkippedDirectories,
            prompt: "Skip"
        )
        skippedCard = skipped
        addGroup(skipped)

        addGroup(createOptionsGroup())

        observers = [
            UserSettingObserver(UserSettings.projectDirectories) { [weak self] _ in self?.reloadRows() },
            UserSettingObserver(UserSettings.projectSkippedDirectories) { [weak self] _ in self?.reloadRows() }
        ]
        reloadRows()
    }

    // MARK: - Groups

    private func createActivePaneGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Active Pane")
        group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Outline the active pane",
            setting: UserSettings.highlightActivePane
        )))
        group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Active pane follows the mouse",
            setting: UserSettings.activePaneFollowsMouse
        )))
        return group
    }

    private func createOptionsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Options")
        group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Skip invisible directories",
            setting: UserSettings.projectScanSkipsHiddenDirectories
        )))
        group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Skip submodule directories",
            setting: UserSettings.projectScanSkipsSubmodules
        )))
        return group
    }

    /// A list of directories with + and −: + asks for directories with an open
    /// panel, − removes the selected one. The two lists differ only in what
    /// they are called and which setting they write, so they are one builder
    /// (`dry`).
    private func makeDirectoryCard(
        title: String,
        emptyMessage: String,
        accessibilityPrefix: String,
        setting: UserSetting<[String]>,
        prompt: String
    ) -> ComposableSettings.EditableTableCard {
        let card = ComposableSettings.EditableTableCard(
            title: title,
            columns: [.init(id: Self.pathColumn, title: "Directory", width: 420)],
            emptyMessage: emptyMessage,
            visibleRows: 4,
            accessibilityPrefix: accessibilityPrefix
        )
        card.onAdd = { [weak self] in
            self?.chooseDirectories(prompt: prompt) { chosen in
                let current = setting.currentValue
                let added = chosen.filter { !current.contains($0) }
                guard !added.isEmpty else { return }
                setting.value = current + added
            }
        }
        card.onRemove = { rowID in
            // The path itself is the row id, so the row removed is the one the
            // user selected even if the list changed under it since it drew.
            setting.value = setting.currentValue.filter { $0 != rowID }
        }
        return card
    }

    // MARK: - Rows

    private func reloadRows() {
        directoriesCard?.setRows(Self.rows(for: UserSettings.projectDirectories.currentValue))
        skippedCard?.setRows(Self.rows(for: UserSettings.projectSkippedDirectories.currentValue))
    }

    private static func rows(for paths: [String]) -> [ComposableSettings.EditableTableRow] {
        paths.map { path in
            ComposableSettings.EditableTableRow(id: path, cells: [
                pathColumn: .text((path as NSString).abbreviatingWithTildeInPath)
            ])
        }
    }

    // MARK: - Choosing

    /// Asks for one or more directories, as a sheet on the settings window
    /// when there is one, and hands back their standardized paths.
    private func chooseDirectories(prompt: String, then use: @escaping ([String]) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.prompt = prompt
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        let finish: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK else { return }
            use(panel.urls.map { $0.standardizedFileURL.path })
        }
        if let window = view.window {
            panel.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(panel.runModal())
        }
    }
}
