import Foundation

/// The OS permission a trigger needs before it may run. Deliberately its own
/// enum rather than AgenticToolkitPermissions' `Permission`: that type is
/// macOS-only and AppKit-flavoured, and this protocol has to compile on iOS,
/// Android and Windows ports. The mapping lives in `MacPermissionGate`.
public enum ContextPermission: String, Sendable, Codable, CaseIterable {
    case none
    case accessibility
    case location
}

public enum ContextPermissionState: String, Sendable, Codable {
    case granted, denied, undetermined
}

/// What came of asking the OS for a permission. Distinct from
/// `ContextPermissionState` because two of its cases are about the *request*
/// rather than the permission: nobody asked, or nobody could.
public enum PermissionRequestResult: String, Sendable, Codable {
    /// The OS was asked and the permission is now granted.
    case granted
    /// The OS was asked and the permission is not granted. Includes "the user
    /// has already decided, so no prompt was shown" — macOS prompts once per
    /// executable, ever, and answers from the TCC database thereafter.
    case denied
    /// Asked, and still nothing decided (a prompt the user dismissed, or one
    /// that never appeared).
    case undetermined
    /// Refused: no trigger the user has opted into needs this permission, so
    /// nothing was asked for. Requesting a permission is a real, visible,
    /// once-ever act, and doing it for a trigger nobody enabled would put a
    /// consent dialog in front of the user for capture they never asked for
    /// (I-4).
    case notNeeded = "not_needed"
    /// Nobody could answer — the collector is not available (the database
    /// failed to open), or the permission name was not recognised.
    case unavailable
}

/// How often the daemon re-checks the gates of triggers whose start decision
/// has already been made.
///
/// It lives here, beside the trigger contract, rather than in the daemon that
/// schedules it. Two things need this number: `ContextStrategy`, which drives
/// `ContextCollector.refresh()` on it, and the settings panel's copy, which
/// promises the owner a row will settle "within about 30 seconds". A literal
/// in the copy makes retuning the schedule silently turn that promise into a
/// lie, so both read the one value. Outside the database-gated part of this
/// module on purpose, so a port with no database still has the constant.
public enum ContextRefresh {
    public static let interval: Duration = .seconds(30)

    /// The interval as user-facing copy — "about 30 seconds", "about 2
    /// minutes" — so a sentence can be built around it without spelling the
    /// number out.
    public static var phrase: String {
        let seconds = Int(interval.components.seconds)
        guard seconds >= 60, seconds % 60 == 0 else {
            return "about \(seconds) seconds"
        }
        let minutes = seconds / 60
        return "about \(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}

/// Answers "may we run a trigger needing this permission right now?", and
/// asks the OS for it.
///
/// An implementation MUST answer `.granted` for `.none`: `ContextCollector`
/// consults the gate for every trigger, including the five of the eight kinds
/// with no real OS permission requirement (`session`, `power`, `network`,
/// `input`, `app_lifecycle`), so any other answer for `.none` would silently
/// and permanently block those triggers from ever starting, with no error
/// raised anywhere. The other three do need one: `app_focus` and `window`
/// require `.accessibility`, and `location` requires `.location`.
public protocol ContextPermissionGate: Sendable {
    func status(_ permission: ContextPermission) async -> ContextPermissionState

    /// Asks the OS for `permission`, prompting if it can, and answers with the
    /// state that resulted.
    ///
    /// This belongs on the gate — i.e. in the daemon's process — because the
    /// answer has to be observed by the process that will do the reading, at
    /// the moment it reads. Not, as I-4 originally reasoned, because olylod
    /// carries a TCC identity of its own: measured on macOS 26 it does not,
    /// and the grant lands on `app.olylo.Olylo` whichever of the two asks.
    /// `MacPermissionGate.request` records what was observed.
    func request(_ permission: ContextPermission) async -> ContextPermissionState
}

extension ContextPermissionGate {
    /// Default for gates that cannot prompt (the iOS/no-op side, and test
    /// fakes): report what is already known rather than pretend to ask.
    public func request(_ permission: ContextPermission) async -> ContextPermissionState {
        await status(permission)
    }
}

/// One observed source of context. `@MainActor` because every macOS
/// implementation observes AppKit/AX/CoreLocation, all of which deliver on the
/// main run loop; keeping the protocol itself main-actor means an
/// implementation never has to hop just to hand an event back.
@MainActor
public protocol ContextTrigger: AnyObject {
    var kind: ContextEventKind { get }
    var requiredPermission: ContextPermission { get }

    /// Set by `ContextCollector`. A trigger emits a detail plus the moment it
    /// observed — it never builds a `ContextEvent`, because it does not know
    /// the machine id and must not decide whether the event is allowed.
    var onEvent: ((ContextEventDetail, Date) -> Void)? { get set }

    func start() throws
    func stop()
}
