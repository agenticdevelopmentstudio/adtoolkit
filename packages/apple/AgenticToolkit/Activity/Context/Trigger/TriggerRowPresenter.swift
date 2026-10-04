import Foundation

/// One trigger row's state as the settings panel should show it, computed
/// purely from the daemon's last `triggerStates()` reply (or its absence).
///
/// `.unknown` is a real, distinct state, not a stand-in for `.off`. The
/// daemon's reply is all-or-nothing — `ReplyOnce`'s fallback on a dropped
/// reply is empty `Data`, which is not valid JSON, so `DaemonControl.
/// triggerStates()` answers `[]` for "the daemon hasn't told us yet" the same
/// way it would for "the daemon has nothing to say" — every row is unknown
/// together in that case, never confidently rendered as off.
public struct TriggerRowState: Sendable, Equatable {
    public enum Availability: Sendable, Equatable {
        case unknown
        case off
        /// `isEnabled == false` but `isRunning == true`: the opt-in reads as
        /// off (which can itself mean "user turned it off" or "olylod
        /// failed closed after a settings-read error" — the client cannot
        /// tell which), but the trigger has not actually stopped collecting
        /// yet. Rendering this as plain `.off` would show an unchecked box
        /// for a trigger that is, at that moment, still recording — the
        /// more dangerous direction of the consent lie `.unknown` guards
        /// against, so it gets its own case rather than being folded into
        /// `.off`.
        case offButRunning
        case on
    }

    public let kind: ContextEventKind
    public let availability: Availability
    public let permission: ContextPermission
    public let permissionState: ContextPermissionState

    /// The user has asked for this trigger but the daemon has not actually
    /// started collecting for it — almost always a missing permission. See
    /// `TriggerState.isRunning`'s doc for why this can disagree with
    /// `availability` in either direction. Only meaningful when
    /// `availability == .on`.
    public let isBlocked: Bool

    /// Whether the row's control should accept user input. False only while
    /// `availability == .unknown` — a row we've never heard the daemon's
    /// answer for is not safe to toggle blind.
    public var isControlEnabled: Bool { availability != .unknown }

    /// What the checkbox glyph should show: `nil` for AppKit's third,
    /// "mixed" state (`NSControl.StateValue.mixed`), never collapsed into
    /// `false`. `.unknown` means "we don't know," which is not the same
    /// claim as "off," and `false` is exactly the claim an unchecked box
    /// makes. `.offButRunning` reads as checked because that is what is
    /// actually happening right now — see its doc above.
    public var isChecked: Bool? {
        switch availability {
        case .unknown:       return nil
        case .off:            return false
        case .offButRunning:  return true
        case .on:             return true
        }
    }

    public init(
        kind: ContextEventKind,
        availability: Availability,
        permission: ContextPermission,
        permissionState: ContextPermissionState,
        isBlocked: Bool
    ) {
        self.kind = kind
        self.availability = availability
        self.permission = permission
        self.permissionState = permissionState
        self.isBlocked = isBlocked
    }

    /// The state before the daemon has answered for `kind` at all.
    public static func unknown(_ kind: ContextEventKind) -> TriggerRowState {
        TriggerRowState(
            kind: kind, availability: .unknown, permission: .none,
            permissionState: .undetermined, isBlocked: false)
    }
}

/// Pure mapping from daemon wire state to what the settings panel shows.
/// Kept out of AppKit so it is unit-testable in `AgenticToolkitActivityTests` without a
/// settings window — the AppKit layer's job is only to project these values
/// onto controls (fact 5 of Task 16: as much logic as possible lives in
/// shared code, precisely because neither `Olylo` nor `olylod` has a test
/// bundle of its own).
public enum TriggerRowPresenter {
    /// `states` is the full `triggerStates()` reply. An empty array means the
    /// daemon has not answered for ANY kind — every row this produces from
    /// it is `.unknown`, never `.off`.
    public static func state(for kind: ContextEventKind, in states: [TriggerState]) -> TriggerRowState {
        guard let match = states.first(where: { $0.kind == kind }) else {
            return .unknown(kind)
        }
        let availability: TriggerRowState.Availability
        if match.isEnabled {
            availability = .on
        } else if match.isRunning {
            // Reads as "off" but is still collecting — see `offButRunning`'s
            // doc. Distinct from the plain-off case so the checkbox does not
            // silently claim nothing is being recorded while it is.
            availability = .offButRunning
        } else {
            availability = .off
        }
        return TriggerRowState(
            kind: kind,
            availability: availability,
            permission: match.permission,
            permissionState: match.permissionState,
            isBlocked: match.isEnabled && !match.isRunning)
    }

    /// What a click on a row currently showing `row` is asking the daemon for.
    ///
    /// Computed from the state the panel last *rendered*, never from the
    /// checkbox's state after the click. That distinction is the whole point:
    /// a three-state `NSButton` advances **off → mixed → on → off** (measured
    /// with `performClick`, not assumed). The panel shipped once reading
    /// intent as `state == .on` under a comment asserting the cycle was
    /// off → on → mixed → off, so every click on an unchecked box landed on
    /// `.mixed`, was read as "not on", and sent `enabled: false` — no trigger
    /// could be switched on at all, and the entire opt-in surface was inert
    /// while looking perfectly healthy.
    ///
    /// The rendered state is ours and its meaning is fixed; the post-click
    /// state belongs to AppKit's cycle and its meaning is not. So a click
    /// means "on" unless the row was already showing checked.
    /// `.offButRunning` shows checked and therefore reads as "turn it off",
    /// which is already what the persisted setting says — a harmless no-op,
    /// and the reading that matches the box the user actually clicked.
    public static func intent(forClickOn row: TriggerRowState) -> Bool {
        row.isChecked != true
    }

    /// The blurb shown under a row, or `nil` when there is nothing to say.
    public static func explanation(for row: TriggerRowState) -> String? {
        switch row.availability {
        case .unknown:
            return "Waiting for olylod to answer…"
        case .off:
            return nil
        case .offButRunning:
            return "Still recording — olylod hasn't confirmed this is off yet. "
                + "It should stop within \(ContextRefresh.phrase)."
        case .on:
            guard row.isBlocked else { return nil }
            guard row.permission != .none else {
                // Blocked for a reason other than a missing permission (the
                // trigger's own `start()` threw, an internal error, etc.) —
                // `title(for: .none)` is "no", and "Waiting on no permission"
                // is not a sentence anyone should read.
                return "Not running yet. It should start within \(ContextRefresh.phrase)."
            }
            return "Waiting on \(title(for: row.permission)) permission "
                + "(currently \(row.permissionState.rawValue))."
        }
    }

    public static func title(for kind: ContextEventKind) -> String {
        switch kind {
        case .appFocus: return "Apps and windows you switch to"
        case .window:   return "Windows opening, closing and being renamed"
        case .input:    return "Whether you're typing or moving the mouse (never what you type)"
        case .session:  return "Locking, unlocking, sleeping and waking"
        case .power:    return "Battery and power source"
        case .network:  return "Wi-Fi and network changes"
        case .location: return "Where this Mac is"
        case .appLifecycle: return "Apps starting and quitting"
        }
    }

    /// What to say after olylod has asked the OS for a permission, and whether
    /// the owner has to be sent to System Settings to finish the job.
    ///
    /// A value rather than a side effect: the decision is a pure function of
    /// the result and the permission, and only the act of opening a pane is
    /// AppKit's business.
    public struct PermissionRequestAdvice: Sendable, Equatable {
        /// The note shown under the "Grant…" button.
        public let message: String

        /// True when the request cannot be retried and the System Settings
        /// pane is the only route left.
        public let opensSystemSettings: Bool

        public init(message: String, opensSystemSettings: Bool) {
            self.message = message
            self.opensSystemSettings = opensSystemSettings
        }
    }

    /// Turns a `PermissionRequestResult` into what the owner is told.
    ///
    /// Here rather than in the settings panel because it is a rule, and
    /// because it is the copy that has to survive the one fact this branch
    /// keeps having to re-learn: **there is no `olylod` row in System
    /// Settings**. olylod ships inside the app bundle and macOS authorizes the
    /// two under the app's identity, so the entry to switch on is *Olylo*.
    /// Telling someone to look for olylod sends them hunting for a row that
    /// does not exist.
    public static func advice(for result: PermissionRequestResult,
                              permission: ContextPermission) -> PermissionRequestAdvice {
        let name = title(for: permission)
        switch result {
        case .granted:
            return PermissionRequestAdvice(
                message: "olylod has \(name) permission.",
                opensSystemSettings: false)
        case .denied, .undetermined:
            // The daemon asked and did not get it. macOS shows its prompt only
            // once per executable, ever, and answers from its own database
            // afterwards — so "no prompt appeared" is the normal case here,
            // not a failure, and the only route left is the Settings pane.
            return PermissionRequestAdvice(
                message: "macOS didn't grant \(name). Open the list that just appeared and "
                    + "switch on Olylo — that one entry covers olylod too. (macOS only ever "
                    + "shows its own prompt once per program, so after the first time this "
                    + "is the only way to change it.)",
                opensSystemSettings: true)
        case .notNeeded:
            // Refused by the daemon, on purpose: asking would put a system
            // consent dialog on screen for capture nobody switched on.
            return PermissionRequestAdvice(
                message: "Nothing needs \(name) yet. Switch on a trigger above that asks "
                    + "for it, then try again.",
                opensSystemSettings: false)
        case .unavailable:
            return PermissionRequestAdvice(
                message: "olylod isn't responding, so nothing was asked for.",
                opensSystemSettings: false)
        }
    }

    public static func title(for permission: ContextPermission) -> String {
        switch permission {
        case .none:          return "no"
        case .accessibility: return "Accessibility"
        case .location:      return "Location"
        }
    }
}
