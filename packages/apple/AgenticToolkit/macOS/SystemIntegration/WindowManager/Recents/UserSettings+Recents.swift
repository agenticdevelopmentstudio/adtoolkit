import Foundation
import AgenticToolkitCore

extension UserSettings {

    /// Maximum number of recent documents shown in File → Open Recent.
    /// Mirrored to `NSDocumentController.maximumRecentDocumentCount` by
    /// `WindowManager.applyRecentDocumentCountFromSettings()`.
    public static let recentWindowsCount = UserSetting<Int>("recentWindowsCount", default: 10)

    /// Whether windows reopen at launch.
    public static let reopenOnLaunchPolicy = UserSetting<ReopenOnLaunchPolicy>(
        "reopenOnLaunchPolicy",
        default: .useSystem
    )

    /// The build (`CFBundleVersion`) that last ran `WindowManager.restoreOnLaunch()`,
    /// per copy of the app on disk (keyed by `WindowStateNamespace.current`).
    /// A launch whose build differs follows an update, and restores the windows
    /// left open whatever the system's close-on-quit preference says (see
    /// `ReopenOnLaunchPolicy.shouldReopen(systemDefault:followingUpdate:)`).
    /// Absent until a copy's first launch records it — which counts as
    /// following an update, so a build that predates this setting is covered too.
    public static let lastLaunchedBuilds = UserSetting<[String: String]>("lastLaunchedBuilds", default: [:])

    /// The copies of the app (keyed by `WindowStateNamespace.current`) whose
    /// updater will install a downloaded update when the person next quits —
    /// a quit of their own, so the launch after it is not an update relaunch.
    /// Set by `WindowManager.noteUpdateWillInstallOnQuit()`, cleared by
    /// `noteUpdateWillRelaunch()` and by the launch that reads it.
    public static let updateInstallsOnQuit = UserSetting<[String: Bool]>("updateInstallsOnQuit", default: [:])
}
