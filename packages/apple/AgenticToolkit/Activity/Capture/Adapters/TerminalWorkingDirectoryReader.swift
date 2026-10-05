// Apple Events reading of a terminal's working directory — macOS only (c2).
#if os(macOS)
import Foundation
import AgenticToolkitPermissions

/// Reads the directory a terminal window is sitting in, so a focus event on a
/// terminal records *where* the work is happening and not only that a terminal
/// was frontmost.
///
/// A terminal has no document in the sense `kAXDocumentAttribute` means, so
/// ``FrontmostFocusAdapter`` gets nothing from Accessibility here and neither
/// would a subtree walk: the working directory is not drawn anywhere in the
/// window unless the owner happens to have turned on a status-bar component
/// that shows it. It exists only as something the app knows and will tell you
/// if you ask over Apple Events. That is what this asks.
///
/// **This costs a second permission.** Everything else the capture pipeline
/// reads runs on the Accessibility grant; Apple Events is Automation, which
/// macOS grants per *target app* — a grant to control iTerm2 is not a grant to
/// control anything else. ``consent`` is how that is handled: the first time a
/// supported terminal is frontmost the system consent dialog is raised once,
/// off the main thread, and that read returns nothing. From the answer onward
/// no probe is paid at all — a granted reader just asks, a denied one stops
/// asking for the rest of the run rather than re-probing on every focus change.
@MainActor
public final class TerminalWorkingDirectoryReader {
    /// The terminals whose working directory can be read, and the script that
    /// asks each one.
    ///
    /// Only iTerm2 is here, and the reason is not that the others were not
    /// worth doing: Terminal.app's dictionary exposes no working directory at
    /// all, and Warp is not scriptable. Adding a terminal that *is* means a
    /// case here and nothing else.
    public enum Family: String, CaseIterable, Sendable {
        case iTerm2 = "com.googlecode.iterm2"

        public static func forBundleID(_ bundleID: String) -> Family? {
            Family(rawValue: bundleID)
        }

        /// The bundle identifier of the app the Automation grant is *for*.
        /// Same string as the raw value today; named separately because it is
        /// the target of a TCC grant, which is a different fact about the case
        /// than "this is how we recognise the frontmost app".
        public var targetBundleID: String { rawValue }

        /// `variable named "path"` rather than any of the older properties:
        /// iTerm2 tracks the working directory of a local session itself, so
        /// this answers whether or not the owner has installed iTerm2's shell
        /// integration. `with timeout of 2 seconds` bounds the send the same
        /// way `AXUIElementSetMessagingTimeout` bounds the Accessibility
        /// round-trip next door — a wedged terminal must not hold the daemon's
        /// main run loop open indefinitely.
        ///
        /// `if application id … is running` first, because `tell application`
        /// *launches* an app that is not running: a read racing the terminal's
        /// quit would otherwise relaunch it and hold the main actor through
        /// the launch. The check itself sends no Apple Event.
        public var script: String {
            switch self {
            case .iTerm2:
                """
                if application id "com.googlecode.iterm2" is running then
                    with timeout of 2 seconds
                        tell application id "com.googlecode.iterm2"
                            tell current session of current window to get variable named "path"
                        end tell
                    end timeout
                end if
                """
            }
        }
    }

    /// What is known about this process's Automation grant for one terminal.
    /// `asking` exists so that a consent dialog the owner has not dismissed
    /// yet does not cause a second one to be raised behind it.
    enum Consent: Equatable { case unknown, asking, granted, denied }

    private var consent: [Family: Consent] = [:]
    private let probe: any AutomationProbing
    private let runner: any TerminalScriptRunning

    /// The in-flight consent ask, kept only so a test can wait for it. The
    /// reader itself never joins it: the whole point of the hop is that the
    /// focus event does not wait behind a dialog.
    private(set) var consentTask: Task<Void, Never>?

    public init(probe: any AutomationProbing = SystemAutomationProbe(),
                runner: any TerminalScriptRunning = AppleScriptRunner()) {
        self.probe = probe
        self.runner = runner
    }

    /// The working directory the frontmost window of `bundleID` is showing, or
    /// `nil` — because this app is not a terminal this reader knows, because
    /// Automation has not been granted for it, or because the terminal has no
    /// window open to have a directory.
    public func workingDirectory(forBundleID bundleID: String) -> String? {
        guard let family = Family.forBundleID(bundleID) else { return nil }
        switch consent[family] ?? .unknown {
        case .granted:
            return run(family)
        case .denied, .asking:
            return nil
        case .unknown:
            askForConsent(family)
            return nil
        }
    }

    /// Raises the Automation consent dialog for `family`, off the main thread.
    ///
    /// Off-thread is not a preference. With `promptIfNeeded: true`
    /// `AEDeterminePermissionToAutomateTarget` blocks until the dialog is
    /// dismissed, so asking from the main actor would freeze the run loop
    /// behind a dialog the owner may not answer for minutes. The read that
    /// triggered this returns nothing; the next focus on the same terminal
    /// finds the answer recorded and uses it.
    private func askForConsent(_ family: Family) {
        consent[family] = .asking
        let probe = self.probe
        let target = family.targetBundleID
        consentTask = Task.detached(priority: .utility) {
            let status = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    continuation.resume(
                        returning: probe.permissionStatus(forBundleID: target, promptIfNeeded: true))
                }
            }
            await MainActor.run { [weak self] in
                self?.consent[family] = Self.consent(for: status)
            }
        }
    }

    /// Maps the probe's `OSStatus` onto what this reader should do next.
    ///
    /// Deliberately narrower than AgenticToolkit's own mapping, which reports
    /// anything that is not an outright denial as undetermined so a settings
    /// row does not mislabel a granted permission whose target is merely not
    /// running. Here the target *is* running — it is the frontmost app — so
    /// the only two useful answers are "ask it" and "stop asking".
    static func consent(for status: OSStatus) -> Consent {
        status == noErr ? .granted : .denied
    }

    /// Asks `family` where it is working, and treats an empty answer as no
    /// answer: iTerm2 reports an empty string for a session whose directory it
    /// has not resolved, and an empty path is not a place.
    private func run(_ family: Family) -> String? {
        guard let value = runner.run(family.script), !value.isEmpty else { return nil }
        return value
    }
}

/// Runs one AppleScript and answers its result. A seam, so the consent
/// handling above can be tested without a terminal — and without a test
/// process quietly acquiring an Automation grant of its own.
@MainActor
public protocol TerminalScriptRunning {
    /// The script's string result, or `nil` if it produced none. A script that
    /// errors returns `nil` too: the caller has no use for the reason.
    func run(_ source: String) -> String?
}

/// Production `TerminalScriptRunning`, backed by `NSAppleScript`.
///
/// Compiled scripts are kept because compiling is the expensive half and the
/// sources are a fixed, tiny set — one per terminal this knows. `@MainActor`
/// because `NSAppleScript` is neither `Sendable` nor safe to drive from two
/// threads, and the focus pipeline that calls it is on the main actor anyway.
@MainActor
public final class AppleScriptRunner: TerminalScriptRunning {
    private var compiled: [String: NSAppleScript] = [:]

    public init() {}

    public func run(_ source: String) -> String? {
        guard let script = compiled[source] ?? NSAppleScript(source: source) else { return nil }
        compiled[source] = script
        // The error dictionary is deliberately discarded. A terminal with no
        // window open has no current session to ask and errors every time;
        // that is an ordinary state, not a fault, and a focus event is still
        // worth recording without a directory on it.
        var error: NSDictionary?
        return script.executeAndReturnError(&error).stringValue
    }
}
#endif
