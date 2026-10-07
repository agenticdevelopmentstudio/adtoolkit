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

    /// The build (`CFBundleVersion`) that last ran `WindowManager.restoreOnLaunch()`.
    /// A launch whose build differs follows an update, and restores the windows
    /// left open whatever the system's close-on-quit preference says (see
    /// `ReopenOnLaunchPolicy.shouldReopen(systemDefault:followingUpdate:)`).
    /// Empty until the first launch that records it — which counts as following
    /// an update, so a build that predates this setting is covered too.
    public static let lastLaunchedBuild = UserSetting<String>("lastLaunchedBuild", default: "")
}
