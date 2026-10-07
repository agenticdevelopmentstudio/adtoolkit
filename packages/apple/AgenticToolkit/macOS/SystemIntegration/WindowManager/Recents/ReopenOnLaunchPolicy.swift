import Foundation

/// Whether the app should reopen previously-open windows at launch. Modeled
/// on Xcode's "Restore open projects and workspaces" preference.
public enum ReopenOnLaunchPolicy: String, Codable, Sendable, CaseIterable, Equatable {
    /// Follow macOS's system-wide "Close windows when quitting an
    /// application" preference (i.e. `NSQuitAlwaysKeepsWindows`).
    case useSystem
    /// Always reopen, regardless of the system setting.
    case always
    /// Never reopen, regardless of the system setting.
    case never

    public var displayName: String {
        switch self {
        case .useSystem: return "Use System Setting"
        case .always: return "Always"
        case .never: return "Never"
        }
    }

    public func shouldReopen(systemDefault: Bool) -> Bool {
        shouldReopen(systemDefault: systemDefault, followingUpdate: false)
    }

    /// Whether to reopen, knowing whether this launch follows an update.
    ///
    /// **An update relaunch reopens unless the reader said `never`.** The
    /// system's "Close windows when quitting an application" is about a quit
    /// the person chose; an update quits the app for them and relaunches it,
    /// and the windows they left open have to come back as they were. The
    /// macOS default for that preference is to close windows, so following it
    /// here left every stock Mac with an empty screen after each update.
    public func shouldReopen(systemDefault: Bool, followingUpdate: Bool) -> Bool {
        switch self {
        case .useSystem: return systemDefault || followingUpdate
        case .always: return true
        case .never: return false
        }
    }

    /// macOS-wide preference: when ON, the system preserves windows across
    /// quit/relaunch cycles. The System Settings UI inverts the label
    /// ("Close windows when quitting an application" — checking it sets
    /// `NSQuitAlwaysKeepsWindows = false`).
    public static var systemDefault: Bool {
        UserDefaults.standard.bool(forKey: "NSQuitAlwaysKeepsWindows")
    }
}
