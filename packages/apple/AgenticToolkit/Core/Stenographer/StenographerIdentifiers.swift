import Foundation

/// The one place Stenographer's launchd label, Mach service, log subsystems,
/// keychain services and on-disk directories are spelled. The `legacy*` values
/// are the pre-1.0.173 names: read, matched and migrated —
/// never written.
public enum StenographerIdentifiers {
    public static let label = "com.agenticdevelopmentstudio.stenographer"
    public static let legacyLabel = "com.agentic-cookbook.stenographer"
    public static let legacyMenubarLabel = "com.agentic-cookbook.stenographer.menubar"
    public static let subsystem = label
    public static func subsystem(_ suffix: String) -> String { "\(label).\(suffix)" }
    public static let keychainService = label
    public static let daemonKeychainService = "\(label).daemon"
    public static let legacyDaemonKeychainService = "com.agentic-cookbook.stenographer.daemon"
    /// The daemon's localhost HTTP port, and the base URL clients reach it at.
    public static let httpPort = 22847
    public static let httpBaseURL = "http://127.0.0.1:\(httpPort)"
}

public struct StenographerPaths: Sendable {
    /// The file whose presence marks a support directory as holding real data.
    public static let databaseFileName = "stenographer.db"
    /// The files launchd opens for the daemon's stdout and stderr, named in the
    /// LaunchAgent plist the app writes and recognised by the daemon's migration.
    public static let launchdStdoutLogName = "stdout.log"
    public static let launchdStderrLogName = "stderr.log"

    private let home: URL
    private let exists: @Sendable (URL) -> Bool

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser,
                exists: @escaping @Sendable (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) {
        self.home = home
        self.exists = exists
    }

    private var library: URL { home.appendingPathComponent("Library", isDirectory: true) }

    public var currentSupportDirectory: URL {
        library.appendingPathComponent("Application Support/\(StenographerIdentifiers.label)", isDirectory: true)
    }
    public var legacySupportDirectory: URL {
        library.appendingPathComponent("Application Support/\(StenographerIdentifiers.legacyLabel)", isDirectory: true)
    }
    /// Where user-installed AI plugins live: the new directory, then the legacy
    /// one. Both, not the resolved ``supportDirectory``: the app discovers
    /// plugins once at launch, and the daemon may move the legacy directory
    /// after that — a single path resolved at launch would point at a folder
    /// that has since moved. A missing directory is skipped by discovery.
    public var pluginDirectories: [URL] {
        [currentSupportDirectory, legacySupportDirectory]
            .map { $0.appendingPathComponent("Plugins", isDirectory: true) }
    }

    /// The new directory once it holds the database; else the legacy one while
    /// it exists (the daemon has not migrated yet — an empty new directory must
    /// not hide the user's real data); else the new one.
    public var supportDirectory: URL {
        let current = currentSupportDirectory
        if exists(current.appendingPathComponent(Self.databaseFileName)) { return current }
        if exists(legacySupportDirectory) { return legacySupportDirectory }
        return current
    }

    /// Writes `name` into the support directory and follows the directory if it
    /// moves underneath the write: the daemon migrates the legacy directory to
    /// the current one, so a file written into the legacy one just before the
    /// move can land where the next read never looks. After each write the
    /// directory is resolved again; if it changed, the write repeats there
    /// (at most `attempts` times). Returns where the file was last written.
    @discardableResult
    public func writeSupportFile(named name: String, attempts: Int = 3,
                                 _ write: (URL) throws -> Void) rethrows -> URL {
        var url = supportDirectory.appendingPathComponent(name)
        for _ in 0..<max(attempts, 1) {
            try write(url)
            let resolved = supportDirectory.appendingPathComponent(name)
            if resolved == url { break }
            url = resolved
        }
        return url
    }

    public var currentLogsDirectory: URL {
        library.appendingPathComponent("Logs/\(StenographerIdentifiers.label)", isDirectory: true)
    }
    public var legacyLogsDirectory: URL {
        library.appendingPathComponent("Logs/\(StenographerIdentifiers.legacyLabel)", isDirectory: true)
    }
    public var logsDirectory: URL {
        if exists(currentLogsDirectory) { return currentLogsDirectory }
        if exists(legacyLogsDirectory) { return legacyLogsDirectory }
        return currentLogsDirectory
    }

    public var launchAgentPlist: URL { agent(StenographerIdentifiers.label) }
    public var legacyLaunchAgentPlist: URL { agent(StenographerIdentifiers.legacyLabel) }
    public var legacyMenubarLaunchAgentPlist: URL { agent(StenographerIdentifiers.legacyMenubarLabel) }

    private func agent(_ label: String) -> URL {
        library.appendingPathComponent("LaunchAgents/\(label).plist")
    }
}
