import Foundation

/// Everything that makes one session daemon's runtime its own: names, paths,
/// intervals and the Claude Code hook registration it installs.
///
/// A daemon builds one of these and hands it to the session runtime; nothing
/// in the shared code spells a daemon's name or directory itself.
public struct SessionDaemonConfiguration: Sendable {

    /// Reverse-DNS label; the log subsystem and the launchd identity.
    public var label: String
    /// Log subsystem the runtime's queues and threads are labelled under.
    public var subsystem: String
    public var daemonVersion: String
    public var httpPort: UInt16
    /// Where the database and the ingest spool live.
    public var supportDirectory: URL
    public var databasePath: String
    public var spoolPath: String
    /// The Unix socket hook helpers deliver events to.
    public var socketPath: String
    /// The directory hook helpers drop envelopes into.
    public var dropDirectory: URL
    /// Where events the daemon could not ingest are quarantined.
    public var errorsDirectory: URL
    public var hook: ClaudeHookConfiguration
    public var retentionDays: Int
    public var livenessCheckInterval: TimeInterval
    public var retentionCheckInterval: TimeInterval
    /// The file the signed-in Claude account is read from; nil means `~/.claude.json`.
    public var claudeJSONPath: String?
    /// Folders scanned for `.aiplugin` bundles in addition to the default
    /// `~/.agenticplugins` and the bundle's `PlugIns`: where this daemon's host app
    /// installs AI plugins. Empty means only the defaults.
    public var pluginSearchPaths: [URL]
    /// Whether AI summaries are on until the user chooses otherwise. Every daemon
    /// states its own: one that must not double LLM spend over sessions another
    /// daemon already summarizes passes false. There is deliberately no default.
    public var summariesDefaultEnabled: Bool

    public init(
        label: String,
        subsystem: String? = nil,
        daemonVersion: String,
        httpPort: UInt16,
        supportDirectory: URL,
        databasePath: String? = nil,
        spoolPath: String? = nil,
        socketPath: String,
        dropDirectory: URL,
        errorsDirectory: URL? = nil,
        hook: ClaudeHookConfiguration,
        retentionDays: Int = 7,
        livenessCheckInterval: TimeInterval = 10,
        retentionCheckInterval: TimeInterval = 86400,
        claudeJSONPath: String? = nil,
        pluginSearchPaths: [URL] = [],
        summariesDefaultEnabled: Bool
    ) {
        self.label = label
        self.subsystem = subsystem ?? label
        self.daemonVersion = daemonVersion
        self.httpPort = httpPort
        self.supportDirectory = supportDirectory
        self.databasePath = databasePath ?? supportDirectory.appendingPathComponent("sessions.db").path
        self.spoolPath = spoolPath ?? supportDirectory.appendingPathComponent("ingest.db").path
        self.socketPath = socketPath
        self.dropDirectory = dropDirectory
        self.errorsDirectory = errorsDirectory ?? dropDirectory.appendingPathComponent("errors")
        self.hook = hook
        self.retentionDays = retentionDays
        self.livenessCheckInterval = livenessCheckInterval
        self.retentionCheckInterval = retentionCheckInterval
        self.claudeJSONPath = claudeJSONPath
        self.pluginSearchPaths = pluginSearchPaths
        self.summariesDefaultEnabled = summariesDefaultEnabled
    }

    /// A configuration rooted under `root` (a fresh temporary directory by
    /// default): every path and the hook's `settings.json` stay inside it, so
    /// a test never touches the real Claude Code settings. Port 0 lets the OS
    /// assign one.
    public static func test(port: UInt16 = 0, root: URL? = nil) -> SessionDaemonConfiguration {
        let base = root ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("session-daemon-test-\(UUID().uuidString)")
        let drop = base.appendingPathComponent("events")
        return SessionDaemonConfiguration(
            label: "test.session-daemon",
            daemonVersion: "0.0.0-test",
            httpPort: port,
            supportDirectory: base,
            socketPath: base.appendingPathComponent("capture.sock").path,
            dropDirectory: drop,
            hook: ClaudeHookConfiguration(
                name: "session-daemon-test",
                marker: "# session-daemon-test-hook",
                hookBinaryPath: base.appendingPathComponent("helper").path,
                dropDirectory: drop.path,
                settingsURL: base.appendingPathComponent("settings.json")
            ),
            livenessCheckInterval: 1,
            claudeJSONPath: base.appendingPathComponent("claude.json").path,
            summariesDefaultEnabled: false
        )
    }
}
