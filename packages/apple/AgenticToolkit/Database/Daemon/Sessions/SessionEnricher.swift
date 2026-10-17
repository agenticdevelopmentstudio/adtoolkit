#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// `db` parameters are the one name for the shared DaemonDatabase, as in the toolkit.
// swiftlint:disable identifier_name

/// Derives the session fields the hook payload doesn't carry:
///   - `git_branch`   — via `git -C <cwd> rev-parse --abbrev-ref HEAD`
///   - `project_root` — the top-level (non-submodule) git working tree for `cwd`
///   - `transcript_title` — from the most recent `custom-title` line in the
///                      Claude Code transcript JSONL
///   - `last_output`  — the agent's most recent prose reply, tailed from the
///                      transcript when the Stop hook fires
///
/// All writes go through `DaemonDatabase` (which serialises them on its
/// own queue). Reads (filesystem / subprocess) run on the caller's
/// queue — callers hand off to a `Task.detached` so ingestion isn't
/// blocked.
public enum SessionEnricher {
    /// Version of the `projectRoot` algorithm. Bump this whenever the resolution
    /// logic changes (it last changed to collapse worktrees to the main working
    /// tree); rows stamped below it are recomputed by the backfill, rows at it are
    /// skipped — no blanket-reset migration needed.
    ///
    /// 2: ``ProjectRootResolution/undetermined`` — version 1 wrote `project_root = ''`
    /// and stamped it whenever `git` declined to answer about a reachable cwd, which
    /// is permanent: the row is at the current version, so every gate below skips it
    /// forever. The rows that bug already poisoned are exactly the population the
    /// `.undetermined` case exists to repair, and only a bump re-opens them.
    public static let projectRootAlgoVersion = 2

    /// Version of the startup backfill sweep. A row stamped at this version is
    /// skipped by `sessionsNeedingEnrichment` even if it's still missing a branch or
    /// summary — the sweep already looked and there was nothing to find. Bump this
    /// whenever enrichment learns to extract something it previously couldn't, which
    /// re-opens every historical row exactly once.
    public static let enrichmentAlgoVersion = 2

    /// Where ``enrich(sessionId:cwd:projectRootVersion:titleSource:database:)``
    /// should look for the session's `custom-title`.
    ///
    /// The two callers have genuinely different needs, and collapsing them is what
    /// made the startup pass expensive. A hook firing for a live session has just
    /// caused the write we care about and the importer may not have picked it up
    /// yet, so it must read the file. The startup sweep is re-examining sessions
    /// the importer has already stored in full, so reading the file there only
    /// re-derives what the daemon wrote down — at 163 MB a session.
    public enum TitleSource: Sendable, Equatable {
        /// Stream the transcript file. `path` nil means "go find it".
        case transcriptFile(path: String?)
        /// Read `transcript_lines`, falling back to the file only for a session
        /// the importer has not stored at all (so nothing is silently missed).
        case importedLines
    }

    /// Whether a sweep of one session actually got to look at everything it needed.
    ///
    /// This is the distinction the value columns cannot express, and the caller needs
    /// it to decide about stamping. `gitBranch(at:)` returns nil both for "this cwd is
    /// not a git working tree" (permanent — stamping is right, it stops the row being
    /// re-examined every launch) and for "this cwd isn't there right now" (transient —
    /// an unmounted volume, a worktree mid-move, a directory about to be restored).
    /// Stamping the transient case is a one-way door: the row is marked swept at the
    /// current algorithm version and never reconsidered, so a branch and root that
    /// would resolve fine tomorrow are lost until someone bumps a version constant.
    public enum SweepOutcome: Sendable, Equatable {
        /// Everything that could be derived was derived. Safe to stamp.
        case complete
        /// The git-derived fields could not be attempted: the session's `cwd` isn't on
        /// disk, or `git` itself declined to answer for it (see
        /// ``ProjectRootResolution/undetermined``). Don't stamp on the normal path —
        /// try again next launch, because an unmounted volume can come back and a repo
        /// mid-operation finishes. The backfill does stamp these once the session has
        /// been inactive long enough that the directory is plainly deleted rather than
        /// absent, or the retry repeats forever (see
        /// `DaemonDatabase.stampSessionEnrichment`'s `onlyInactiveForDays`).
        case inputsUnavailable
    }

    /// What a project-root resolution actually learned, which is not the same as what
    /// it returned. `projectRoot(at:)` answers `nil` both for "git says there is no
    /// repository here" and for "git wouldn't answer", and only the first of those may
    /// be written down: `project_root = ''` is stamped at the current algorithm
    /// version and never reconsidered, so one `git` that failed — a repo mid-rebase, a
    /// worktree being moved, a momentarily unavailable binary — permanently records a
    /// session as rootless. The Sessions window then labels it with its `cwd`'s last
    /// component and groups it alone, which is how a worktree ends up displayed as its
    /// own project, under the worktree's name, beside its own siblings.
    public typealias ProjectRootResolution = GitProjectRoot.Resolution

    /// Runs all enrichments for the given session. Safe to call repeatedly: it
    /// writes git_branch/title only when it finds a non-empty value, and it
    /// recomputes project_root only when `projectRootVersion` is below the current
    /// algorithm version (pass 0 to force a recompute, e.g. on SessionStart).
    @discardableResult
    public static func enrich(
        sessionId: String,
        cwd: String,
        projectRootVersion: Int,
        titleSource: TitleSource,
        database: DaemonDatabase
    ) -> SweepOutcome {
        // An empty `cwd` is permanent — nothing will ever fill it in for a session
        // row that was written without one — so it counts as "looked, found nothing"
        // and stays stampable. A *non-empty* cwd that isn't on disk is the transient
        // case: it can come back.
        let cwdReachable = cwd.isEmpty || FileManager.default.fileExists(atPath: cwd)

        if let branch = gitBranch(at: cwd), !branch.isEmpty {
            database.updateSessionGitBranch(branch, sessionId: sessionId)
        }
        // The second way this sweep comes up empty through no fault of the session's:
        // `cwd` is right there on disk, but git wouldn't answer about it.
        var rootUndetermined = false
        if projectRootVersion < projectRootAlgoVersion, cwdReachable {
            switch projectRootResolution(at: cwd) {
            case .resolved(let root):
                database.updateSessionProjectRoot(
                    root, version: projectRootAlgoVersion, sessionId: sessionId
                )
            case .notAGitWorkingTree:
                // Stamp the empty root: git positively said there is no repository
                // here, so the row drops out of the backfill instead of re-running
                // git forever.
                database.updateSessionProjectRoot(
                    "", version: projectRootAlgoVersion, sessionId: sessionId
                )
            case .undetermined:
                // Write nothing at all — see `ProjectRootResolution` for what
                // stamping a guess here costs.
                rootUndetermined = true
            }
        }
        // The title comes from the DB (or the transcript), not from `cwd`, so it is
        // still worth resolving for an unreachable session.
        if let title = customTitle(sessionId: sessionId, source: titleSource, database: database),
           !title.isEmpty {
            // `transcript_title`, NOT `summary`. Writing the name into the summary
            // column is what made the Sessions window print "vsc-plugins" where a
            // summary belonged, and it also told the summarizer the row was already
            // done — so those sessions were never summarized at all.
            // `updateSessionTranscriptTitle` clears the residue of the old behavior.
            try? database.updateSessionTranscriptTitle(
                sessionId: sessionId, title: title, source: "custom"
            )
        }
        return cwdReachable && !rootUndetermined ? .complete : .inputsUnavailable
    }

    /// Records the agent's most recent prose reply for `sessionId`, reading the tail
    /// of its transcript. Call it when the agent has just stopped speaking.
    public static func refreshLastOutput(sessionId: String, transcriptPath: String?, database: DaemonDatabase) {
        guard let path = transcriptPath ?? findTranscriptPath(sessionId: sessionId),
              let text = transcriptLastAssistantText(path: path), !text.isEmpty else { return }
        database.updateSessionLastOutput(text, sessionId: sessionId)
    }

    /// Resolves the session's custom title from `source`, or nil when there is none.
    private static func customTitle(
        sessionId: String,
        source: TitleSource,
        database: DaemonDatabase
    ) -> String? {
        switch source {
        case .transcriptFile(let path):
            guard let path = path ?? findTranscriptPath(sessionId: sessionId) else { return nil }
            return transcriptCustomTitle(path: path)
        case .importedLines:
            switch (try? database.latestCustomTitle(sessionId: sessionId)) ?? .notImported {
            case .found(let title):
                return title
            case .absent:
                // Authoritative: the importer has this session's lines and none is
                // a title. Reading the file would burn a full scan to learn the
                // same thing — which is exactly what this pass used to do.
                return nil
            case .notImported:
                // The DB genuinely cannot answer yet, so fall back rather than
                // report a false "no title" for a session that has one.
                guard let path = findTranscriptPath(sessionId: sessionId) else { return nil }
                return transcriptCustomTitle(path: path)
            }
        }
    }

    /// Returns the current branch for `cwd`, or nil if cwd isn't a git
    /// working tree, the command fails, or HEAD is detached.
    public static func gitBranch(at cwd: String) -> String? {
        guard let branch = runGit(cwd: cwd, ["rev-parse", "--abbrev-ref", "HEAD"]) else { return nil }
        return branch == "HEAD" ? nil : branch
    }

    /// Returns the top-level project root for `cwd`: the **main** working tree
    /// of the topmost git repository that is *not* itself a submodule of a
    /// parent. Two steps:
    ///   1. Climb out of any submodule nesting via
    ///      `--show-superproject-working-tree` (empty when not a submodule).
    ///   2. Collapse linked worktrees to the repo's main working tree, so every
    ///      worktree of one project groups together — `git worktree list` lists
    ///      the main working tree first.
    /// Returns nil when `cwd` isn't in a git working tree — and also when git simply
    /// wouldn't answer. Callers that write the result down must use
    /// ``projectRootResolution(at:)``, which keeps those two apart.
    public static func projectRoot(at cwd: String) -> String? {
        guard case .resolved(let root) = projectRootResolution(at: cwd) else { return nil }
        return root
    }

    /// ``projectRoot(at:)``, with the distinction between "no repository here" and
    /// "git didn't answer" preserved — see ``ProjectRootResolution``.
    public static func projectRootResolution(at cwd: String) -> ProjectRootResolution {
        GitProjectRoot.resolve(at: cwd)
    }

    /// Returns the path of the repository's **main** working tree for `dir`
    /// (the first `worktree` entry of `git worktree list --porcelain`), or nil
    /// if `dir` isn't in a git repo. For a normal checkout this is the repo
    /// root; for a linked worktree it's the primary checkout the worktree
    /// belongs to — so all worktrees of a project resolve to one root.
    public static func mainWorkingTree(at dir: String) -> String? {
        GitProjectRoot.mainWorkingTree(at: dir)
    }

    /// Runs `git -C <cwd> <args…>` and returns trimmed stdout, or nil when cwd
    /// is missing/empty, git exits non-zero, or the output is empty. It still
    /// serves the branch lookup above.
    private static func runGit(cwd: String, _ args: [String]) -> String? {
        GitProjectRoot.output(cwd: cwd, args)
    }

    /// Scans a Claude Code transcript `.jsonl` for `custom-title` lines
    /// and returns the *last* one. These lines look like:
    /// `{"type":"custom-title","customTitle":"…","sessionId":"…"}`.
    /// Returns nil if the file is missing/unreadable or has no title.
    ///
    /// Streams instead of slurping. `Data(contentsOf:)` + `String(data:encoding:)`
    /// held the entire transcript TWICE at once, and the startup backfill runs this
    /// over hundreds of files back to back: one 132 MB transcript on its own stepped
    /// the daemon's footprint by ~264 MB, and the staircase of those steps is the
    /// whole startup peak. `streamCompleteLines` bounds it to one 1 MB buffer plus a
    /// chunk, and pools its own reads. It is also stricter about encoding in the
    /// right direction — one bad byte skips its own line rather than voiding the
    /// entire file, which is what the whole-file `String(data:encoding:)` did.
    public static func transcriptCustomTitle(path: String) -> String? {
        var latest: String?
        _ = try? JSONLScanner.streamCompleteLines(at: URL(fileURLWithPath: path)) { chunk in
            if let title = lastCustomTitle(in: chunk) { latest = title }
        }
        return latest
    }

    /// The last non-empty `custom-title` among `lines`, or nil when they hold none.
    public static func lastCustomTitle(in lines: [String]) -> String? {
        var latest: String?
        for line in lines {
            // Prefilter so only candidate lines are decoded.
            guard mentionsCustomTitle(line) else { continue }
            guard let lineData = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  obj["type"] as? String == "custom-title",
                  let title = obj["customTitle"] as? String,
                  !title.isEmpty else { continue }
            latest = title
        }
        return latest
    }

    private static let customTitleMarker = Array("custom-title".utf8)

    /// Whether `line` holds the bytes `custom-title` — a byte search on the
    /// line's own UTF-8 storage (the toolkit's `containsUTF8`), not
    /// `String.contains(_:)`, whose generic substring search was ~1,750 of
    /// 1,800 sampled title-scan frames. Every transcript line passes through
    /// here, and after a daemon restart each session's first Stop scans its
    /// whole transcript, which can be 130 MB.
    public static func mentionsCustomTitle(_ line: String) -> Bool {
        line.containsUTF8(customTitleMarker)
    }

    /// How much of a transcript's tail ``transcriptLastAssistantText(path:)`` reads to
    /// begin with. The last assistant turn is the last few lines of the file; a
    /// transcript can be 130 MB, and this runs on every Stop hook, so the read is
    /// bounded rather than proportional. A record larger than this is not skipped —
    /// the reader grows the window until one whole record fits, up to `maxByteWindow`.
    private static let tailByteWindow = 512 * 1024

    /// The text of the last thing the **agent said** in the transcript at `path`:
    /// the newest main-session `assistant` record's `text` blocks, as written — a
    /// blank line between blocks, only the ends trimmed. Nil when the file is
    /// unreadable or the agent's most recent records are all tool calls with nothing
    /// to say.
    ///
    /// The text is markdown and its line breaks are part of it: a list item or a
    /// table row is only one because it starts a line. Collapsing it onto one line
    /// here left the Sessions row showing stray `-` and `|` it could no longer
    /// recognize as markup, and Show Info showing a wall of text. Fitting it on one
    /// line is the row's job.
    public static func transcriptLastAssistantText(path: String) -> String? {
        var found: String?
        visitMainConversationNewestFirst(path: path, byteWindow: tailByteWindow) { root in
            let type = root["type"] as? String
            if type == "user" {
                // A user record carrying real text is the prompt that opened this
                // turn, and scanning newest-first that makes it the floor: anything
                // older is a finished turn, and showing it as the session's live last
                // output contradicts what the user has just asked. Two user records
                // are not that floor — a tool result carries no text and sits *inside*
                // the agent's turn, and an interrupt marker ends a turn the agent may
                // already have spoken in, which is still the newest thing it said.
                let text = userText(of: root)
                return text.isEmpty || text.hasPrefix(interruptMarkerPrefix)
            }
            guard type == "assistant",
                  let message = root["message"] as? [String: Any],
                  let content = message["content"] as? [[String: Any]] else { return true }
            let text = content
                .filter { ($0["type"] as? String) == "text" }
                .compactMap { $0["text"] as? String }
                .joined(separator: "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return true }
            found = text
            return false
        }
        return found
    }

    /// How much of a transcript's tail ``transcriptInterruptTimestamp(path:)`` reads to
    /// begin with. The interrupt marker is the newest conversation record and a short
    /// line; the check runs every few seconds for every working session, so it starts
    /// far below the last-output window and only grows when the newest record doesn't
    /// fit — which, measured, is 2 transcripts in 20.
    private static let interruptByteWindow = 64 * 1024

    /// The text Claude Code writes as a user record when the user interrupts a turn —
    /// `[Request interrupted by user]`, or `… for tool use]` when a tool call was cut
    /// short. It is the only trace an interrupt leaves: no hook fires for one.
    public static let interruptMarkerPrefix = "[Request interrupted by user"

    /// When the user interrupted the agent, if the main conversation in the transcript
    /// at `path` ends that way: its newest user-or-assistant record is a user record
    /// whose text starts with ``interruptMarkerPrefix``, and this is that record's own
    /// ISO-8601 `timestamp`. Anything after the marker — a new prompt, the agent
    /// speaking again — means the session moved on.
    ///
    /// The time matters because the transcript lags the hooks: a new prompt's
    /// `UserPromptSubmit` lands before the prompt is written, so for a moment an old
    /// interrupt is still the newest record. The caller compares against the time the
    /// session's turn state was set.
    ///
    /// nil when the turn wasn't interrupted, the file is unreadable, it holds no
    /// conversation record in its tail, or the marker carries no timestamp.
    public static func transcriptInterruptTimestamp(path: String) -> String? {
        var timestamp: String?
        visitMainConversationNewestFirst(path: path, byteWindow: interruptByteWindow) { root in
            guard let type = root["type"] as? String, type == "user" || type == "assistant" else { return true }
            if type == "user", userText(of: root).hasPrefix(interruptMarkerPrefix) {
                timestamp = root["timestamp"] as? String
            }
            return false
        }
        return timestamp
    }

    /// The first text of a user record: its `content` when that is a plain string,
    /// else its first `text` block. "" when it has none (a tool result).
    private static func userText(of root: [String: Any]) -> String {
        guard let message = root["message"] as? [String: Any] else { return "" }
        if let text = message["content"] as? String { return text }
        let blocks = message["content"] as? [[String: Any]] ?? []
        return blocks.first { ($0["type"] as? String) == "text" }?["text"] as? String ?? ""
    }

    /// Calls `visit` with each parsed record of the transcript's **main conversation**
    /// in the last `byteWindow` bytes of `path`, newest first, until `visit` returns
    /// false. A dispatched subagent's records (`isSidechain`, or carrying an
    /// `agentId`) are not this session speaking and are skipped.
    ///
    /// Reads backwards from EOF over a bounded window rather than streaming the file
    /// forwards: transcripts reach 130 MB, and these readers want only the end.
    private static func visitMainConversationNewestFirst(
        path: String,
        byteWindow: Int,
        _ visit: ([String: Any]) -> Bool
    ) {
        guard let handle = FileHandle(forReadingAtPath: path) else { return }
        defer { try? handle.close() }

        let size = (try? handle.seekToEnd()) ?? 0
        guard size > 0 else { return }

        // Grow the window until it holds a whole record. A single JSONL record is
        // routinely bigger than the nominal window — measured across 20 real
        // transcripts, the largest is 295 KB against a 64 KB interrupt window — and a
        // window that lands inside one yields no records at all. Read as "nothing
        // there", that is silently wrong in both directions: the interrupt check
        // concluded "not interrupted" and left the session rendering as working
        // forever, on every tick, because nothing else clears the state. Starting
        // small and doubling keeps the common case a single short read.
        var window = byteWindow
        var lines: [Data] = []
        while true {
            lines = wholeRecords(in: handle, size: size, byteWindow: window)
            if !lines.isEmpty || UInt64(window) >= size || window >= maxByteWindow { break }
            window = min(window * 2, maxByteWindow)
        }

        for slice in lines.reversed() {
            guard let root = try? JSONSerialization.jsonObject(with: slice) as? [String: Any],
                  !(root["isSidechain"] as? Bool ?? false),
                  root["agentId"] == nil else { continue }
            if !visit(root) { return }
        }
    }

    /// The ceiling on the growth in ``visitMainConversationNewestFirst(path:byteWindow:_:)``.
    /// Past this a transcript record is pathological rather than large, and reading
    /// more would cost more than the answer is worth on a per-tick path.
    private static let maxByteWindow = 8 * 1024 * 1024

    /// The complete JSONL records in the last `byteWindow` bytes of `handle`, oldest
    /// first — empty when the window holds none.
    ///
    /// Whether the window's first line is whole is decided by the byte *before* it,
    /// not by where the window starts. `split(omittingEmptySubsequences: true)` has
    /// already dropped any empty leading fragment, so the first element is
    /// indistinguishable from a whole record by inspection — and dropping it
    /// unconditionally threw away a real record every time the window happened to
    /// begin on a boundary, emptying the list entirely for a window holding one
    /// record.
    private static func wholeRecords(in handle: FileHandle, size: UInt64, byteWindow: Int) -> [Data] {
        let window = UInt64(byteWindow)
        let start = size > window ? size - window : 0
        var firstLineIsWhole = start == 0
        if start > 0 {
            try? handle.seek(toOffset: start - 1)
            firstLineIsWhole = (try? handle.read(upToCount: 1))?.first == UInt8(ascii: "\n")
        } else {
            try? handle.seek(toOffset: 0)
        }
        guard let data = try? handle.readToEnd(), !data.isEmpty else { return [] }

        var lines = data
            .split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
            .map { Data($0) }
        if !firstLineIsWhole, !lines.isEmpty { lines.removeFirst() }
        return lines
    }

    /// Falls back to locating the transcript when the hook payload
    /// didn't include `transcript_path`. Claude stores transcripts at
    /// `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`; we just
    /// scan every subdir for the matching file.
    public static func findTranscriptPath(sessionId: String) -> String? {
        let root = (NSString(string: "~/.claude/projects").expandingTildeInPath)
        let fileManager = FileManager.default
        guard let subdirs = try? fileManager.contentsOfDirectory(atPath: root) else { return nil }
        for sub in subdirs {
            let candidate = "\(root)/\(sub)/\(sessionId).jsonl"
            if fileManager.fileExists(atPath: candidate) { return candidate }
        }
        return nil
    }
}
// swiftlint:enable identifier_name
#endif
