import Foundation

/// The one place the Kitchen daemon's launchd label, log subsystems, keychain
/// service, HTTP port and executable names are spelled, so the daemon, its CLI
/// and the app that hosts it never spell them twice. The daemon has no
/// history: there are no legacy names to read or migrate.
///
/// Every value differs from `StenographerIdentifiers`, so both daemons run on
/// one machine without sharing a label, a port, a hook marker or a directory.
public enum ADKDIdentifiers {
    public static let label = "com.agenticdevelopmentstudio.adkd"
    public static let subsystem = label
    public static func subsystem(_ suffix: String) -> String { "\(label).\(suffix)" }
    public static let keychainService = "\(label).daemon"
    /// The daemon's localhost HTTP port, and the base URL clients reach it at.
    public static let httpPort = 22849
    public static let httpBaseURL = "http://127.0.0.1:\(httpPort)"
    /// Marks a hook command as installed by this daemon.
    public static let hookMarker = "# adkd-hook"
    /// The name its hook and status-line entries carry in Claude Code's settings.
    public static let hookName = "adkd"
    /// The lock file serialising edits to Claude Code's hook settings.
    public static let ownHookLockName = ".adkd-hooks.lock"
    /// The command-line tool, at `Contents/Helpers/adk` in the app bundle.
    public static let cliName = "adk"
    /// The daemon executable, at `Contents/MacOS/adkd` in the app bundle.
    public static let daemonExecutableName = "adkd"
}

public struct ADKDPaths: Sendable {
    /// The app's storage token: its display name with non-alphanumerics dropped.
    /// Spelled here because Core cannot import the database layer that derives
    /// it; a test in the app's own target checks the two agree.
    public static let storageToken = "AgenticDeveloperKitchen"
    /// The app's display name, which names its folder under Application Support.
    public static let displayName = "Agentic Developer Kitchen"
    public static let databaseFileName = "adkd.db"
    public static let spoolFileName = "ingest.db"
    /// The files launchd opens for the daemon's stdout and stderr.
    public static let launchdStdoutLogName = "stdout.log"
    public static let launchdStderrLogName = "stderr.log"
    /// The marker whose presence means the user stopped the daemon on purpose.
    public static let stopMarkerName = "daemon-stopped-by-user"

    private let home: URL

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home
    }

    private var library: URL { home.appendingPathComponent("Library", isDirectory: true) }

    /// `~/.agenticdeveloperkitchen`, the app's storage root.
    public var storageDirectory: URL {
        home.appendingPathComponent(".\(Self.storageToken.lowercased())", isDirectory: true)
    }
    /// Where the daemon keeps its data, under the storage root.
    public var supportDirectory: URL { storageDirectory.appendingPathComponent("adkd", isDirectory: true) }
    public var databaseURL: URL { supportDirectory.appendingPathComponent(Self.databaseFileName) }
    public var spoolURL: URL { supportDirectory.appendingPathComponent(Self.spoolFileName) }
    public var errorsDirectory: URL { supportDirectory.appendingPathComponent("errors", isDirectory: true) }
    /// Where user-installed AI plugins live: the app's folder under Application Support.
    public var pluginDirectories: [URL] {
        [library.appendingPathComponent("Application Support/\(Self.displayName)/Plugins", isDirectory: true)]
    }

    public var claudeDirectory: URL { home.appendingPathComponent(".claude", isDirectory: true) }
    /// Where Claude Code's hooks drop events for the daemon to ingest.
    public var dropDirectory: URL { claudeDirectory.appendingPathComponent("adkd-events", isDirectory: true) }
    public var socketURL: URL { claudeDirectory.appendingPathComponent("adkd.sock") }

    public var logsDirectory: URL {
        library.appendingPathComponent("Logs/\(ADKDIdentifiers.label)", isDirectory: true)
    }
    public var launchAgentPlist: URL {
        library.appendingPathComponent("LaunchAgents/\(ADKDIdentifiers.label).plist")
    }
    /// Recorded in the support directory, beside the data the daemon owns.
    public var stopMarkerURL: URL { supportDirectory.appendingPathComponent(Self.stopMarkerName) }
}
