#if os(macOS)
import AgenticToolkitPermissions
import AgenticToolkitPermissionsUI

/// Accessibility check/prompt gating the capture toggle: capture reads window
/// titles, so a Start attempt without the grant routes through the system
/// prompt (or Settings) before it flips the daemon on.
public enum CapturePermission {
    public static func isGranted() async -> Bool {
        await SystemPermissionChecker().isGranted(.accessibility)
    }

    @MainActor
    public static func requestOrOpenSettings() async {
        let checker = SystemPermissionChecker()
        // The presenter acts on the status the caller's control offered; this
        // entry point has no control, so it offers what the system says now.
        let shown: PermissionStatus = await checker.isGranted(.accessibility) ? .granted : .denied
        await PermissionPresenter.present(.accessibility, shownAs: shown, using: checker)
    }
}
#endif
