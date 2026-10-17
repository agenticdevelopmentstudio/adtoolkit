import Foundation

/// Enumerates the live `claude` (Claude Code CLI) processes via libproc + sysctl —
/// no subprocess, and no reliance on the
/// unreliable stored hook PID (which is the hook's transient shell, not Claude).
///
/// `LivenessTask` uses this to reconcile session status: a session is active
/// while its `claude` process exists and ended when it doesn't.
///
/// Identity comes from the **launched executable path** (`KERN_PROCARGS2`), whose
/// basename is `claude` for the CLI (`~/.local/bin/claude`). `proc_pidpath` is
/// NOT usable: the CLI's real image is a version-named binary
/// (`~/.local/share/claude/versions/2.1.183`, basename = the version, not
/// `claude`), and `proc_pidpath` fails outright once an old version's file is
/// removed by an update. The launch path is recorded at exec time, so it's stable
/// and present for every process. The desktop app (`/Applications/Claude.app`) has
/// a different launch path, so it's excluded.
public enum ProcessLiveness {

    /// One running Claude Code CLI process, as liveness sees it.
    public struct LiveClaudeProcess: Sendable, Equatable {
        public let pid: pid_t
        /// Nil when the parent can't be read. A parent that is itself a live
        /// `claude` marks this process as that CLI's helper, not a session.
        public let parentPid: pid_t?
        /// The canonical directory the process was launched in. It does not follow
        /// the agent: `cd` and `EnterWorktree` move the hook's cwd, never this.
        /// Empty when the kernel would not name it (a revoked vnode, an unmounted
        /// volume) — such a process claims nothing by directory.
        public let cwd: String
        /// The session the process is running now, from its own session file, or nil
        /// when it wrote none (see ``currentSessionId(ofPid:environment:)``).
        public let sessionId: String?

        public init(pid: pid_t, parentPid: pid_t?, cwd: String, sessionId: String?) {
            self.pid = pid
            self.parentPid = parentPid
            self.cwd = cwd
            self.sessionId = sessionId
        }
    }

    /// Every running `claude` CLI process with its launch directory and, where the
    /// CLI recorded one, the session it is running.
    ///
    /// Returns `nil` if process enumeration itself failed (a Mac always has
    /// processes, so an empty pid list means `proc_listpids` failed, not "no
    /// processes") — the caller skips reconciliation rather than ending every
    /// session on a bad scan. An empty (non-nil) array means "enumerated, no
    /// `claude` running". Best-effort: per-process query failures are skipped.
    ///
    /// An unreadable cwd is not a reason to skip a process that names its session.
    /// The session id comes from the CLI's own session file and never consults the
    /// directory, whereas `PROC_PIDVNODEPATHINFO` fails *durably* when the process's
    /// cwd vnode is revoked or its volume is unmounted — a deleted worktree, an
    /// ejected disk. Dropping the whole process there hid a live `claude` from
    /// liveness on every tick, which ended its session while it was still running.
    /// Only a process with neither a session nor a directory says nothing at all.
    public static func liveClaudeProcesses() -> [LiveClaudeProcess]? {
        let pids = allPIDs()
        guard !pids.isEmpty else { return nil }
        return pids.filter(isClaudeProcess).compactMap { pid in
            let sessionId = currentSessionId(ofPid: pid, environment: ProcessEnv.environment(forPid: pid))
            let cwd = workingDirectory(pid)
            guard sessionId != nil || cwd != nil else { return nil }
            return LiveClaudeProcess(
                pid: pid,
                parentPid: ProcessEnv.parentPid(of: pid),
                cwd: cwd.map(canonicalPath) ?? "",
                sessionId: sessionId
            )
        }
    }

    /// The session `pid` is running, read from the file the CLI keeps for itself at
    /// `<config dir>/sessions/<pid>.json` — `~/.claude` unless the process was started
    /// with `CLAUDE_CONFIG_DIR`. The CLI rewrites it when the process resumes or
    /// clears into a different session, so it names the current one, not the first.
    ///
    /// This is the only direct link between a process and a session. The directory is
    /// not one: a session records wherever its agent last ran a command, so a session
    /// that moved into a submodule or a worktree no longer sits where its process was
    /// launched, while an older session the same process has since left still does.
    ///
    /// Nil when there is no file (the CLI's helper processes write none) or it doesn't
    /// read as this pid's — a file left by a dead process whose pid was reused.
    public static func currentSessionId(ofPid pid: pid_t, environment: [String: String]?) -> String? {
        let configured = environment?["CLAUDE_CONFIG_DIR"] ?? ""
        let configDir = configured.isEmpty
            ? (NSHomeDirectory() as NSString).appendingPathComponent(".claude")
            : configured
        let file = URL(fileURLWithPath: configDir).appendingPathComponent("sessions/\(pid).json")
        guard let data = try? Data(contentsOf: file) else { return nil }
        return sessionId(fromSessionFile: data, pid: pid)
    }

    /// The `sessionId` of a CLI session file, provided the file's own `pid` is `pid`.
    public static func sessionId(fromSessionFile data: Data, pid: pid_t) -> String? {
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              (json["pid"] as? NSNumber)?.int32Value == pid,
              let sessionId = json["sessionId"] as? String, !sessionId.isEmpty
        else { return nil }
        return sessionId
    }

    /// The pid of the *unique* live `claude` CLI process whose working directory
    /// matches `cwd` (both canonicalized), or nil if none — or more than one — is
    /// running there.
    ///
    /// This is what lets the `http` hook path recover state the bash hook used
    /// to forward out-of-band. An `http` hook carries only the payload JSON — no
    /// `$PPID`, no `env` dump — but the payload's `cwd` locates the live `claude`
    /// process, and `ProcessEnv.environment(forPid:)` reads its env (the scrubbed
    /// OAuth token, `TERM_PROGRAM`, `TERM_SESSION_ID`, `CLAUDE_*`) straight from it.
    ///
    /// Ambiguity is a *refusal*, not a guess: because the recovered pid's env now
    /// decides which account an event is billed to, picking an arbitrary "first
    /// match" when two `claude` sessions share one directory could attribute
    /// session B's event to session A's account. Returning nil instead makes the
    /// caller fall back to the read-time oauth account — the safe degradation, and
    /// consistent with the account-attribution invariant (token-only at write time).
    public static func claudePid(inCwd cwd: String) -> pid_t? {
        uniqueClaude(
            among: allPIDs(), inCwd: canonicalPath(cwd),
            directory: workingDirectory, isClaude: isClaudeProcess, canonical: canonicalPath
        )
    }

    /// The matching rule behind ``claudePid(inCwd:)``, with the three probes
    /// passed in so a test can see which processes each one touched.
    ///
    /// Two passes, each cheapest-first:
    /// 1. The kernel's own path (`PROC_PIDVNODEPATHINFO`, answered from kernel
    ///    state and already physical) equal to `target`, then the
    ///    `KERN_PROCARGS2` read — which pages the process's memory in — for only
    ///    the few processes sitting there.
    /// 2. Only when that finds nothing: the `claude` processes, with their
    ///    directories run through `realpath`.
    ///
    /// `realpath` walks the file system, so it blocks for as long as a dead
    /// network mount does. It is never run on an unrelated process's
    /// directory: a shell left in an unreachable SMB share must not stall the
    /// hook-ingest path. Only `claude` processes, which were always resolved,
    /// get it.
    public static func uniqueClaude(
        among pids: [pid_t],
        inCwd target: String,
        directory: (pid_t) -> String?,
        isClaude: (pid_t) -> Bool,
        canonical: (String) -> String
    ) -> pid_t? {
        var directories: [pid_t: String] = [:]
        for pid in pids { directories[pid] = directory(pid) }

        func unique(_ matches: (pid_t, String) -> Bool) -> (found: Bool, pid: pid_t?) {
            var match: pid_t?
            for pid in pids {
                guard let dir = directories[pid], matches(pid, dir) else { continue }
                if match != nil { return (true, nil) }   // >1 claude here ⇒ ambiguous, don't guess
                match = pid
            }
            return (match != nil, match)
        }

        let exact = unique { pid, dir in dir == target && isClaude(pid) }
        if exact.found { return exact.pid }
        return unique { pid, dir in isClaude(pid) && canonical(dir) == target }.pid
    }

    /// Fully resolves symlinks (via `realpath`) so the session `cwd` the hook
    /// stored (the logical `$PWD`, e.g. `/tmp/x`) compares equal to the physical
    /// path libproc reports (e.g. `/private/tmp/x`). `URL.resolvingSymlinksInPath`
    /// is NOT used: it deliberately leaves `/tmp`, `/var`, `/etc` unresolved.
    /// Falls back to the input when the path doesn't exist.
    public static func canonicalPath(_ path: String) -> String {
        guard let resolved = realpath(path, nil) else { return path }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    // MARK: - Enumeration

    /// Process IDs owned by the current user (best-effort). `PROC_UID_ONLY`
    /// narrows the kernel scan to this user's processes — a live `claude` is
    /// always same-user, and it avoids a `KERN_PROCARGS2` probe of every root /
    /// other-user process each tick. The buffer is over-allocated beyond the
    /// sizing call's count so a `fork` burst between the size and fill calls (a
    /// TOCTOU that would otherwise truncate) doesn't drop pids; the byte size is
    /// clamped so a pathological count can't trap the `Int32` conversion.
    private static func allPIDs() -> [pid_t] {
        let uid = getuid()
        let bytes = proc_listpids(UInt32(PROC_UID_ONLY), uid, nil, 0)
        guard bytes > 0 else { return [] }
        let capacity = Int(bytes) / MemoryLayout<pid_t>.stride + 256
        var pids = [pid_t](repeating: 0, count: capacity)
        let written = proc_listpids(
            UInt32(PROC_UID_ONLY), uid, &pids, Int32(clamping: capacity * MemoryLayout<pid_t>.stride)
        )
        guard written > 0 else { return [] }
        let count = Int(written) / MemoryLayout<pid_t>.stride
        return pids.prefix(count).filter { $0 > 0 }
    }

    /// Whether `pid` is a Claude Code CLI process, by the path it was launched
    /// with (`KERN_PROCARGS2`, layout `[argc: Int32][exec_path NUL-terminated]…`).
    /// Matches basename `claude` (the CLI launcher `~/.local/bin/claude`) or any
    /// `…/claude/…` path component (e.g. a versioned/wrapped install), and excludes
    /// the desktop app `/Applications/Claude.app/…`. Same-user pids only; others /
    /// unreadable return false.
    private static func isClaudeProcess(_ pid: pid_t) -> Bool {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.stride else { return false }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return false }
        let execPath = buffer.withUnsafeBufferPointer { ptr -> String in
            guard let base = ptr.baseAddress else { return "" }
            return String(cString: base.advanced(by: MemoryLayout<Int32>.stride))
        }
        guard !execPath.isEmpty else { return false }
        return (execPath as NSString).lastPathComponent == "claude" || execPath.contains("/claude/")
    }

    /// `pid`'s current working directory via `PROC_PIDVNODEPATHINFO`, or nil.
    private static func workingDirectory(_ pid: pid_t) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        let read = withUnsafeMutablePointer(to: &info) {
            proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, $0, size)
        }
        guard read == size else { return nil }
        // Bound the read to the field width via strnlen so a (kernel-bug)
        // non-NUL-terminated vip_path can't make String(cString:) over-read into
        // adjacent struct memory.
        return withUnsafeBytes(of: &info.pvi_cdir.vip_path) { raw -> String? in
            guard let base = raw.baseAddress else { return nil }
            let length = strnlen(base.assumingMemoryBound(to: CChar.self), raw.count)
            return String(bytes: UnsafeRawBufferPointer(start: base, count: length), encoding: .utf8)
        }
    }
}
