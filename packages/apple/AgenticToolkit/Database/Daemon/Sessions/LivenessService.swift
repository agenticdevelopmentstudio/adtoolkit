#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

/// Reconciles session status against live `claude` processes. A session is
/// **active while its `claude` process exists and destroyed (`ended`) when it's
/// gone** — idle time is irrelevant, there are no staleness/ended timeouts.
///
/// The stored `pid` is the hook's transient shell (not Claude) and Claude doesn't
/// hold its transcript open. What links a process to its session is the file the
/// CLI keeps for each process, which names the session it is running; the working
/// directory is the fallback for a process that has none. See
/// ``liveSessionIds(processes:database:)``. The sessions it returns are forced
/// `active` — resurrected even if they had ended; every other `active`/`stale`
/// session is ended at once.
///
/// One `reconcile()` is one pass; the caller owns the schedule.
public struct LivenessService: Sendable {
    public typealias LiveClaudeProcess = ProcessLiveness.LiveClaudeProcess

    public let database: DaemonDatabase
    public let onStatusChange: @Sendable (String, SessionStatus) -> Void
    /// The running `claude` processes, or `nil` if process enumeration failed (so a
    /// bad scan can't end every session). Injected so the logic is unit-testable
    /// without real processes; the default is ``ProcessLiveness/liveClaudeProcesses()``.
    public let liveProcesses: @Sendable () -> [LiveClaudeProcess]?

    public init(
        database: DaemonDatabase,
        liveProcesses: @escaping @Sendable () -> [LiveClaudeProcess]? = ProcessLiveness.liveClaudeProcesses,
        onStatusChange: @escaping @Sendable (String, SessionStatus) -> Void
    ) {
        self.database = database
        self.liveProcesses = liveProcesses
        self.onStatusChange = onStatusChange
    }

    /// One reconciliation pass over the sessions table.
    public func reconcile() {
        // nil = process enumeration failed; skip this tick rather than ending
        // every session (an empty dict means "enumerated, no claude running").
        guard let processes = liveProcesses() else { return }

        // nil = the DB couldn't be asked which sessions exist. Same posture as the
        // guard above: skip the tick rather than reconcile against an answer we
        // don't have.
        guard let liveIds = Self.liveSessionIds(processes: processes, database: database) else {
            logger.info("liveness: skipped — the session lookup failed, nothing reconciled")
            return
        }

        let shown = (try? database.fetchActiveSessionsForLiveness()) ?? []
        let activeIds = Set(shown.filter { $0.status == SessionStatus.active.rawValue }.map(\.sessionId))
        logger.info("liveness: \(processes.count) live claude process(es), \(liveIds.count) live session(s)")

        // Promote/resurrect every live session that isn't already active.
        for sessionId in liveIds where !activeIds.contains(sessionId) {
            database.updateSessionStatus(.active, sessionId: sessionId)
            onStatusChange(sessionId, .active)
        }

        // End every shown session whose process is gone — except ones with no
        // cwd, which can't be reconciled against a process (no live claude ever
        // reports an empty cwd), so ending them would be a guess.
        for session in shown where !liveIds.contains(session.sessionId) && !session.cwd.isEmpty {
            logger.info("Session \(session.sessionId, privacy: .public) ended (no live claude)")
            database.updateSessionStatus(.ended, sessionId: session.sessionId)
            onStatusChange(session.sessionId, .ended)
        }
    }

    /// The sessions backed by a live `claude` process.
    ///
    /// **Named**: a process whose session file names a session owns exactly that one.
    /// Nothing about the directory is consulted, because the directory is what moves:
    /// a session records wherever its agent last ran a command, so once the agent
    /// `cd`s into a submodule or runs `EnterWorktree` the session no longer sits where
    /// its process was launched — while an older session that same process has since
    /// left behind (or a dead one from another terminal) still does. Matching by
    /// directory handed the process's slot to that stale session, ended the real one,
    /// and the real one's next hook resurrected it: the row popped in and out of the
    /// Sessions window every few seconds.
    ///
    /// **Helpers**: a process with no session file whose parent is itself a live
    /// `claude` is that CLI's helper (its background-agent daemon, a pty host, a warm
    /// spare) and claims nothing. Counted, it took a slot in whatever directory it
    /// was started in — the home directory for the daemon — and resurrected a dead
    /// session there. An *orphaned* one counts as a helper too: a helper outlives the
    /// `claude` that spawned it and is reparented to launchd, and matching only on a
    /// parent that is still a live `claude` let every reparented `bg-pty-host` /
    /// `bg-spare` back in — the same resurrection, now permanent, because nothing
    /// ever reaps them. A real CLI session is launched by a shell and names itself,
    /// so an unnamed process at ppid 1 is a helper every time.
    ///
    /// **Unnamed**: any other process without a session file (an older CLI) falls
    /// back to its directory, by ``cwdMatchedSessionIds(liveCounts:excluding:database:)``,
    /// among the sessions no named process already owns. A process whose directory the
    /// kernel wouldn't name has nothing to fall back to and is left out — an empty
    /// path would otherwise "contain" every session on the machine.
    ///
    /// Returns nil when the database couldn't be asked. An error is not an answer:
    /// read as "none of these sessions exist", it ends every live session at once.
    public static func liveSessionIds(processes: [LiveClaudeProcess], database: DaemonDatabase) -> Set<String>? {
        let named = Set(processes.compactMap(\.sessionId))
        let claudePids = Set(processes.map(\.pid))
        var unnamedCounts: [String: Int] = [:]
        for process in processes where process.sessionId == nil && !process.cwd.isEmpty {
            if let parent = process.parentPid, claudePids.contains(parent) || parent == 1 { continue }
            unnamedCounts[process.cwd, default: 0] += 1
        }
        guard let existingNamed = try? database.existingSessionIds(named),
              let cwdMatched = cwdMatchedSessionIds(
                  liveCounts: unnamedCounts, excluding: named, database: database
              )
        else { return nil }
        return existingNamed.union(cwdMatched)
    }

    /// The sessions a count of unnamed live `claude` processes per directory accounts
    /// for, leaving `excluded` (sessions a named process owns) out of the running.
    ///
    /// Matched by containment, not equality. A live `claude` reports the directory it
    /// was launched in; the session row records the hook *shell's* `$PWD`, which an
    /// agent moves the moment it runs anything from a subdirectory. The two then never
    /// compared equal again, so liveness ended the session, the next hook resurrected
    /// it, and the row blinked in and out of the Sessions window.
    ///
    /// Containment alone is not enough, because a shallow live directory contains its
    /// whole subtree. The project root `~/p` and its linked worktrees under
    /// `~/p/.claude/worktrees/*` are all "under `~/p`", so `~/p`'s single slot went to
    /// whichever subtree session happened to be most recently active — a long-dead
    /// worktree session got resurrected while the live session actually sitting in
    /// `~/p` was ended for want of a slot. On the next tick its hook fired, the two
    /// swapped, and both rows flickered.
    ///
    /// So ownership is decided first and claiming second.
    ///
    /// **Ownership**: every candidate goes to the *deepest* live directory that
    /// contains it, so a worktree with its own live `claude` keeps its own session
    /// instead of having it counted against the project root.
    ///
    /// **Claiming**: each directory then takes its `count` best candidates, closest
    /// first — fewest path components between the live directory and the session's
    /// `cwd`, ties broken by recency. Distance is the evidence here: a live `claude`
    /// reports exactly the directory it was launched in, so a session whose `cwd` *is*
    /// that directory is that process, and one three levels down is a guess about how
    /// far the agent has wandered. Recency alone is what let a session buried in a
    /// worktree outrank the one sitting in the directory itself.
    ///
    /// Returns nil when any directory's lookup couldn't be answered, for the same
    /// reason ``liveSessionIds(processes:database:)`` does: a directory that failed
    /// to answer looks exactly like a directory with no sessions under it, and the
    /// caller ends every session it didn't hear about. Skipping the tick is the only
    /// safe reading of a database that wouldn't answer.
    public static func cwdMatchedSessionIds(
        liveCounts: [String: Int],
        excluding excluded: Set<String>,
        database: DaemonDatabase
    ) -> Set<String>? {
        // Each directory's query spans its subtree, so the same session comes back
        // for several of them; keyed by id, it is considered once.
        var candidates: [String: DaemonDatabase.SessionCwdCandidate] = [:]
        for (directory, count) in liveCounts {
            guard let rows = try? database.recentSessionCandidates(
                underCwd: directory, limit: count, excluding: excluded
            ) else {
                return nil
            }
            for row in rows { candidates[row.sessionId] = row }
        }

        // Deepest-first, so the first containing directory found is the owner.
        let directoriesDeepestFirst = liveCounts.keys.sorted { $0.count > $1.count }
        var owned: [String: [DaemonDatabase.SessionCwdCandidate]] = [:]
        for candidate in candidates.values {
            guard let owner = directoriesDeepestFirst.first(where: { contains($0, candidate.cwd) }) else {
                continue
            }
            owned[owner, default: []].append(candidate)
        }

        var liveIds: Set<String> = []
        for (directory, count) in liveCounts {
            let mine = (owned[directory] ?? [])
                .sorted { lhs, rhs in
                    let lhsDepth = depth(of: lhs.cwd, below: directory)
                    let rhsDepth = depth(of: rhs.cwd, below: directory)
                    if lhsDepth != rhsDepth { return lhsDepth < rhsDepth }
                    return lhs.lastActivityAt > rhs.lastActivityAt
                }
                .prefix(count)
            liveIds.formUnion(mine.map(\.sessionId))
        }
        return liveIds
    }

    /// How many path components separate `path` from `directory` — 0 when they are the
    /// same directory. Only called for a `path` already known to be under `directory`.
    private static func depth(of path: String, below directory: String) -> Int {
        let trimmed = directory.hasSuffix("/") ? String(directory.dropLast()) : directory
        return path.dropFirst(trimmed.count).split(separator: "/").count
    }

    /// Whether `path` is `directory` itself or sits below it. Compared on path
    /// components, so `/a/bc` is not "under" `/a/b`.
    private static func contains(_ directory: String, _ path: String) -> Bool {
        path == directory || path.hasPrefix(directory.hasSuffix("/") ? directory : directory + "/")
    }
}

extension LivenessService: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
