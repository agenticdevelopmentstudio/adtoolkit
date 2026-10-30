import Foundation
import AgenticToolkitCore

extension UserSettings {

    /// The directories the project scan walks, as absolute paths.
    ///
    /// Empty by default: the scan used to walk `~` on its own, and now walks
    /// only what the user has named. The scanner takes these as plain values
    /// rather than reading the settings — it runs off the main actor, and a
    /// walk that is told what to cover is testable without a settings store
    /// (`dependency-injection`).
    public static let projectDirectories =
        UserSetting<[String]>("project_directories", default: [])

    /// Directories the project scan never enters, as absolute paths.
    public static let projectSkippedDirectories =
        UserSetting<[String]>("project_skipped_directories", default: [])

    /// Whether the project scan stays out of dot-directories.
    public static let projectScanSkipsHiddenDirectories =
        UserSetting<Bool>("project_scan_skips_hidden_directories", default: true)

    /// Whether the project scan leaves out the submodules of the repositories
    /// it finds.
    public static let projectScanSkipsSubmodules =
        UserSetting<Bool>("project_scan_skips_submodules", default: true)

    /// A scanner configured by the four settings above, read now.
    @MainActor
    public static func projectScanner() -> GitRepoScanner {
        GitRepoScanner(
            roots: projectDirectories.currentValue.map { URL(fileURLWithPath: $0) },
            skippedDirectories: projectSkippedDirectories.currentValue.map { URL(fileURLWithPath: $0) },
            skipsHiddenDirectories: projectScanSkipsHiddenDirectories.currentValue,
            skipsSubmodules: projectScanSkipsSubmodules.currentValue
        )
    }

    /// Whether the pane the user last clicked in is outlined. Lives with the
    /// project settings rather than the appearance ones because it is about a
    /// project window's panes — nothing else in the app has any.
    /// `ThemeProjectOptions.highlightActivePane` overrides it.
    static public var highlightActivePane = UserSetting<Bool>("highlight_active_pane", default: true)

    /// Whether moving the pointer over a pane makes it the active one and hands
    /// it the keyboard, so a window in front can be typed into without a click.
    ///
    /// Off by default. Focus that moves without being asked to is a preference
    /// people hold strongly in both directions, and the surprising answer — the
    /// keys going somewhere the user did not put them — is the wrong default.
    static public var activePaneFollowsMouse =
        UserSetting<Bool>("active_pane_follows_mouse", default: false)

    /// The `git_repo.id` of the project window that was key most recently, as
    /// a UUID string; empty before any has been.
    ///
    /// A project opened for the first time is laid out like that window — its
    /// tab edges, panes and dividers — and placed at its size, so arranging
    /// one window is arranging the next. An id rather than a copy of the
    /// layout: the layout already lives in that project's rows, and a second
    /// copy here would be a second answer to "how is it arranged" (`dry`).
    static public var lastActiveProjectWindow =
        UserSetting<String>("last_active_project_window", default: "")

    /// Whether project windows show the project shelf — the list of projects
    /// down the window's leading edge. One answer for every project window,
    /// not one per project: choosing a project in the shelf replaces the
    /// window with that project's, and a shelf that vanished the moment it
    /// was used would be no way to move between projects.
    static public var projectShelfVisible = UserSetting<Bool>("project_shelf_visible", default: false)

    /// How wide the project shelf is, in points, as the reader last dragged it.
    /// Shared for the same reason as `projectShelfVisible`.
    static public var projectShelfWidth = UserSetting<Double>("project_shelf_width", default: 240)

    /// Every project window, as it stood the last time one changed: which
    /// projects each has active, which of them it shows, and which shelf panel
    /// is up. Read once at launch by `ProjectWindowManager.restoreOpenProjects()`
    /// and rewritten on every change after that, so a quit — however it
    /// happens — leaves the windows to come back as they were.
    ///
    /// An app preference rather than a `project_setting` row: a window is not
    /// one project's, it holds several, and the row it would belong to does
    /// not exist.
    static public var projectWindows = UserSetting<[ProjectWindowState]>("project_windows", default: [])
}
