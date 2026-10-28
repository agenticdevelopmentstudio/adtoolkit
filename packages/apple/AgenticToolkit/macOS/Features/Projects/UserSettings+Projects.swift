import Foundation
import AgenticToolkitCore

extension UserSettings {

    /// Folder names the project scan refuses to descend into, matched as
    /// case-insensitive globs against the home directory's own folders.
    ///
    /// The scan itself takes this list as a plain `[String]` parameter rather
    /// than reading the setting — the scanner runs off the main actor, and a
    /// pure walk that is told what to skip is testable without a settings
    /// store (`dependency-injection`).
    public static let projectScanSkipPatterns = UserSetting<[String]>(
        "projectScanSkipPatterns",
        default: GitRepoScanner.defaultRootSkipPatterns
    )

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
}
