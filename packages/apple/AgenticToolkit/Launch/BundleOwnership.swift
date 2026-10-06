import Foundation
import AgenticToolkitCore

/// A pkg install leaves the bundle owned by root; an in-app updater (Sparkle)
/// then needs a password for every update. Hand it to the console user once.
///
/// Security: the job runs as root. `assess()` only filters out the obvious
/// (a non-`.app`, a translocated copy, a symlinked path, a user-owned parent);
/// the parent check does NOT exclude an admin-writable one such as
/// `/Applications` (root:admin 775). The real guard is the root command's own
/// filters; see `BundleOwnershipJob`.
public struct BundleOwnershipAssessment: PreparationJob {
    /// Owner of the item at `url` by lstat (a symlink reports itself), or nil.
    public static let lstatOwner: @Sendable (URL) -> uid_t? = { url in
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.ownerAccountID] as? NSNumber)?.uint32Value
    }

    public let bundleURL: URL
    public let appName: String
    public var ownerUID: @Sendable (URL) -> uid_t?
    public var parentOwnerUID: @Sendable (URL) -> uid_t?
    public var consoleUID: uid_t
    public var commands: any CommandRunning

    public init(bundleURL: URL, appName: String,
                ownerUID: @escaping @Sendable (URL) -> uid_t? = Self.lstatOwner,
                parentOwnerUID: @escaping @Sendable (URL) -> uid_t? = Self.lstatOwner,
                consoleUID: uid_t = getuid(),
                commands: any CommandRunning = ProcessCommandRunner()) {
        self.bundleURL = bundleURL
        self.appName = appName
        self.ownerUID = ownerUID
        self.parentOwnerUID = parentOwnerUID
        self.consoleUID = consoleUID
        self.commands = commands
    }

    public func assess() async -> [any StartupJob] {
        guard bundleURL.path.hasPrefix("/"), bundleURL.pathExtension == "app",
              !BundleLocation.isTranslocated(bundleURL),
              bundleURL.resolvingSymlinksInPath().path == bundleURL.standardizedFileURL.path,
              parentOwnerUID(bundleURL.deletingLastPathComponent()) == 0,
              ownerUID(bundleURL) == 0, consoleUID != 0 else { return [] }
        return [BundleOwnershipJob(bundleURL: bundleURL, appName: appName, consoleUID: consoleUID,
                                   ownerUID: ownerUID, commands: commands)]
    }
}

public struct BundleOwnershipJob: StartupJob {
    public let id = "bundle-ownership"
    public let title: String
    public let needsAdministrator = true
    public let bundleURL: URL
    public let consoleUID: uid_t
    public var ownerUID: @Sendable (URL) -> uid_t?
    /// Runs the unprivileged leftovers check after the privileged pass.
    public var commands: any CommandRunning

    public init(bundleURL: URL, appName: String, consoleUID: uid_t,
                ownerUID: @escaping @Sendable (URL) -> uid_t? = BundleOwnershipAssessment.lstatOwner,
                commands: any CommandRunning = ProcessCommandRunner()) {
        self.title = "Letting \(appName) update itself"
        self.bundleURL = bundleURL
        self.consoleUID = consoleUID
        self.ownerUID = ownerUID
        self.commands = commands
    }

    /// The invariant: every chown runs while the directory that holds the name
    /// is still owned by `$3` (root in production). A directory the user does
    /// not own cannot have its entries renamed, so the name `chown` acts on is
    /// the entry `find` checked, never a hard link to `/etc/sudoers` swapped in
    /// after the check. Handing a directory over first would open that swap
    /// for every name still queued inside it.
    ///
    /// So the order is bottom-up, root last:
    ///
    /// Step 1 chowns everything below the root, post-order (`-depth`): a
    /// directory only after every entry in it, so its own parent is still
    /// `$3`'s when it goes. `-mindepth 1` keeps the root out of this pass.
    /// `-execdir` runs `chown` inside the directory `find` actually entered,
    /// so no path component is resolved a second time. `-user` skips anything
    /// not owned by `$3`, `-h` never follows a symlink, and
    /// `( -type d -o -links 1 )` skips a hard link smuggled in from outside.
    public static func findStep(chown: String = "/usr/sbin/chown") -> String {
        #"/usr/bin/find "$1" -mindepth 1 -depth -xdev -user "$3" \( -type d -o -links 1 \) "#
            + #"-execdir \#(chown) -h "$2:staff" {} +"#
    }

    /// Step 2, last, chowns the bundle root through a file descriptor. Its
    /// parent (`/Applications`, root:admin 775) is admin-writable, so the root
    /// is the one name that could be swapped; the handle covers it.
    /// `O_NOFOLLOW` rejects a symlink, `O_DIRECTORY` rejects a hard-linked
    /// file, and `chown` on the handle is an `fchown`, so a path swapped in
    /// after the open cannot redirect it. `find` cannot do this step:
    /// `-execdir` runs the root entry in find's starting directory with a
    /// bare name. An owner other than `$ARGV[2]` exits quietly (0), so a retry
    /// after a partial run still reaches this step. 20 is `staff`. Needs
    /// `/usr/bin/perl`, which macOS ships; if it goes missing the job fails
    /// loudly.
    public static let rootChownPerl = #"use Fcntl; sysopen(my $f, $ARGV[0], O_RDONLY|O_DIRECTORY|O_NOFOLLOW) "#
        + #"or die "$!\n"; (stat $f)[4] == $ARGV[2] or exit 0; chown($ARGV[1], 20, $f) or die "$!\n""#

    /// Both steps in one privileged call (one password prompt). `$1` is the
    /// bundle, `$2` the new owner, `$3` the owner to take over from. Paths and
    /// ids travel as arguments, never interpolated into the script. `chown`
    /// is a seam for the real-tool test only.
    public static var privilegedScript: String { privilegedScript() }

    public static func privilegedScript(chown: String = "/usr/sbin/chown") -> String {
        "\(findStep(chown: chown)) && /usr/bin/perl -e '\(rootChownPerl)' \"$1\" \"$2\" \"$3\""
    }

    /// The password prompt can sit open for minutes, so the check below is only
    /// an early exit; it cannot protect the window after the prompt. The root
    /// script is the guard (see the two steps above).
    @MainActor public func run(context: StartupJobContext) async throws {
        guard ownerUID(bundleURL) == 0 else { return }
        try await context.privileged.run([
            "/bin/sh", "-c", Self.privilegedScript, "sh", bundleURL.path, "\(consoleUID)", "0"
        ])
        let skipped = await leftovers()
        if skipped > 0 {
            context.progress("\(skipped) hard-linked file(s) in the app are still owned by root; "
                             + "updates may ask for a password.")
        }
    }

    /// Root-owned multi-link files left after the run: the ones the root
    /// command deliberately skips. Counted from `find`'s output lines.
    private func leftovers() async -> Int {
        let result = await commands.capture(["/usr/bin/find", bundleURL.path, "-xdev", "-user", "0",
                                             "-type", "f", "-links", "+1"], environment: nil)
        guard result.status == 0 else { return 0 }
        return result.stdout.split(whereSeparator: \.isNewline).count
    }
}
