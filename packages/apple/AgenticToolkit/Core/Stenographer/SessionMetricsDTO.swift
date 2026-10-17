import Foundation

/// Per-session aggregate metrics sourced from Claude Code's JSONL
/// transcripts. Populated by the `steno import` CLI command; not
/// maintained in real-time by hook ingestion (hooks don't carry token
/// data).
public struct SessionMetricsDTO: Codable, Sendable {
    public let sessionId: String
    public let totalInputTokens: Int
    public let totalOutputTokens: Int
    public let cacheReadTokens: Int
    public let cacheCreationTokens: Int
    public let totalCostUsd: Double
    public let turnCount: Int
    /// The most recent model seen for this session (last assistant turn's model).
    public let model: String
    public let firstTurnAt: String
    public let lastTurnAt: String
    public let updatedAt: String

    public init(
        sessionId: String,
        totalInputTokens: Int,
        totalOutputTokens: Int,
        cacheReadTokens: Int,
        cacheCreationTokens: Int,
        totalCostUsd: Double,
        turnCount: Int,
        model: String,
        firstTurnAt: String,
        lastTurnAt: String,
        updatedAt: String
    ) {
        self.sessionId = sessionId
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.totalCostUsd = totalCostUsd
        self.turnCount = turnCount
        self.model = model
        self.firstTurnAt = firstTurnAt
        self.lastTurnAt = lastTurnAt
        self.updatedAt = updatedAt
    }
}

/// What `steno import` asks for — the body of both `POST /import` and the XPC
/// `importTranscripts`. snake_case on the wire, `since` as ISO-8601; every field
/// optional, so an empty body is a full import from the default directory.
public struct ImportRequestDTO: Codable, Sendable {
    public let sourceDirectory: String?
    public let since: Date?
    public let dryRun: Bool?

    public init(sourceDirectory: String? = nil, since: Date? = nil, dryRun: Bool? = nil) {
        self.sourceDirectory = sourceDirectory
        self.since = since
        self.dryRun = dryRun
    }
}

/// How much of the transcripts on disk the JSONL byte cursors already cover.
public struct TranscriptCursorStatsDTO: Codable, Sendable {
    /// Files with a stored cursor.
    public let files: Int
    /// Bytes already ingested across those files — what the next pass will skip.
    public let bytesCovered: Int64
    /// Size of those same files as recorded at the START of their last scan, which
    /// is why it can read slightly BELOW `bytesCovered`: Claude appends to live
    /// transcripts, so a file that grew while being read ends up with more bytes
    /// consumed than the size stat taken moments earlier. Treat the gap as a rough
    /// "still to read", not an exact remainder.
    public let bytesOnDisk: Int64
    public let oldestUpdatedAt: String?
    public let newestUpdatedAt: String?

    public init(
        files: Int,
        bytesCovered: Int64,
        bytesOnDisk: Int64,
        oldestUpdatedAt: String?,
        newestUpdatedAt: String?
    ) {
        self.files = files
        self.bytesCovered = bytesCovered
        self.bytesOnDisk = bytesOnDisk
        self.oldestUpdatedAt = oldestUpdatedAt
        self.newestUpdatedAt = newestUpdatedAt
    }
}

/// Summary of a completed `steno import` run.
public struct ImportSummary: Codable, Sendable {
    public let filesScanned: Int
    public let turnsSeen: Int
    public let eventsInserted: Int
    public let eventsSkipped: Int
    public let sessionsCreated: Int
    public let sessionsTouched: Int
    public let metricsUpserted: Int
    /// Total transcript JSONL lines seen across scanned files this run
    /// (every line, not just user/assistant turns). Counted even in dryRun.
    public let linesSeen: Int
    /// Transcript lines actually inserted into `transcript_lines` this run;
    /// re-runs of already-captured files insert 0 (session_id+hash dedup).
    public let linesInserted: Int
    /// Non-empty lines dropped because their bytes were not valid UTF-8.
    ///
    /// These are *permanently* dropped: the byte cursor advances past them (the
    /// alternative is parking on an undecodable line forever), so nothing will
    /// re-read them. A non-zero value here is the only signal that a transcript
    /// lost content, which is why it is a counter of its own rather than an
    /// inference from `linesSeen - linesInserted` — that gap is normally just dedup.
    public let linesSkipped: Int
    /// Bytes actually read off disk this run.
    public let bytesRead: Int64
    /// Bytes the per-file byte cursors let this run skip — the head of every
    /// scanned file that was already ingested. Read next to `bytesRead` it is the
    /// whole point of the cursor: a healthy steady state reads kilobytes and skips
    /// gigabytes. If this is 0 while files are being scanned, cursors are being
    /// rejected and every pass is re-reading transcripts from byte zero.
    public let bytesSkipped: Int64
    public let errors: [String]
    /// True when the importer hit `Options.maxFiles` and stopped early —
    /// callers (e.g. JSONLImportTask) re-enqueue themselves until this is
    /// false. Defaults to false for source compatibility with the CLI
    /// `steno import` path, which runs unbounded.
    public let hasMore: Bool
    /// ISO 8601 mtime of the latest file processed in this run. The
    /// chunked task path persists this as the next `since` cutoff so the
    /// next chunk skips files already handled. Nil when nothing was
    /// processed.
    public let cutoffISO: String?

    public init(
        filesScanned: Int = 0,
        turnsSeen: Int = 0,
        eventsInserted: Int = 0,
        eventsSkipped: Int = 0,
        sessionsCreated: Int = 0,
        sessionsTouched: Int = 0,
        metricsUpserted: Int = 0,
        linesSeen: Int = 0,
        linesInserted: Int = 0,
        linesSkipped: Int = 0,
        bytesRead: Int64 = 0,
        bytesSkipped: Int64 = 0,
        errors: [String] = [],
        hasMore: Bool = false,
        cutoffISO: String? = nil
    ) {
        self.filesScanned = filesScanned
        self.turnsSeen = turnsSeen
        self.eventsInserted = eventsInserted
        self.eventsSkipped = eventsSkipped
        self.sessionsCreated = sessionsCreated
        self.sessionsTouched = sessionsTouched
        self.metricsUpserted = metricsUpserted
        self.linesSeen = linesSeen
        self.linesInserted = linesInserted
        self.linesSkipped = linesSkipped
        self.bytesRead = bytesRead
        self.bytesSkipped = bytesSkipped
        self.errors = errors
        self.hasMore = hasMore
        self.cutoffISO = cutoffISO
    }

    private enum CodingKeys: String, CodingKey {
        case filesScanned, turnsSeen, eventsInserted, eventsSkipped
        case sessionsCreated, sessionsTouched, metricsUpserted, errors
        case linesSeen, linesInserted, linesSkipped, bytesRead, bytesSkipped
        case hasMore, cutoffISO
    }

    /// Tolerant decode: this DTO is the daemon→CLI wire contract for
    /// `POST /import`, so the two binaries can be at different versions.
    /// Every field decodes-if-present and falls back to its default, so an
    /// older peer that omits a newer field (e.g. `hasMore`/`cutoffISO`)
    /// yields a usable summary instead of a `keyNotFound` crash.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.filesScanned = try container.decodeIfPresent(Int.self, forKey: .filesScanned) ?? 0
        self.turnsSeen = try container.decodeIfPresent(Int.self, forKey: .turnsSeen) ?? 0
        self.eventsInserted = try container.decodeIfPresent(Int.self, forKey: .eventsInserted) ?? 0
        self.eventsSkipped = try container.decodeIfPresent(Int.self, forKey: .eventsSkipped) ?? 0
        self.sessionsCreated = try container.decodeIfPresent(Int.self, forKey: .sessionsCreated) ?? 0
        self.sessionsTouched = try container.decodeIfPresent(Int.self, forKey: .sessionsTouched) ?? 0
        self.metricsUpserted = try container.decodeIfPresent(Int.self, forKey: .metricsUpserted) ?? 0
        self.linesSeen = try container.decodeIfPresent(Int.self, forKey: .linesSeen) ?? 0
        self.linesInserted = try container.decodeIfPresent(Int.self, forKey: .linesInserted) ?? 0
        self.linesSkipped = try container.decodeIfPresent(Int.self, forKey: .linesSkipped) ?? 0
        self.bytesRead = try container.decodeIfPresent(Int64.self, forKey: .bytesRead) ?? 0
        self.bytesSkipped = try container.decodeIfPresent(Int64.self, forKey: .bytesSkipped) ?? 0
        self.errors = try container.decodeIfPresent([String].self, forKey: .errors) ?? []
        self.hasMore = try container.decodeIfPresent(Bool.self, forKey: .hasMore) ?? false
        self.cutoffISO = try container.decodeIfPresent(String.self, forKey: .cutoffISO)
    }
}
