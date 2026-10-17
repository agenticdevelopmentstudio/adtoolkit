import Foundation
import AgenticToolkitCore

/// Brings a daemon's launchd job back up when its app launches and finds it
/// stopped.
///
/// An app that talks to its daemon assumes it is running. But a "Stop Daemon"
/// click does a `launchctl bootout`, which unregisters the job while leaving the
/// plist on disk. In that state a relaunched app just fails lookups forever,
/// with no way back short of a manual `launchctl bootstrap`. Detecting "plist
/// present but job unregistered" at launch and bootstrapping it lets the app
/// self-heal instead.
///
/// ## Deliberate stops
///
/// Self-heal must not fight the user: a daemon stopped ON PURPOSE has to stay
/// stopped, while one stopped by a crash, a stray `bootout`, or a mis-clicked
/// menu should come back. launchd cannot tell those apart — the *intent* only
/// exists at the moment of the click — so a stop is recorded as a marker file
/// (`stopMarkerURL`), and `ensureRunning()` declines to revive while that marker
/// is present. "Start" and "Restart" clear it, an install clears it (installing
/// means "this should be running"), and any observed-running daemon clears it as
/// stale — so the marker can never strand self-heal permanently.
public struct DaemonBootstrap: Sendable {
    /// launchd label + plist basename.
    public let label: String
    public let plistURL: URL
    /// Where the deliberate-stop marker lives.
    public let stopMarkerURL: URL
    public let commands: any CommandRunning

    public init(label: String, plistURL: URL, stopMarkerURL: URL, commands: any CommandRunning) {
        self.label = label
        self.plistURL = plistURL
        self.stopMarkerURL = stopMarkerURL
        self.commands = commands
    }

    // MARK: - The deliberate-stop marker

    /// Records that the user stopped the daemon on purpose.
    public func recordDeliberateStop() { Self.recordDeliberateStop(at: stopMarkerURL) }

    /// Forgets a recorded deliberate stop, re-arming self-heal.
    public func clearDeliberateStop() { Self.clearDeliberateStop(at: stopMarkerURL) }

    public var wasStoppedDeliberately: Bool { Self.wasStoppedDeliberately(at: stopMarkerURL) }

    /// Records that this stop was deliberate. Best effort: if the marker can't be
    /// written the only consequence is that self-heal revives the daemon later,
    /// which is exactly the pre-marker behavior. Stores a timestamp so the file is
    /// self-describing when someone finds it while debugging.
    public static func recordDeliberateStop(at url: URL) {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? markerFormatter.string(from: Date())
            .write(to: url, atomically: true, encoding: .utf8)
    }

    /// Fractional seconds so two stops can't write an identical stamp — the
    /// compare-and-swap in `ensureRunning` distinguishes markers by content.
    private static var markerFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    public static func clearDeliberateStop(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    public static func wasStoppedDeliberately(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// The marker's contents — the stop timestamp — or `nil` when there is no
    /// marker. Serves as the compare-and-swap token in ``ensureRunning(uid:isRegistered:)``:
    /// a stop recorded during the probe rewrites the file, so a changed (or newly
    /// appeared) stamp means "someone stopped the daemon since we looked; leave
    /// their marker alone." Raw bytes, so a marker that isn't UTF-8 still
    /// compares (and clears).
    public static func markerStamp(at url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    // MARK: - Registration and self-heal

    /// `true` when launchd already has the job registered in the user's GUI
    /// domain — `launchctl print gui/$UID/<label>` exits 0 only when it is.
    public func isRegistered(uid: uid_t = getuid()) async -> Bool {
        await commands.run([Launchctl.path, "print", Launchctl.guiTarget(label, uid: uid)]).status == 0
    }

    /// Runs ``ensureRunning(uid:isRegistered:)`` off the calling task and returns
    /// at once; the returned task finishes when the work has.
    ///
    /// This is what app launch should call: `launchctl print` walks the whole job
    /// description and can take seconds on a loaded machine, and nothing downstream
    /// needs the result synchronously. `commands` runs the subprocess off the
    /// cooperative pool, so awaiting it parks no pool thread.
    @discardableResult
    public func ensureRunningInBackground(uid: uid_t = getuid()) -> Task<Void, Never> {
        let bootstrap = self
        return Task.detached(priority: .userInitiated) {
            await bootstrap.ensureRunning(uid: uid)
        }
    }

    /// If the plist exists but the job isn't registered, bootstrap it — unless the
    /// user stopped it deliberately. Best effort: on failure the app is left in the
    /// same "daemon down" state it would have been in anyway, so errors are
    /// swallowed.
    ///
    /// A daemon we observe RUNNING proves any stop marker is stale (an install, a
    /// "Start", or a manual bootstrap brought it back), so we drop the marker then
    /// — that keeps a one-time deliberate stop from disabling self-heal forever.
    ///
    /// That clear is a compare-and-swap, not an unconditional delete, because the
    /// registration probe is slow: the user can click "Stop" while it is still in
    /// flight. Deleting whatever marker is on disk when the probe returns would
    /// erase that brand-new one and revive the daemon on the next launch — the
    /// precise behaviour the marker exists to prevent. So we only clear the marker
    /// we actually observed as stale.
    public func ensureRunning(uid: uid_t = getuid(),
                              isRegistered probe: (@Sendable (uid_t) async -> Bool)? = nil) async {
        guard FileManager.default.fileExists(atPath: plistURL.path) else { return }
        let markerBeforeProbe = Self.markerStamp(at: stopMarkerURL)
        let registered: Bool
        if let probe {
            registered = await probe(uid)
        } else {
            registered = await isRegistered(uid: uid)
        }
        if registered {
            if markerBeforeProbe != nil, Self.markerStamp(at: stopMarkerURL) == markerBeforeProbe {
                Self.clearDeliberateStop(at: stopMarkerURL)
            }
            return
        }
        guard !Self.wasStoppedDeliberately(at: stopMarkerURL) else { return }
        _ = await commands.run([Launchctl.path, "bootstrap", Launchctl.guiDomain(uid: uid), plistURL.path])
    }
}
