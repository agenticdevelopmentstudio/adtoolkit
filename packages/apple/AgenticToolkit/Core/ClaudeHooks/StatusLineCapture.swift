import Foundation

/// The capture half of a status-line command: what runs on every Claude Code
/// status-line render, around whatever the caller renders.
///
/// Claude Code pipes the status-line payload (the only carrier of
/// `rate_limits`) to the registered command on every render. Per render:
///   1. FEED: post the payload to the daemon, with a `GitContextFingerprint` of
///      the session's git state added on the way out. When the daemon is
///      unreachable the feed drops an envelope for it to scan in later.
///   2. RENDER: the caller's `render` closure prints the line. A tap-only
///      configuration renders nothing and passes `captureOnly`.
///
/// The feed is handed to a detached `<helper> statusline --capture-only` and the
/// render returns as soon as its line is printed. The claudehelpers dispatcher
/// kills a renderer still running after 3 seconds, and a feed can take up to 17
/// (three `git` watchdogs and the post): waiting for it threw the line away and
/// killed the post with it. Detached, the feed is out of the dispatcher's reach
/// and bounded by its own deadline instead.
///
/// The toolkit core links no daemon client, so the transport is injected:
/// `post` sends one hook event and says whether the daemon accepted it.
public enum StatusLineCapture {

    /// `--capture-only`: run the FEED half only. Nothing is printed and the exit
    /// status is 0 whatever the feed does: the status-line display is switched
    /// off, but Claude Code is still the only carrier of `rate_limits`, and a
    /// status line must never break Claude Code.
    public static let captureOnlyFlag = "--capture-only"

    /// Set by the claudehelpers dispatcher (and by this command on the feed it
    /// detaches): the pid that ran the status line. A tap or detached feed has
    /// been reparented to launchd, so its own parent leads nowhere.
    public static let parentPIDVariable = "CLAUDEHELPERS_STATUSLINE_PARENT_PID"

    /// The longest a feed may run. Each step has its own timeout (5s per `git`,
    /// 2s for the post); this bounds the whole, so feeds cannot pile up.
    public static let feedDeadline: TimeInterval = 20

    /// Runs one status-line invocation and returns the process exit status.
    ///
    /// - `payload`: the status-line JSON Claude Code piped in.
    /// - `environment`: this process's environment.
    /// - `post`: sends `(event, payload)` to the daemon; true on acceptance. On
    ///   false the feed writes a drop file into the configuration's drop
    ///   directory instead.
    /// - `accountName` / `oauthEmail`: the account lookups the drop-file
    ///   envelope carries (see `HookCaptureCommand.buildEnvelope`).
    /// - `render`: prints the status line for `(payload, recoveredToken)` and
    ///   returns its exit status. Not called with `captureOnly`.
    public static func run(
        captureOnly: Bool,
        payload: Data,
        environment: [String: String],
        configuration: ClaudeHookConfiguration,
        post: @escaping @Sendable (_ event: String, _ payload: Data) -> Bool,
        accountName: @escaping @Sendable (String?) -> String,
        oauthEmail: @escaping @Sendable () -> String = { "" },
        render: (_ payload: Data, _ token: String?) -> Int32
    ) -> Int32 {
        // A child (external pipeline script) can exit before draining stdin;
        // ignore SIGPIPE so the ensuing write surfaces as a swallowable error
        // instead of killing this process before the status line renders.
        signal(SIGPIPE, SIG_IGN)
        let parent = parentPID(environment: environment)
        // Claude Code scrubs CLAUDE_CODE_OAUTH_TOKEN from the env it hands this
        // command; recover it once from the `claude` process above `parent` so
        // the renderer's current-account resolution works. A detached feed
        // carries the token its renderer recovered, for when `claude` is gone.
        let carried = captureOnly ? environment["CLAUDE_CODE_OAUTH_TOKEN"] : nil
        let recoveredToken = ProcessEnv.oauthTokenWalkingUp(from: parent) ?? carried.flatMap { $0.isEmpty ? nil : $0 }
        if captureOnly {
            feedOnce(payload: payload, token: recoveredToken, environment: environment,
                     configuration: configuration, post: post,
                     accountName: accountName, oauthEmail: oauthEmail)
            return 0
        }
        let status = render(payload, recoveredToken)
        fflush(stdout)
        if !detachFeed(payload: payload, token: recoveredToken, parent: parent,
                       environment: environment, configuration: configuration) {
            feedOnce(payload: payload, token: recoveredToken, environment: environment,
                     configuration: configuration, post: post,
                     accountName: accountName, oauthEmail: oauthEmail)
        }
        return status
    }

    /// The pid to walk up from for the token: the dispatcher's
    /// `parentPIDVariable` when it is a live-looking pid, else our own parent.
    public static func parentPID(environment: [String: String]) -> Int32 {
        if let value = environment[parentPIDVariable].flatMap(Int32.init), value > 1 {
            return value
        }
        return getppid()
    }

    /// Returns `base` with `CLAUDE_CODE_OAUTH_TOKEN` set to `token` when non-nil.
    public static func injected(_ base: [String: String], token: String?) -> [String: String] {
        guard let token else { return base }
        var env = base
        env["CLAUDE_CODE_OAUTH_TOKEN"] = token
        return env
    }

    /// Starts `<helper> statusline --capture-only` detached, with the payload on
    /// its stdin and the token and parent pid in its environment. False when
    /// this process is not the configuration's helper (the in-process tests) or
    /// nothing started, and the caller feeds in-process instead.
    static func detachFeed(
        payload: Data, token: String?, parent: Int32, environment: [String: String],
        configuration: ClaudeHookConfiguration,
        executable: String? = Bundle.main.executablePath
    ) -> Bool {
        let helperName = URL(fileURLWithPath: configuration.hookBinaryPath).lastPathComponent
        guard let executable,
              (executable as NSString).lastPathComponent == helperName else { return false }
        var childEnvironment = injected(environment, token: token)
        childEnvironment[parentPIDVariable] = String(parent)
        return DetachedProcess.spawn(
            executable: executable,
            arguments: configuration.statusLineArguments + [captureOnlyFlag],
            environment: childEnvironment, stdin: payload)
    }

    // MARK: - FEED

    /// One feed per session at a time, within `feedDeadline`. A feed that finds
    /// its session's previous one still running skips: the next render brings a
    /// newer snapshot anyway.
    static func feedOnce(
        payload: Data, token: String?, environment: [String: String],
        configuration: ClaudeHookConfiguration,
        post: @escaping @Sendable (String, Data) -> Bool,
        accountName: @escaping @Sendable (String?) -> String,
        oauthEmail: @escaping @Sendable () -> String
    ) {
        let object = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any]
        var lock: FeedLock?
        if let session = object?["session_id"] as? String {
            guard let acquired = FeedLock.acquire(sessionID: session, name: configuration.name) else { return }
            lock = acquired
        }
        defer { lock?.release() }
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            feed(payload: payload, token: token, environment: environment, configuration: configuration,
                 post: post, accountName: accountName, oauthEmail: oauthEmail)
            done.signal()
        }
        _ = done.wait(timeout: .now() + feedDeadline)
    }

    /// Posts the payload as a `StatusLine` event (the daemon recovers the
    /// session's env, token and terminal, from the payload's `cwd`, exactly as it
    /// does for a hook's drop file). Runs on its own thread alongside the render,
    /// so a slow or failed feed costs the status line nothing but the tail of its
    /// own duration. When the daemon is unreachable, drops an envelope for it to
    /// scan in later.
    static func feed(
        payload: Data, token: String?, environment: [String: String],
        configuration: ClaudeHookConfiguration,
        post: (String, Data) -> Bool,
        accountName: (String?) -> String,
        oauthEmail: () -> String
    ) {
        // Fingerprint the session's git state *here*, before the payload leaves
        // this process: the sample has to be taken in the session's working
        // directory at render time, and on the drop-file path ingest can be
        // minutes later. See `GitContextFingerprint`.
        let fed = GitContextFingerprint.enriched(payload: payload)
        if post("StatusLine", fed) { return }
        if let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "StatusLine", ppidString: nil, stdin: fed,
            env: injected(environment, token: token),
            accountName: accountName, oauthEmail: oauthEmail
        ) {
            try? HookDropWriter.writeDropFile(
                envelope: envelope,
                directory: HookDropWriter.dropDirectory(configuration: configuration, environment: environment))
        }
    }
}
