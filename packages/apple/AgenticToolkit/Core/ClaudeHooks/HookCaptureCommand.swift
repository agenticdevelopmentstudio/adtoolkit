import Foundation

/// What a hook helper runs when Claude Code fires a hook
/// (`<helper> hook --event <Type> [--ppid <int>]`): read the hook payload from
/// stdin, add a process-context snapshot, and write a drop file the daemon picks
/// up. Everything configuration-specific (the drop directory and its override
/// variable) comes from the `ClaudeHookConfiguration`.
///
/// The hook contract is: never fail, never produce stdout. `run` therefore
/// always returns 0 whatever goes wrong (a parse error, a file-system error),
/// so a broken hook never blocks Claude Code.
public enum HookCaptureCommand {

    /// Runs the hook capture for one invocation and returns the process exit
    /// status, which is always 0.
    ///
    /// `arguments` are the arguments after the subcommand (`--event <Type>` and
    /// optionally `--ppid <int>`); `stdin` is the payload Claude Code piped in.
    /// A call without `--event` writes nothing. `accountName` maps an OAuth
    /// token to its account ("" when unknown) and `oauthEmail` reads the machine
    /// login's account; both are injected because the toolkit core has no
    /// account store.
    public static func run(
        arguments: [String],
        stdin: Data,
        environment: [String: String],
        configuration: ClaudeHookConfiguration,
        accountName: (String?) -> String,
        oauthEmail: () -> String = { "" },
        claudePid: () -> Int32? = { ProcessEnv.claudePid(aboveHookParent: getppid()) }
    ) -> Int32 {
        let values = flagValues(arguments)
        guard let eventType = values["--event"], !eventType.isEmpty else { return 0 }
        guard let envelope = buildEnvelope(
            eventType: eventType,
            ppidString: values["--ppid"],
            stdin: stdin,
            env: environment,
            claudePid: claudePid,
            accountName: accountName,
            oauthEmail: oauthEmail
        ) else { return 0 }
        // Any failure is swallowed: stderr from a hook can confuse Claude Code,
        // and the next event brings the same information.
        try? HookDropWriter.writeDropFile(
            envelope: envelope,
            directory: HookDropWriter.dropDirectory(configuration: configuration, environment: environment))
        return 0
    }

    /// Builds the drop-file envelope from the hook inputs, or returns nil when
    /// the event must not be tracked. Pure over `env`/`stdin` for the hook_data
    /// it produces (context.* is still captured from the live process), which is
    /// what keeps the headless-drop and term_session_id behaviour unit-testable
    /// without mutating the process environment or redirecting stdin.
    ///
    /// `claudePid` finds the `claude` process when the command line passed no
    /// `--ppid` (the registered command does not; see `ProcessEnv.claudePid`).
    /// `oauthEmail` is the machine login's account, read now rather than when the
    /// daemon drains the file: see the comment where it is used.
    public static func buildEnvelope(
        eventType: String, ppidString: String?, stdin: Data, env: [String: String],
        claudePid: () -> Int32? = { ProcessEnv.claudePid(aboveHookParent: getppid()) },
        accountName: (String?) -> String,
        oauthEmail: () -> String = { "" }
    ) -> [String: Any]? {
        // Mirror HookEnvelopeBuilder (socket path) and the shell hook: a
        // programmatic `claude` a daemon's own app runs (AI summaries) exports
        // AGENTIC_TOOLKIT_HEADLESS and must NOT be tracked. Guarding here, not
        // only in the shell hook, means a headless drop file is never written
        // even if this command is invoked directly or the daemon was down, so
        // none can be quarantined and later replayed into a phantom session.
        guard env["AGENTIC_TOOLKIT_HEADLESS"] == nil else { return nil }

        var hookData: [String: Any] = {
            guard !stdin.isEmpty,
                  let parsed = try? JSONSerialization.jsonObject(with: stdin) as? [String: Any]
            else { return [:] }
            return parsed
        }()

        // Claude's PID: an explicit --ppid if a caller passed one, else found by
        // walking up from this process. nil when neither names a `claude`.
        let ppid = Int(ppidString ?? "") ?? claudePid().map(Int.init)

        // Preserve v4 wire-compat: term_program lifted onto hook_data, and
        // SessionStart carries pid (= Claude's PID, 0 when unknown).
        hookData["term_program"] = env["TERM_PROGRAM"] ?? ""
        // Match HookEnvelopeBuilder (socket path): carry the terminal session id
        // so an app can jump to the exact tab/pane, even when the daemon was down
        // and this fallback wrote the drop file.
        hookData["term_session_id"] = env["TERM_SESSION_ID"] ?? ""
        if eventType == "SessionStart" {
            hookData["pid"] = ppid ?? 0
        }

        // Claude Code scrubs CLAUDE_CODE_OAUTH_TOKEN from the env it hands hook
        // commands; recover it from the parent `claude` process ($PPID) instead,
        // falling back to the (likely-empty) forwarded env if the walk fails.
        let token = ProcessEnv.oauthTokenWalkingUp(from: getppid()) ?? env["CLAUDE_CODE_OAUTH_TOKEN"]

        return [
            "event": eventType,
            "timestamp": iso8601UTC(),
            "hook_data": hookData,
            "context": captureContext(ppid: ppid),
            "account_email": accountName(token),
            // Resolved while the hook fires, as HookEnvelopeBuilder does for the
            // socket path. The file may sit in the drop directory through an
            // update, a migration or a stopped daemon, and the sessions upsert
            // keeps the first oauth stamp: left to the drain, a backlog is
            // billed for good to whoever is logged in by then.
            "oauth_account_email": oauthEmail()
        ]
    }

    // MARK: - Arguments

    /// Very small flag parser: `--key value` pairs only, positionals ignored.
    private static func flagValues(_ args: [String]) -> [String: String] {
        var values: [String: String] = [:]
        var index = 0
        while index < args.count {
            let arg = args[index]
            if arg.hasPrefix("--"), index + 1 < args.count, !args[index + 1].hasPrefix("--") {
                values[arg] = args[index + 1]
                index += 2
                continue
            }
            index += 1
        }
        return values
    }

    // MARK: - Context capture

    /// Curated process-context snapshot. Only fields with values are included;
    /// absent env vars are omitted.
    private static func captureContext(ppid: Int?) -> [String: Any] {
        var ctx: [String: Any] = [:]

        // claude.*
        var claude: [String: Any] = [:]
        if let value = env("CLAUDECODE") { claude["running"] = value == "1" || value.lowercased() == "true" }
        if let value = env("CLAUDE_CODE_ENTRYPOINT") { claude["entrypoint"] = value }
        if let value = env("CLAUDE_CODE_EXECPATH") { claude["exec_path"] = value }
        if let value = env("CLAUDE_PROJECT_DIR") { claude["project_dir"] = value }
        if let value = env("CLAUDE_YOLO") { claude["yolo"] = value == "1" || value.lowercased() == "true" }
        if !claude.isEmpty { ctx["claude"] = claude }

        // process.*
        var process: [String: Any] = [:]
        process["argv"] = Array(CommandLine.arguments.dropFirst())  // exclude $0
        process["cwd"] = currentWorkingDirectory()
        process["pid"] = Int(getpid())
        process["ppid"] = ppid ?? Int(getppid())
        process["uid"] = Int(getuid())
        process["euid"] = Int(geteuid())
        process["gid"] = Int(getgid())
        ctx["process"] = process

        // system.*
        ctx["system"] = systemInfo()

        // shell.*
        var shell: [String: Any] = [:]
        if let value = env("SHELL") { shell["shell"] = value }
        if let value = env("SHLVL"), let num = Int(value) { shell["shlvl"] = num }
        if let value = env("LANG") { shell["lang"] = value }
        if let value = env("PATH") { shell["path"] = value }
        if !shell.isEmpty { ctx["shell"] = shell }

        // session.*
        var session: [String: Any] = [:]
        if let value = env("USER") { session["user"] = value }
        if let value = env("HOME") { session["home"] = value }
        if let value = env("LOGNAME") { session["logname"] = value }
        if let value = env("TMPDIR") { session["tmpdir"] = value }
        if let value = env("PWD") { session["pwd"] = value }
        if !session.isEmpty { ctx["session"] = session }

        // terminal.*
        var terminal: [String: Any] = [:]
        if let value = env("TERM") { terminal["term"] = value }
        if let value = env("TERM_PROGRAM") { terminal["term_program"] = value }
        if let value = env("TERM_PROGRAM_VERSION") { terminal["term_version"] = value }
        if let value = env("TERM_SESSION_ID") { terminal["term_session_id"] = value }
        if let value = env("LC_TERMINAL") { terminal["lc_terminal"] = value }
        if !terminal.isEmpty { ctx["terminal"] = terminal }

        return ctx
    }

    private static func env(_ key: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[key], !value.isEmpty else { return nil }
        return value
    }

    private static func currentWorkingDirectory() -> String {
        var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
        return buf.withUnsafeMutableBufferPointer { ptr -> String in
            guard let base = ptr.baseAddress, getcwd(base, ptr.count) != nil else { return "" }
            return String(cString: base)
        }
    }

    /// Hostname, OS and architecture, shared with `HookEnvelopeBuilder`'s context.
    static func systemInfo() -> [String: Any] {
        var info = utsname()
        guard uname(&info) == 0 else { return [:] }
        let hostname = withUnsafePointer(to: &info.nodename) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        let sysname = withUnsafePointer(to: &info.sysname) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        let release = withUnsafePointer(to: &info.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        let machine = withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return [
            "hostname": hostname,
            "os": "\(sysname) \(release)",
            "arch": machine
        ]
    }

    static func iso8601UTC() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
}
