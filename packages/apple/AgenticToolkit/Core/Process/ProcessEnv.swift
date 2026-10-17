import Foundation
import Darwin

// swiftlint:disable identifier_name
// Short loop/scratch names below (i, s, eq, pp) mirror the standard
// KERN_PROCARGS2 parsing idiom used everywhere this technique is documented;
// renaming them buys nothing and would make the byte-offset walk harder to
// eyeball-verify.

/// Recovers `CLAUDE_CODE_OAUTH_TOKEN` from a parent `claude` process. Claude
/// Code scrubs the token from the env it gives hook/status-line commands, but
/// the token lives in the `claude` process, whose pid the hook forwards
/// ($PPID). Same-user KERN_PROCARGS2 is readable (as `ps eww` proves). Shared
/// by the daemon and the CLI target (file-listed in both, like DigestHex).
public enum ProcessEnv {
    /// How long a resolved token stays usable. Checked on read; also the
    /// staleness predicate the over-cap eviction in `oauthTokenWalkingUp` uses.
    private static let ttl: TimeInterval = 30

    /// Hard ceiling on cached entries. Matches `HookEnvCache`, whose two caches
    /// are the same shape and already bound themselves this way.
    public static let maxEntries = 128

    private static let lock = NSLock()

    /// pid → the token that pid's parent chain yielded.
    ///
    /// The TTL is checked on *read*, which is not the same as bounding the
    /// dictionary: an expired entry stays resident until something asks for that
    /// exact pid again, and nothing ever does — pids belong to short-lived hook
    /// processes, so every miss allocates a key that is already dead. Over a
    /// daemon uptime measured in weeks that is unbounded growth holding an OAuth
    /// token per entry, long after both the process and the token's usefulness
    /// are gone. So `oauthTokenWalkingUp` evicts inline after each insert, once
    /// the dictionary is over `maxEntries`: first by the same TTL the reads
    /// already trust, then — if everything is still live — by dropping all but
    /// the newest `maxEntries`.
    nonisolated(unsafe) private static var cache: [Int32: (at: Date, token: String)] = [:]

    /// The environment (KEY→VALUE) the process was started with, or nil.
    /// NOTE: this is the exec-time env snapshot (KERN_PROCARGS2), not live setenv changes.
    public static func environment(forPid pid: Int32) -> [String: String]? {
        procArgs(forPid: pid)?.env
    }

    /// The executable path, argv and environment `pid` was exec'd with, or nil.
    private static func procArgs(forPid pid: Int32)
        -> (execPath: String, argv: [String], env: [String: String])? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return nil }
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buf, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return nil }
        // Layout: int32 argc | exec_path\0 | \0-padding | argv[0..argc-1]\0 | env...\0
        let argc = buf.withUnsafeBytes { $0.load(as: Int32.self) }
        var i = MemoryLayout<Int32>.size
        let pathStart = i
        while i < size && buf[i] != 0 { i += 1 }          // exec_path
        let execPath = String(bytes: buf[pathStart..<i], encoding: .utf8) ?? ""
        while i < size && buf[i] == 0 { i += 1 }          // skip null padding
        var argv: [String] = []                            // argc argv strings
        while argv.count < Int(argc) && i < size {
            let start = i
            while i < size && buf[i] != 0 { i += 1 }
            argv.append(String(bytes: buf[start..<i], encoding: .utf8) ?? "")
            i += 1
        }
        var env: [String: String] = [:]                    // remaining = env
        while i < size {
            let start = i
            while i < size && buf[i] != 0 { i += 1 }
            if i > start, let s = String(bytes: buf[start..<i], encoding: .utf8),
               let eq = s.firstIndex(of: "=") {
                env[String(s[..<eq])] = String(s[s.index(after: eq)...])
            }
            i += 1
        }
        return (execPath, argv, env)
    }

    /// The names `pid` answers to: argv[0]'s and the executable's basenames,
    /// with a login shell's leading "-" dropped. Both, because neither alone
    /// names `claude`: the native install execs `…/claude/versions/2.1.x`
    /// (so the executable is a version number) through a `claude` symlink
    /// (so argv[0] is `claude`), while the npm install is `node` running a script.
    public static func processNames(of pid: Int32) -> Set<String> {
        guard let args = procArgs(forPid: pid) else { return [] }
        let paths = [args.execPath] + args.argv.prefix(1)
        return Set(paths.map { path -> String in
            let name = (path as NSString).lastPathComponent
            return name.hasPrefix("-") ? String(name.dropFirst()) : name
        }.filter { !$0.isEmpty })
    }

    /// Shells Claude Code may run a hook command line through.
    public static let hookShellNames: Set<String> = ["sh", "bash", "zsh", "dash"]

    /// What the `claude` process is called: the native binary or node.
    public static let claudeProcessNames: Set<String> = ["claude", "node"]

    /// The pid of the `claude` process that ran a hook, found from the hook's
    /// own parent `parent` (its `getppid()`), or nil when the chain is not the
    /// expected one.
    ///
    /// The hook command line is several statements (marker, `steno`, `exit 0`),
    /// so Claude Code hands it to `/bin/sh -c` and the shell cannot exec
    /// `steno` in its place: `steno`'s parent is that shell and the shell's is
    /// `claude`. That is the pid the rendered command used to forward as
    /// `$PPID`, and the one the app's tab activation and text injection key on.
    /// Checked by name rather than trusted by position, because a wrong pid
    /// would aim an injection at someone else's terminal, while nil only
    /// leaves the session's pid unknown.
    public static func claudePid(
        aboveHookParent parent: Int32,
        parentOf: (Int32) -> Int32? = parentPid(of:),
        namesOf: (Int32) -> Set<String> = processNames(of:)
    ) -> Int32? {
        var pid = parent
        if !namesOf(pid).isDisjoint(with: hookShellNames) {
            guard let up = parentOf(pid) else { return nil }
            pid = up
        }
        guard pid > 1, !namesOf(pid).isDisjoint(with: claudeProcessNames) else { return nil }
        return pid
    }

    /// The parent pid of `pid`, or nil.
    public static func parentPid(of pid: Int32) -> Int32? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        let pp = info.kp_eproc.e_ppid
        return pp > 0 ? pp : nil
    }

    /// Walk up the parent chain from `startPid`, returning the first non-empty
    /// CLAUDE_CODE_OAUTH_TOKEN found (the `claude` process), or nil. Cached per
    /// startPid for 30s so the daemon's per-event calls don't re-sysctl-walk.
    public static func oauthTokenWalkingUp(from startPid: Int32, maxHops: Int = 16) -> String? {
        lock.lock()
        if let hit = cache[startPid], Date().timeIntervalSince(hit.at) < ttl {
            lock.unlock()
            return hit.token.isEmpty ? nil : hit.token
        }
        lock.unlock()

        let found = firstToken(from: startPid, maxHops: maxHops, stoppingAt: nil)
        let now = Date()
        lock.lock()
        cache[startPid] = (now, found)
        if cache.count > maxEntries {
            cache = cache.filter { now.timeIntervalSince($0.value.at) < ttl }
            if cache.count > maxEntries {
                // Still over after dropping the stale entries: a burst of live
                // hook processes, all inside the TTL. Keep the newest and drop
                // the rest, so the cap is a real ceiling rather than "however
                // many distinct pids appeared in the last 30 seconds". An
                // evicted entry costs one sysctl walk to rebuild; an
                // unevictable one costs a token held forever.
                let newest = cache.sorted { $0.value.at > $1.value.at }.prefix(maxEntries)
                cache = Dictionary(uniqueKeysWithValues: newest.map { ($0.key, $0.value) })
            }
        }
        lock.unlock()
        return found.isEmpty ? nil : found
    }

    /// The same walk, stopping short of `boundary` — the shell that ran
    /// `steno claude clear`. An environment read here is the one a process was
    /// exec'd with, so that shell and everything above it still show the token
    /// it had before the clear; only a process started below it can have pinned
    /// one since. Uncached: `steno` asks once per run.
    public static func oauthTokenWalkingUp(from startPid: Int32, below boundary: Int32, maxHops: Int = 16) -> String? {
        let found = firstToken(from: startPid, maxHops: maxHops, stoppingAt: boundary)
        return found.isEmpty ? nil : found
    }

    private static func firstToken(from startPid: Int32, maxHops: Int, stoppingAt boundary: Int32?) -> String {
        var pid = startPid
        var hops = 0
        while pid > 1 && pid != boundary && hops < maxHops {
            if let env = environment(forPid: pid),
               let tok = env["CLAUDE_CODE_OAUTH_TOKEN"], !tok.isEmpty {
                return tok
            }
            guard let pp = parentPid(of: pid), pp != pid else { break }
            pid = pp
            hops += 1
        }
        return ""
    }

    /// Cached pid→token entries. A test seam: the growth this bounds is invisible
    /// from the outside, because every read of a live pid returns the same answer
    /// whether or not the dead pids beside it were ever evicted.
    public static var cachedTokenCountForTesting: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }

    /// Drops every cached token. Tests only — the daemon has no reason to.
    public static func resetCacheForTesting() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}
// swiftlint:enable identifier_name
