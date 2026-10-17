import Foundation

/// Builds a `ParsedEvent` from the data a hook forwards to a daemon: over its
/// Unix socket (a hook script's `event`, `ppid`, `env` and `payload`) or over an
/// `http` hook, which carries only the payload.
///
/// It produces the same context shape as `HookCaptureCommand`'s drop-file
/// envelope, so events ingested over the socket and via drop files are
/// queryable identically.
///
/// System fields (`hostname`, `os`, `arch`, `uid`, `euid`, `gid`) are computed
/// in the calling process. A daemon runs as the same user as the hook-firing
/// process, so these match.
///
/// Account lookups are injected: the toolkit core has no account store.
/// `accountName` maps an OAuth token to the account that owns it ("" when
/// unknown) and `oauthEmail` reads the machine login's account. Both default to
/// the "no answer" value, "".
public enum HookEnvelopeBuilder {

    /// The calling process's own working directory (canonical), computed once.
    /// A daemon changes into its support directory early in start-up, before this
    /// is first read; the headless `claude` it spawns inherits that directory and
    /// never sets its own, so a hook payload reporting it is the daemon's internal
    /// claude, never an interactive user session.
    public static let daemonWorkingDirectory: String =
        ProcessLiveness.canonicalPath(FileManager.default.currentDirectoryPath)

    /// Builds a `ParsedEvent` from an `http` hook, which carries **only** the
    /// payload JSON: no `$PPID`, no `env` dump a hook script forwarded over the
    /// socket. Both are recovered from the payload's `cwd`: it locates the live
    /// `claude` process (`ProcessLiveness.claudePid(inCwd:)`), whose env
    /// (`ProcessEnv.environment(forPid:)`) carries the scrubbed OAuth token, the
    /// terminal vars and the `AGENTIC_TOOLKIT_HEADLESS` marker. The recovered
    /// `claude` pid also stands in for `ppid` (it is Claude's PID). Degrades to an
    /// empty env when the process can't be located (token and terminal are simply
    /// absent for that event; a sessions upsert that coalesces never clobbers an
    /// earlier good value).
    ///
    /// The default resolvers go through `HookEnvCache` (a short-TTL memo) so the
    /// highest-frequency event, a status-line post on every render, doesn't drive
    /// a full process-table scan each time. Tests inject their own resolvers and
    /// bypass the cache.
    public static func build(
        event: String,
        payload: Data,
        claudePid: (String) -> Int32? = { HookEnvCache.pid(inCwd: $0) },
        environment: (Int32) -> [String: String]? = { HookEnvCache.env(forPid: $0) },
        daemonCwd: String = daemonWorkingDirectory,
        accountName: (String?) -> String = { _ in "" },
        oauthEmail: () -> String = { "" }
    ) -> ParsedEvent? {
        guard !event.isEmpty else { return nil }
        let json = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any]
        let cwd = json?["cwd"] as? String
        // Drop the daemon's own headless `claude -p` BEFORE trying to read its env.
        // It inherits the daemon's working directory and never sets its own, so a
        // payload reporting that directory is internal work, not a user session.
        // This cwd match is timing-independent; the `AGENTIC_TOOLKIT_HEADLESS` env
        // marker (checked in the inner build) is only recoverable while that
        // short-lived process is still alive, so relying on it alone races the
        // summarizer's exit and lets a phantom session slip in.
        if let cwd, !daemonCwd.isEmpty, daemonCwd != "/",
           ProcessLiveness.canonicalPath(cwd) == daemonCwd {
            return nil
        }
        let pid = cwd.flatMap(claudePid)
        let env = pid.flatMap(environment) ?? [:]
        return build(event: event, ppid: Int(pid ?? 0), env: env,
                     payload: payload, parsedPayload: json,
                     accountName: accountName, oauthEmail: oauthEmail)
    }

    /// Builds a `ParsedEvent` ready for ingestion. Returns `nil` when the payload
    /// is missing required fields (currently: a `session_id`).
    public static func build(
        event: String,
        ppid: Int,
        env: [String: String],
        payload: Data,
        parsedPayload: [String: Any]? = nil,
        accountName: (String?) -> String = { _ in "" },
        oauthEmail: () -> String = { "" }
    ) -> ParsedEvent? {
        guard !event.isEmpty else { return nil }

        // Drop events from a programmatic/headless `claude` the daemon spawned
        // itself (e.g. AI session summaries): those fire hooks too, but they're
        // internal work, not a user session. The http path also drops these by
        // cwd before env recovery (see the payload-only build above), which
        // covers the case where the summarizer has already exited and its env can
        // no longer be read.
        guard env["AGENTIC_TOOLKIT_HEADLESS"] == nil else { return nil }

        // Reuse the caller's already-parsed payload when provided (the http path
        // parses once to read `cwd`); only deserialize here for the socket
        // callers that hand over raw bytes.
        var hookData: [String: Any] = parsedPayload ?? {
            guard !payload.isEmpty,
                  let parsed = try? JSONSerialization.jsonObject(with: payload) as? [String: Any]
            else { return [:] }
            return parsed
        }()

        // v4 wire-compat: term_program lifted onto hook_data; SessionStart gets
        // `pid` (= Claude's PID, from $PPID) so a liveness check can detect dead
        // sessions.
        hookData["term_program"] = env["TERM_PROGRAM"] ?? ""
        // The terminal's session identifier (iTerm/Terminal set TERM_SESSION_ID,
        // e.g. "w0t1p0:UUID"). Lets an app jump to the exact tab/pane on click.
        hookData["term_session_id"] = env["TERM_SESSION_ID"] ?? ""
        if event == "SessionStart" {
            hookData["pid"] = ppid
        }

        guard let sessionId = hookData["session_id"] as? String, !sessionId.isEmpty else {
            return nil
        }
        _ = sessionId

        let context = buildContext(event: event, ppid: ppid, env: env)
        let timestamp = iso8601UTC()
        // Claude Code scrubs CLAUDE_CODE_OAUTH_TOKEN from the env it hands hook
        // commands; fall back to recovering it from the parent `claude` process
        // (whose pid the hook forwards as `ppid`) when the forwarded env lacks it.
        let token = nonEmpty(env["CLAUDE_CODE_OAUTH_TOKEN"]) ?? ProcessEnv.oauthTokenWalkingUp(from: Int32(ppid))
        let accountEmail = accountName(token)
        // Resolved HERE, while the hook is firing, not at ingest. The event may
        // wait in a spool for the length of a migration, or in the drop directory
        // across a reboot, and a sessions upsert that is first-oauth-wins would
        // attribute a backlog, permanently, to whoever is logged in at the drain.
        let oauthAccountEmail = oauthEmail()

        return ParsedEvent(
            eventType: event,
            timestamp: timestamp,
            hookData: hookData,
            context: context,
            accountEmail: accountEmail,
            oauthAccountEmail: oauthAccountEmail
        )
    }

    // MARK: - Context

    /// The same curated shape as `HookCaptureCommand`'s envelope context:
    /// claude.*/process.*/system.*/shell.*/session.*/terminal. Fields whose env
    /// vars are unset are omitted.
    public static func buildContext(
        event: String,
        ppid: Int,
        env: [String: String]
    ) -> [String: Any] {
        var ctx: [String: Any] = [:]

        // claude.*
        var claude: [String: Any] = [:]
        if let value = nonEmpty(env["CLAUDECODE"]) { claude["running"] = RawSetting.bool(value, default: false) }
        if let value = nonEmpty(env["CLAUDE_CODE_ENTRYPOINT"]) { claude["entrypoint"] = value }
        if let value = nonEmpty(env["CLAUDE_CODE_EXECPATH"]) { claude["exec_path"] = value }
        if let value = nonEmpty(env["CLAUDE_PROJECT_DIR"]) { claude["project_dir"] = value }
        if let value = nonEmpty(env["CLAUDE_YOLO"]) { claude["yolo"] = RawSetting.bool(value, default: false) }
        if !claude.isEmpty { ctx["claude"] = claude }

        // process.*
        // The hook-firing process exited by the time we ingest, so its PID isn't
        // useful. We record `ppid` (Claude's PID) and the identity fields the
        // daemon shares with the hook process (same user). We deliberately omit
        // `argv`: a hook script's argv is just its name and the event, and the
        // event is already top-level.
        var process: [String: Any] = [:]
        process["ppid"] = ppid
        process["uid"] = Int(getuid())
        process["euid"] = Int(geteuid())
        process["gid"] = Int(getgid())
        ctx["process"] = process

        // system.*
        ctx["system"] = HookCaptureCommand.systemInfo()

        // shell.*
        var shell: [String: Any] = [:]
        if let value = nonEmpty(env["SHELL"]) { shell["shell"] = value }
        if let value = nonEmpty(env["SHLVL"]), let num = Int(value) { shell["shlvl"] = num }
        if let value = nonEmpty(env["LANG"]) { shell["lang"] = value }
        if let value = nonEmpty(env["PATH"]) { shell["path"] = value }
        if !shell.isEmpty { ctx["shell"] = shell }

        // session.*
        var session: [String: Any] = [:]
        if let value = nonEmpty(env["USER"]) { session["user"] = value }
        if let value = nonEmpty(env["HOME"]) { session["home"] = value }
        if let value = nonEmpty(env["LOGNAME"]) { session["logname"] = value }
        if let value = nonEmpty(env["TMPDIR"]) { session["tmpdir"] = value }
        if let value = nonEmpty(env["PWD"]) { session["pwd"] = value }
        if !session.isEmpty { ctx["session"] = session }

        // terminal.*
        var terminal: [String: Any] = [:]
        if let value = nonEmpty(env["TERM"]) { terminal["term"] = value }
        if let value = nonEmpty(env["TERM_PROGRAM"]) { terminal["term_program"] = value }
        if let value = nonEmpty(env["TERM_PROGRAM_VERSION"]) { terminal["term_version"] = value }
        if let value = nonEmpty(env["TERM_SESSION_ID"]) { terminal["term_session_id"] = value }
        if let value = nonEmpty(env["LC_TERMINAL"]) { terminal["lc_terminal"] = value }
        if !terminal.isEmpty { ctx["terminal"] = terminal }

        return ctx
    }

    // MARK: - Wire parsing

    /// Parses the wire format a hook script sends over a daemon's socket: the
    /// event, the ppid and `KEY=value` env lines, a `---` line, then the payload
    /// bytes. Returns nil on malformed input.
    public static func parseWire(_ data: Data) -> (event: String, ppid: Int, env: [String: String], payload: Data)? {
        // Find the "\n---\n" separator between header and payload.
        guard let separatorRange = data.range(of: Data("\n---\n".utf8)) else {
            return nil
        }
        let headerData = data.subdata(in: 0..<separatorRange.lowerBound)
        let payloadData = data.subdata(in: separatorRange.upperBound..<data.count)

        guard let headerString = String(data: headerData, encoding: .utf8) else { return nil }
        let lines = headerString.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count >= 2 else { return nil }

        let event = lines[0]
        let ppid = Int(lines[1]) ?? 0
        var env: [String: String] = [:]
        for line in lines.dropFirst(2) where !line.isEmpty {
            guard let eqIdx = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<eqIdx])
            let value = String(line[line.index(after: eqIdx)...])
            env[key] = value
        }

        return (event, ppid, env, payloadData)
    }

    // MARK: - Helpers

    private static func nonEmpty(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return text
    }

    private static func iso8601UTC() -> String {
        HookCaptureCommand.iso8601UTC()
    }
}

/// Short-TTL memoization for the http-hook env recovery.
///
/// `HookEnvelopeBuilder.build(event:payload:)` recovers a session's env by
/// locating the live `claude` for the payload's `cwd` (a full `KERN_PROCARGS2`
/// scan of the user's process table) and reading that pid's env. A status-line
/// post arrives on *every* render, many times per second per session, so without
/// a cache each render re-scans the whole process table. A ~3s TTL collapses a
/// burst of same-cwd renders to a single scan while a mid-window account switch
/// still self-heals within one window.
///
/// A daemon may service hook posts concurrently, so both maps are lock-guarded.
public enum HookEnvCache {
    private static let ttl: TimeInterval = 3
    private static let lock = NSLock()
    // Guarded by `lock` on every access, so the mutation is safe despite the
    // `nonisolated(unsafe)` opt-out of Swift 6's shared-mutable-state checking.
    nonisolated(unsafe) private static var pidByCwd: [String: (expires: Date, pid: Int32?)] = [:]
    nonisolated(unsafe) private static var envByPid: [Int32: (expires: Date, env: [String: String])] = [:]

    /// The `claude` pid for `cwd`, memoized by canonical cwd. Delegates the miss
    /// to `ProcessLiveness.claudePid(inCwd:)` (which refuses to guess when more
    /// than one claude shares the directory, returning nil).
    public static func pid(inCwd cwd: String) -> Int32? {
        let key = ProcessLiveness.canonicalPath(cwd)
        let now = Date()
        lock.lock()
        if let hit = pidByCwd[key], hit.expires > now {
            lock.unlock()
            return hit.pid
        }
        lock.unlock()
        let resolved = ProcessLiveness.claudePid(inCwd: cwd)
        lock.lock()
        pidByCwd[key] = (now.addingTimeInterval(ttl), resolved)
        if pidByCwd.count > 128 { pidByCwd = pidByCwd.filter { $0.value.expires > now } }
        lock.unlock()
        return resolved
    }

    /// `pid`'s env, memoized by pid. A miss reads it via `ProcessEnv`; the empty
    /// dict is cached too so a transient read failure doesn't re-scan every
    /// render.
    public static func env(forPid pid: Int32) -> [String: String] {
        let now = Date()
        lock.lock()
        if let hit = envByPid[pid], hit.expires > now {
            lock.unlock()
            return hit.env
        }
        lock.unlock()
        let resolved = ProcessEnv.environment(forPid: pid) ?? [:]
        lock.lock()
        envByPid[pid] = (now.addingTimeInterval(ttl), resolved)
        if envByPid.count > 128 { envByPid = envByPid.filter { $0.value.expires > now } }
        lock.unlock()
        return resolved
    }
}
