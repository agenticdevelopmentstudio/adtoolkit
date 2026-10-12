import Foundation

// MARK: - DTOs

/// Serializable session data transferred over XPC and HTTP.
public struct SessionDTO: Codable, Sendable {
    public let sessionId: String
    public let cwd: String
    public let model: String
    public let startedAt: String
    public let lastActivityAt: String
    public let lastTool: String
    public let status: String
    public let gitBranch: String
    public let summary: String
    public let pid: Int
    public let termProgram: String
    /// The top-level (non-submodule) git project root for `cwd`. Empty until
    /// enrichment resolves it, or when `cwd` isn't in a git working tree.
    public let projectRoot: String
    /// The terminal's `TERM_SESSION_ID` (e.g. iTerm's "w0t1p0:UUID"), so the app
    /// can jump to the exact tab/pane on click. Empty for terminals that don't set it.
    public let termSessionId: String
    /// The session's Claude Code title (`/tab-name`, or Claude's own auto-title),
    /// from the transcript's `custom-title` / `ai-title` records. Empty until the
    /// session is named. This is the *name*, never the AI summary — they lived in
    /// one column once, and the Sessions window showed the name where the summary
    /// belonged for every session that had one.
    public let transcriptTitle: String
    /// The agent's most recent prose reply, tailed from the transcript when the
    /// Stop hook fires. Empty for a session that has not answered yet.
    public let lastOutput: String
    /// The last hook event seen for the session (`PreToolUse`, `Notification`, …).
    /// The Sessions window reads it as the session's activity: working, idle, or
    /// waiting on the user.
    public let lastEventType: String
    /// When `summary` was written (`datetime()` format), empty when never.
    public let summaryAt: String
    public let eventCount: Int
    /// Whether a **subagent** of this session was doing something just now.
    ///
    /// `lastEventType` deliberately cannot say — it tracks the *main agent's*
    /// turn, and every hook a subagent fires is refused so that a background
    /// agent's `SubagentStop` landing after the main `Stop` cannot leave a
    /// finished session spinning. That leaves the honest gap this closes: a
    /// session whose main agent handed back while a background subagent is
    /// still working is doing work, and reads as working.
    ///
    /// It is a verdict, not a timestamp: the daemon owns the freshness window
    /// (see `DatabaseManager.fetchSessions`), so no client re-derives it.
    public let subagentWorking: Bool

    public init(
        sessionId: String,
        cwd: String,
        model: String,
        startedAt: String,
        lastActivityAt: String,
        lastTool: String,
        status: String,
        gitBranch: String,
        summary: String,
        pid: Int,
        termProgram: String,
        projectRoot: String = "",
        termSessionId: String = "",
        transcriptTitle: String = "",
        lastOutput: String = "",
        lastEventType: String = "",
        summaryAt: String = "",
        eventCount: Int,
        subagentWorking: Bool = false
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.model = model
        self.startedAt = startedAt
        self.lastActivityAt = lastActivityAt
        self.lastTool = lastTool
        self.status = status
        self.gitBranch = gitBranch
        self.summary = summary
        self.pid = pid
        self.termProgram = termProgram
        self.projectRoot = projectRoot
        self.termSessionId = termSessionId
        self.transcriptTitle = transcriptTitle
        self.lastOutput = lastOutput
        self.lastEventType = lastEventType
        self.summaryAt = summaryAt
        self.eventCount = eventCount
        self.subagentWorking = subagentWorking
    }

    /// Hand-rolled so `project_root` (added later) is optional on decode: a payload
    /// from an older daemon that predates the field still decodes, defaulting it to
    /// "" instead of throwing. All other keys are required as before. Encoding stays
    /// synthesized. (App, daemon, and CLI ship together, so this only matters during
    /// the brief window an old daemon is still serving a freshly-updated client.)
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        cwd = try container.decode(String.self, forKey: .cwd)
        model = try container.decode(String.self, forKey: .model)
        startedAt = try container.decode(String.self, forKey: .startedAt)
        lastActivityAt = try container.decode(String.self, forKey: .lastActivityAt)
        lastTool = try container.decode(String.self, forKey: .lastTool)
        status = try container.decode(String.self, forKey: .status)
        gitBranch = try container.decode(String.self, forKey: .gitBranch)
        summary = try container.decode(String.self, forKey: .summary)
        pid = try container.decode(Int.self, forKey: .pid)
        termProgram = try container.decode(String.self, forKey: .termProgram)
        projectRoot = try container.decodeIfPresent(String.self, forKey: .projectRoot) ?? ""
        termSessionId = try container.decodeIfPresent(String.self, forKey: .termSessionId) ?? ""
        transcriptTitle = try container.decodeIfPresent(String.self, forKey: .transcriptTitle) ?? ""
        lastOutput = try container.decodeIfPresent(String.self, forKey: .lastOutput) ?? ""
        lastEventType = try container.decodeIfPresent(String.self, forKey: .lastEventType) ?? ""
        summaryAt = try container.decodeIfPresent(String.self, forKey: .summaryAt) ?? ""
        eventCount = try container.decode(Int.self, forKey: .eventCount)
        subagentWorking = try container.decodeIfPresent(Bool.self, forKey: .subagentWorking) ?? false
    }
}

/// Serializable event data transferred over XPC and HTTP.
public struct SessionEventDTO: Codable, Sendable {
    public let id: Int
    public let sessionId: String
    public let eventType: String
    public let timestamp: String
    public let cwd: String
    public let detail: String
    public let gitBranch: String

    public init(
        id: Int,
        sessionId: String,
        eventType: String,
        timestamp: String,
        cwd: String,
        detail: String,
        gitBranch: String = ""
    ) {
        self.id = id
        self.sessionId = sessionId
        self.eventType = eventType
        self.timestamp = timestamp
        self.cwd = cwd
        self.detail = detail
        self.gitBranch = gitBranch
    }
}

/// One session and its newest events — `GET /sessions/:id` and the XPC
/// `getSessionDetail`, what `steno session` prints.
public struct SessionDetailDTO: Codable, Sendable {
    public let session: SessionDTO
    public let recentEvents: [SessionEventDTO]

    public init(session: SessionDTO, recentEvents: [SessionEventDTO]) {
        self.session = session
        self.recentEvents = recentEvents
    }
}

/// Daemon health information. `/health` is a pure liveness probe — it
/// never touches the database, so an in-flight retention/import does not
/// affect its responsiveness. Use `/insights/summary` for DB-backed counts.
public struct HealthDTO: Codable, Sendable {
    public let status: String
    public let uptime: TimeInterval
    public let version: String
    /// Always nil from `/health` (DB-free). Retained for source compatibility
    /// — callers that want counts should use `/insights/summary` instead.
    public let activeSessionCount: Int?
    public let totalEventCount: Int?
    /// Milliseconds from process start to HTTP-ready. Nil until first startup completes.
    public let startupDurationMs: Int?
    /// Daemon `phys_footprint` in MB — the figure macOS holds the process to and
    /// Activity Monitor shows. Nil if the kernel declined the reading.
    ///
    /// **`Mb`, not `MB`, and that casing is load-bearing.** Every client decodes
    /// with `.convertFromSnakeCase`, which rebuilds `memory_footprint_mb` as
    /// `memoryFootprintMb`. A trailing all-caps acronym does not round-trip:
    /// `.convertToSnakeCase` still emits `memory_footprint_mb`, but the
    /// synthesized `CodingKey` would read `memoryFootprintMB` and never match — and
    /// because these are `Optional`, the synthesized init uses `decodeIfPresent`
    /// and returns nil instead of throwing. The wire format is unchanged; only the
    /// Swift spelling is, and it now matches `startupDurationMs` above.
    public let memoryFootprintMb: Int?
    /// Highest footprint since this process started. It never falls, so a big peak
    /// beside a small current footprint means a transient spike, not a leak —
    /// only a restart re-baselines it. See the casing note above.
    public let memoryPeakMb: Int?
    /// Why Claude Code's status line is missing Stenographer's part: the
    /// claudehelpers dispatcher's record of our renderer's last failure, which
    /// it clears on the next success. Nil while the renderer works. A file
    /// read, never a DB read, so `/health` stays DB-free.
    public let statusLineError: String?

    public init(
        status: String,
        uptime: TimeInterval,
        version: String,
        activeSessionCount: Int? = nil,
        totalEventCount: Int? = nil,
        startupDurationMs: Int? = nil,
        memoryFootprintMb: Int? = nil,
        memoryPeakMb: Int? = nil,
        statusLineError: String? = nil
    ) {
        self.statusLineError = statusLineError
        self.status = status
        self.uptime = uptime
        self.version = version
        self.activeSessionCount = activeSessionCount
        self.totalEventCount = totalEventCount
        self.startupDurationMs = startupDurationMs
        self.memoryFootprintMb = memoryFootprintMb
        self.memoryPeakMb = memoryPeakMb
    }
}
