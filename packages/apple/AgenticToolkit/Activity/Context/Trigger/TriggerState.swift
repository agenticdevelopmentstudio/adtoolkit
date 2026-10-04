import Foundation

/// What the app shows and the daemon reports over XPC for one trigger.
/// `Codable` because it crosses the XPC boundary as JSON — `@objc` XPC
/// protocols cannot carry Swift enums directly.
public struct TriggerState: Sendable, Codable, Equatable {
    public let kind: ContextEventKind
    public let isEnabled: Bool
    public let permission: ContextPermission
    public let permissionState: ContextPermissionState
    /// What the collector actually has attached as of the last gate
    /// evaluation (`start()`, `setEnabled`, or `refresh()`). Distinct from
    /// `isEnabled` so the UI can say "on, but blocked by a missing
    /// permission" — and the two CAN disagree in the other direction too:
    /// `isEnabled` fails closed to `false` when the settings read throws,
    /// while a trigger already running keeps running until the next gate
    /// evaluation notices, so a transient settings-read failure can show
    /// `isEnabled: false, isRunning: true`.
    public let isRunning: Bool

    public init(kind: ContextEventKind, isEnabled: Bool, permission: ContextPermission,
                permissionState: ContextPermissionState, isRunning: Bool) {
        self.kind = kind; self.isEnabled = isEnabled; self.permission = permission
        self.permissionState = permissionState; self.isRunning = isRunning
    }
}
