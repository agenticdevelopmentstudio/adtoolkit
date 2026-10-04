#if os(macOS)
import Foundation
import AgenticToolkitPermissions

/// Bridges the cross-platform `ContextPermission` onto AgenticToolkit's
/// macOS-flavoured `Permission`. This mapping is the only place the two
/// vocabularies meet, so an Android/Windows port supplies its own gate and
/// nothing else changes.
public struct MacPermissionGate: ContextPermissionGate {
    private let checker: any PermissionChecking

    public init(checker: any PermissionChecking = SystemPermissionChecker()) {
        self.checker = checker
    }

    /// `nil` means "no OS permission is involved" — not "unknown".
    public static func toolkitPermission(for permission: ContextPermission) -> Permission? {
        switch permission {
        case .none:          return nil
        case .accessibility: return .accessibility
        case .location:      return .location
        }
    }

    public func status(_ permission: ContextPermission) async -> ContextPermissionState {
        guard let toolkit = Self.toolkitPermission(for: permission) else { return .granted }
        switch await checker.status(toolkit) {
        case .granted:      return .granted
        case .denied:       return .denied
        case .undetermined: return .undetermined
        }
    }

    /// Prompts for the permission a trigger needs.
    ///
    /// Called **in `olylod`**, reached from the app over XPC (I-4). The
    /// reason I-4 gave for that was wrong, and the correction matters here
    /// because it is the opposite of what you would guess: I-4 assumed olylod
    /// carried its own TCC identity, so a prompt raised in the app's process
    /// would authorize `Olylo.app` and leave the daemon blocked. Measured on
    /// macOS 26 instead — after olylod answered `granted` for Accessibility,
    /// `TCC.db` held **no `olylod` row at all**, only `app.olylo.Olylo`,
    /// allowed. olylod ships inside the app bundle and is authorized under
    /// the app's identity, which is also why it can use CoreLocation at all:
    /// the `NSLocation*UsageDescription` strings it needs live in
    /// `Olylo.app/Contents/Info.plist` and nowhere else. So there is no
    /// `olylod` row for the owner to find in System Settings, and no copy may
    /// send them looking for one — see `TriggerRowPresenter.advice`.
    ///
    /// Asking from olylod is still right, for a reason that survives the
    /// correction: the answer has to be observed by the process that will do
    /// the reading, at the moment it reads. See
    /// `ContextCollector.requestPermission` for the consent check that guards
    /// this, and `docs/planning/STATUS.md` ("Verification status") for what
    /// each permission was observed to do from the daemon on real hardware.
    @discardableResult
    public func request(_ permission: ContextPermission) async -> ContextPermissionState {
        guard let toolkit = Self.toolkitPermission(for: permission) else { return .granted }
        switch await checker.request(toolkit) {
        case .granted:      return .granted
        case .denied:       return .denied
        case .undetermined: return .undetermined
        }
    }
}
#endif
