#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import CryptoKit
import Foundation

/// Parses a single line of a Claude Code JSONL transcript into a
/// ``ParsedTurn`` — or returns `nil` if the line isn't a shape we care
/// about (blank line, malformed JSON, non-user / non-assistant `type`,
/// or missing `sessionId`).
///
/// Mirrors claude-usage's `scanner.py:88–178` defensive style: every
/// field accessed via `.get(..., default)`, unknown fields ignored, so
/// parsing survives Claude's transcript schema drifting between versions.
public enum JSONLScanner {

    public struct ParsedTurn: Sendable, Equatable {
        public enum Kind: String, Sendable { case user, assistant }

        public let kind: Kind
        public let sessionId: String
        public let timestamp: String
        public let cwd: String
        public let gitBranch: String
        // Assistant-only fields (zero / empty for user turns)
        public let model: String
        public let messageId: String
        public let inputTokens: Int
        public let outputTokens: Int
        public let cacheReadTokens: Int
        public let cacheCreationTokens: Int
        /// The subset of ``cacheCreationTokens`` written into the **1-hour**
        /// cache, from `usage.cache_creation.ephemeral_1h_input_tokens`.
        ///
        /// This is the only place a turn's cache TTL is knowable: a 1h write
        /// bills at 2× base input against 1.25× for the 5-minute default, so a
        /// session that runs on the 1h cache is understated by 37.5% of its
        /// cache-creation cost without it. Zero on a transcript predating the
        /// breakdown, which is exactly the "all 5-minute" assumption the
        /// importer made before.
        public let cacheCreation1hTokens: Int
        /// First `tool_use` block's `name`, or empty if no tool call in this turn.
        public let toolName: String
        /// True when the turn belongs to a dispatched subagent (Task/Agent
        /// tool). Detected three ways, mirroring claude-usage's
        /// `is_subagent_record`: a root `isSidechain` flag, an `agentId` on
        /// the record (or its `data` wrapper), or the source file living
        /// under a `subagents/` directory (a property of the FILE, threaded
        /// in via `parse(_:isSubagentFile:)`).
        public let isSubagent: Bool
        /// The dispatched subagent's id (top-level or `data` wrapper), or
        /// empty for main-session turns.
        public let agentId: String
    }

    /// A session title record. Claude Code writes `custom-title` (user-set
    /// via `/tab-name` etc.) and `ai-title` (auto-generated) records into
    /// the transcript; a custom title always outranks an ai one — the
    /// importer enforces that precedence when persisting.
    public struct ParsedTitle: Sendable, Equatable {
        /// The persisted `title_source` values. `aiGenerated` is spelled out
        /// only because SwiftLint's `identifier_name` rejects a two-letter
        /// case; the raw value stored in the DB is still `"ai"`.
        public enum Source: String, Sendable {
            case custom
            case aiGenerated = "ai"
        }

        public let sessionId: String
        public let source: Source
        public let title: String
    }

    /// Subagent dispatch metadata from a parent session's record. Claude
    /// Code writes a `toolUseResult` dict on the user-side record that
    /// closes out an Agent/Task tool invocation; it carries `agentId`
    /// (matching the subagent JSONL's records) and `agentType` (the
    /// human-readable type such as 'general-purpose' or 'Explore') plus
    /// aggregate stats. Mirrors claude-usage's `extract_agent_dispatch`.
    public struct AgentDispatch: Sendable, Equatable {
        public let agentId: String
        public let agentType: String
        /// The parent session that dispatched the subagent.
        public let sessionId: String
        /// The closing record's timestamp (the only one the parent carries).
        public let timestamp: String
        public let status: String
        public let totalTokens: Int
        public let totalDurationMs: Int
        public let totalToolUseCount: Int
    }

    /// One JSONL line captured verbatim for full-transcript storage, with
    /// light metadata promoted for slicing. Unlike ``ParsedTurn``, EVERY line
    /// is represented — summaries, system entries, and even malformed lines —
    /// so the stored transcript is a faithful copy of the file, not just its
    /// user/assistant turns.
    public struct RawTranscriptLine: Sendable, Equatable {
        /// 1-based index among the file's NON-EMPTY lines at scan time
        /// (blank lines are skipped and consume no number).
        public let lineNo: Int
        public let sessionId: String
        public let entryUuid: String
        public let parentUuid: String
        public let entryType: String
        public let role: String
        public let timestamp: String
        public let isSidechain: Bool
        public let rawJSON: String
        /// Whether this line is a prompt the human typed while the agent was
        /// working (``QueuedPrompt/isQueuedPrompt(entry:)``), decided
        /// here, where the line is already parsed, rather than by parsing it a
        /// second time inside the importer's write transaction.
        public var isQueuedPrompt: Bool = false

        public init(
            lineNo: Int, sessionId: String, entryUuid: String, parentUuid: String,
            entryType: String, role: String, timestamp: String, isSidechain: Bool,
            rawJSON: String, isQueuedPrompt: Bool = false
        ) {
            self.lineNo = lineNo
            self.sessionId = sessionId
            self.entryUuid = entryUuid
            self.parentUuid = parentUuid
            self.entryType = entryType
            self.role = role
            self.timestamp = timestamp
            self.isSidechain = isSidechain
            self.rawJSON = rawJSON
            self.isQueuedPrompt = isQueuedPrompt
        }
    }

    /// Parse one JSONL line. Returns `nil` for irrelevant / malformed input.
    /// `isSubagentFile` is the file-level subagent marker (see
    /// ``isSubagentPath(_:)``) — a per-line parse can't derive it.
    public static func parse(_ line: String, isSubagentFile: Bool = false) -> ParsedTurn? {
        guard let data = line.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawType = root["type"] as? String,
              let kind = ParsedTurn.Kind(rawValue: rawType),
              let sessionId = root["sessionId"] as? String, !sessionId.isEmpty else {
            return nil
        }

        let timestamp = root["timestamp"] as? String ?? ""
        let cwd = root["cwd"] as? String ?? ""
        let gitBranch = root["gitBranch"] as? String ?? ""

        var model = ""
        var messageId = ""
        var input = 0
        var output = 0
        var cacheRead = 0
        var cacheCreate = 0
        var cacheCreate1h = 0
        var toolName = ""

        if kind == .assistant, let msg = root["message"] as? [String: Any] {
            model = msg["model"] as? String ?? ""
            messageId = msg["id"] as? String ?? ""
            if let usage = msg["usage"] as? [String: Any] {
                input       = readInt(usage["input_tokens"])
                output      = readInt(usage["output_tokens"])
                cacheRead   = readInt(usage["cache_read_input_tokens"])
                cacheCreate = readInt(usage["cache_creation_input_tokens"])
                // `cache_creation` splits that same total by TTL:
                // `{"ephemeral_5m_input_tokens": N, "ephemeral_1h_input_tokens": M}`.
                // Absent on older transcripts, in which case 0 stands for
                // "all 5-minute" — the assumption the importer already made.
                if let breakdown = usage["cache_creation"] as? [String: Any] {
                    cacheCreate1h = readInt(breakdown["ephemeral_1h_input_tokens"])
                }
            }
            if let content = msg["content"] as? [[String: Any]] {
                for item in content where (item["type"] as? String) == "tool_use" {
                    toolName = item["name"] as? String ?? ""
                    if !toolName.isEmpty { break }
                }
            }
        }

        // Subagent markers, mirroring claude-usage's `is_subagent_record`:
        // (1) root `isSidechain`, (2) an agentId on the record or its `data`
        // wrapper, (3) the source file living under `subagents/`.
        let agentId = recordAgentId(root)
        let isSubagent = isSubagentFile
            || (root["isSidechain"] as? Bool ?? false)
            || !agentId.isEmpty

        return ParsedTurn(
            kind: kind,
            sessionId: sessionId,
            timestamp: timestamp,
            cwd: cwd,
            gitBranch: gitBranch,
            model: model,
            messageId: messageId,
            inputTokens: input,
            outputTokens: output,
            cacheReadTokens: cacheRead,
            cacheCreationTokens: cacheCreate,
            cacheCreation1hTokens: cacheCreate1h,
            toolName: toolName,
            isSubagent: isSubagent,
            agentId: agentId
        )
    }

    /// Pull the subagent id off a record, if any (top-level or `data`
    /// wrapper). Mirrors claude-usage's `record_agent_id`.
    private static func recordAgentId(_ root: [String: Any]) -> String {
        if let id = root["agentId"] as? String, !id.isEmpty { return id }
        if let data = root["data"] as? [String: Any],
           let id = data["agentId"] as? String, !id.isEmpty {
            return id
        }
        return ""
    }

    /// Whether a transcript path belongs to a subagent's own JSONL — Claude
    /// Code writes one file per subagent under a `subagents/` directory.
    /// This is the third subagent marker: a property of the file, not of any
    /// single line.
    public static func isSubagentPath(_ path: String) -> Bool {
        path.replacingOccurrences(of: "\\", with: "/")
            .lowercased()
            .contains("/subagents/")
    }

    // MARK: - Auxiliary records (titles + subagent dispatches)

    /// ``parseExtras(_:)``'s prefilter needles, held as bytes so the per-line
    /// check is a `memmem` rather than a character-by-character search.
    private enum Marker {
        static let customTitle = Array("custom-title".utf8)
        static let aiTitle = Array("ai-title".utf8)
        static let toolUseResult = Array("toolUseResult".utf8)
        static let agentId = Array("agentId".utf8)
    }

    /// The non-turn records of interest on one line: a session title and/or
    /// subagent dispatch metadata.
    ///
    /// One entry point rather than two so a caller walking a transcript pays
    /// at most ONE extra `JSONSerialization` pass per line on top of
    /// ``parse(_:isSubagentFile:)`` and ``parseRawLine(_:lineNo:fileStem:)`` —
    /// and usually none: both shapes are rare, so a substring pre-check
    /// (a plain byte search) rejects the overwhelming
    /// majority of lines before any JSON is decoded.
    public static func parseExtras(_ line: String) -> (title: ParsedTitle?, dispatch: AgentDispatch?) {
        let mayBeTitle = line.containsUTF8(Marker.customTitle) || line.containsUTF8(Marker.aiTitle)
        let mayBeDispatch = line.containsUTF8(Marker.toolUseResult) && line.containsUTF8(Marker.agentId)
        guard mayBeTitle || mayBeDispatch else { return (nil, nil) }
        guard let data = line.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, nil)
        }
        return (
            mayBeTitle ? title(from: root) : nil,
            mayBeDispatch ? dispatch(from: root) : nil
        )
    }

    /// Parse one JSONL line into a title record (`custom-title` /
    /// `ai-title`). Returns `nil` for any other shape.
    public static func parseTitle(_ line: String) -> ParsedTitle? {
        parseExtras(line).title
    }

    /// Parse one JSONL line into subagent dispatch metadata. Returns `nil`
    /// unless the line is a user record carrying a `toolUseResult` with both
    /// `agentId` and `agentType`.
    public static func parseDispatch(_ line: String) -> AgentDispatch? {
        parseExtras(line).dispatch
    }

    private static func title(from root: [String: Any]) -> ParsedTitle? {
        guard let sessionId = root["sessionId"] as? String, !sessionId.isEmpty else {
            return nil
        }
        switch root["type"] as? String {
        case "custom-title":
            guard let title = root["customTitle"] as? String, !title.isEmpty else { return nil }
            return ParsedTitle(sessionId: sessionId, source: .custom, title: title)
        case "ai-title":
            guard let title = root["aiTitle"] as? String, !title.isEmpty else { return nil }
            return ParsedTitle(sessionId: sessionId, source: .aiGenerated, title: title)
        default:
            return nil
        }
    }

    private static func dispatch(from root: [String: Any]) -> AgentDispatch? {
        guard (root["type"] as? String) == "user",
              let sessionId = root["sessionId"] as? String, !sessionId.isEmpty,
              let result = root["toolUseResult"] as? [String: Any],
              let agentId = result["agentId"] as? String, !agentId.isEmpty,
              let agentType = result["agentType"] as? String, !agentType.isEmpty else {
            return nil
        }
        return AgentDispatch(
            agentId: agentId,
            agentType: agentType,
            sessionId: sessionId,
            timestamp: root["timestamp"] as? String ?? "",
            status: result["status"] as? String ?? "",
            totalTokens: readInt(result["totalTokens"]),
            totalDurationMs: readInt(result["totalDurationMs"]),
            totalToolUseCount: readInt(result["totalToolUseCount"])
        )
    }

    /// Read a JSONL file's full text. Returns `nil` when the bytes aren't
    /// valid UTF-8 — callers treat that as "no lines", matching the
    /// long-standing `parseFile` behaviour.
    ///
    /// Exposed so a caller that needs both the parsed turns AND the verbatim
    /// lines of the same file reads it from disk once and feeds both
    /// `parseTurns(in:)` and `rawLines(in:fileStem:)`.
    public static func readText(at url: URL) throws -> String? {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.readToEnd() ?? Data()
        return String(data: data, encoding: .utf8)
    }

    /// Walk a JSONL file line-by-line, yielding each parsed turn.
    /// Malformed lines are silently skipped (matching claude-usage's
    /// behaviour; an unreadable line shouldn't kill the whole import).
    public static func parseFile(at url: URL) throws -> [ParsedTurn] {
        guard let text = try readText(at: url) else { return [] }
        return parseTurns(in: text, isSubagentFile: isSubagentPath(url.path))
    }

    /// ``parseFile(at:)`` over already-read file text. `isSubagentFile` is
    /// the file-level subagent marker the text alone can't carry.
    public static func parseTurns(in text: String, isSubagentFile: Bool = false) -> [ParsedTurn] {
        var turns: [ParsedTurn] = []
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = String(rawLine)
            guard !line.isEmpty else { continue }
            if let turn = parse(line, isSubagentFile: isSubagentFile) {
                turns.append(turn)
            }
        }
        return turns
    }

    /// Walk a JSONL file line-by-line, capturing EVERY non-empty line verbatim
    /// with defensively-extracted metadata. A line that isn't valid JSON (or
    /// lacks a field) is still returned — `rawJSON` set, metadata empty — so the
    /// stored transcript never silently drops content. `sessionId` falls back to
    /// the file stem (`<sessionId>.jsonl`) when the line carries none, so summary
    /// and snapshot entries still attribute to their session.
    public static func scanRawLines(at url: URL) throws -> [RawTranscriptLine] {
        guard let text = try readText(at: url) else { return [] }
        return rawLines(in: text, fileStem: url.deletingPathExtension().lastPathComponent)
    }

    /// ``scanRawLines(at:)`` over already-read file text. `lineNo` counts only
    /// non-empty lines, in file order, starting at 1 — blank lines consume no
    /// number.
    public static func rawLines(in text: String, fileStem: String) -> [RawTranscriptLine] {
        var results: [RawTranscriptLine] = []
        var lineNo = 0
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            lineNo += 1
            results.append(parseRawLine(String(rawLine), lineNo: lineNo, fileStem: fileStem))
        }
        return results
    }

    /// Promote one verbatim line's metadata. Never fails: a line that isn't
    /// valid JSON still yields a ``RawTranscriptLine`` with `rawJSON` set and
    /// every metadata field empty, so nothing is silently dropped.
    public static func parseRawLine(
        _ line: String, lineNo: Int, fileStem: String
    ) -> RawTranscriptLine {
        var sessionId = ""
        var entryUuid = ""
        var parentUuid = ""
        var entryType = ""
        var role = ""
        var timestamp = ""
        var isSidechain = false
        var isQueuedPrompt = false

        if let lineData = line.data(using: .utf8),
           let root = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] {
            sessionId = root["sessionId"] as? String ?? ""
            entryUuid = root["uuid"] as? String ?? ""
            parentUuid = root["parentUuid"] as? String ?? ""
            entryType = root["type"] as? String ?? ""
            timestamp = root["timestamp"] as? String ?? ""
            isSidechain = root["isSidechain"] as? Bool ?? false
            if let msg = root["message"] as? [String: Any] {
                role = msg["role"] as? String ?? ""
            }
            isQueuedPrompt = QueuedPrompt.isQueuedPrompt(entry: root)
        }

        return RawTranscriptLine(
            lineNo: lineNo,
            sessionId: sessionId.isEmpty ? fileStem : sessionId,
            entryUuid: entryUuid,
            parentUuid: parentUuid,
            entryType: entryType,
            role: role,
            timestamp: timestamp,
            isSidechain: isSidechain,
            rawJSON: line,
            isQueuedPrompt: isQueuedPrompt
        )
    }

    // MARK: - Streaming reads

    /// Outcome of one ``streamCompleteLines(at:startingAtByte:linesPerChunk:bufferSize:_:)``
    /// pass.
    public struct StreamResult: Sendable, Equatable {
        /// Absolute byte offset just past the last entry handed to `body` — the
        /// resume point for the next pass. Bytes of a trailing line too torn to
        /// parse are deliberately excluded, so a still-being-written final entry
        /// is re-read whole next time rather than sealed behind the cursor.
        public let bytesConsumed: Int64
        /// Number of non-empty lines handed to the body — every one of them
        /// covered by `bytesConsumed`, so a persisted line counter stays in step
        /// with the persisted byte offset.
        public let linesEmitted: Int
        /// Non-empty lines whose bytes were not valid UTF-8 and were therefore
        /// dropped rather than handed to `body`.
        ///
        /// Their bytes ARE included in `bytesConsumed`, deliberately: leaving them
        /// unconsumed would park the cursor on a permanently-undecodable line and
        /// re-read it forever. But that makes the drop irreversible, so it has to
        /// be *countable* — silently advancing past data with no signal anywhere
        /// left `linesSeen != linesInserted` as the only trace, which reads as a
        /// dedup artefact rather than as data loss.
        public let linesSkipped: Int

        public init(bytesConsumed: Int64, linesEmitted: Int, linesSkipped: Int = 0) {
            self.bytesConsumed = bytesConsumed
            self.linesEmitted = linesEmitted
            self.linesSkipped = linesSkipped
        }
    }

    /// Stream a JSONL file's lines in bounded chunks instead of materializing the
    /// whole file. Peak memory is O(chunk + longest line), not O(file size) —
    /// transcripts here reach 180 MB+, and the previous whole-file read held the
    /// text, the parsed turns, and a second verbatim copy of every line live at
    /// once.
    ///
    /// Only COMPLETE lines advance `bytesConsumed`. A trailing line without a
    /// newline counts as complete when it parses as JSON — a file whose last entry
    /// simply lacks its newline isn't lost, and isn't re-read forever either. A
    /// trailing fragment that ISN'T valid JSON is a torn or in-flight write: it is
    /// dropped and its bytes left unconsumed, so the next pass re-reads it whole.
    ///
    /// Splitting on the `\n` byte is safe for UTF-8: 0x0A can never appear inside a
    /// multi-byte sequence. A line whose bytes aren't valid UTF-8 is skipped
    /// individually rather than voiding the entire file (which is what the
    /// whole-file `String(data:encoding:)` read did) — and counted into
    /// ``StreamResult/linesSkipped``, because that skip permanently consumes bytes.
    ///
    /// Each read iteration runs inside its own `autoreleasepool`, and that is what
    /// makes the O(chunk) bound real rather than nominal. `FileHandle.read(upToCount:)`
    /// hands back an AUTORELEASED buffer: on a synchronous caller — which every
    /// importer here is — no pool drains until the whole run unwinds, so without this
    /// the buffers pile up one per `bufferSize` and the footprint tracks file size
    /// exactly as if the file had been read whole. Measured: a 48 MB file cost 48 MB
    /// per pass even when the body did nothing but count lines.
    @discardableResult
    public static func streamCompleteLines(
        at url: URL,
        startingAtByte startOffset: Int64 = 0,
        linesPerChunk: Int = 500,
        bufferSize: Int = 1 << 20,
        _ body: ([String]) throws -> Void
    ) throws -> StreamResult {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        if startOffset > 0 { try handle.seek(toOffset: UInt64(startOffset)) }

        var consumed = startOffset
        var emitted = 0
        var skipped = 0
        var pending: [UInt8] = []
        /// How much of `pending` has already been examined for a newline.
        ///
        /// Without this the scan restarted at 0 on every read, so bytes that had
        /// already been proven newline-free were re-tested once per subsequent
        /// 1 MB read. For a line spanning N buffers that is O(N²) byte compares —
        /// on a multi-megabyte line (a pasted image, a large tool result) the pass
        /// stalls while `bytesRead` still reports normal progress, which makes it
        /// look like slow I/O rather than a scan defect.
        var scanned = 0
        var chunk: [String] = []
        chunk.reserveCapacity(linesPerChunk)

        func flushChunk() throws {
            guard !chunk.isEmpty else { return }
            try body(chunk)
            chunk.removeAll(keepingCapacity: true)
        }

        var reachedEnd = false
        while !reachedEnd {
            // The pool must enclose the read itself, not just the parsing: the
            // buffer `read(upToCount:)` returns is what accumulates without it.
            try autoreleasepool {
                guard let data = try handle.read(upToCount: bufferSize), !data.isEmpty else {
                    reachedEnd = true
                    return
                }
                pending.append(contentsOf: data)
                var lineStart = 0
                // Resume at `scanned`, never at 0 — see the declaration above.
                var index = scanned
                while index < pending.count {
                    defer { index += 1 }
                    guard pending[index] == 0x0A else { continue }
                    let lineBytes = pending[lineStart..<index]
                    consumed += Int64(index - lineStart + 1)
                    lineStart = index + 1
                    guard !lineBytes.isEmpty else { continue }
                    guard let text = String(bytes: lineBytes, encoding: .utf8) else {
                        skipped += 1
                        continue
                    }
                    chunk.append(text)
                    emitted += 1
                    if chunk.count >= linesPerChunk { try flushChunk() }
                }
                if lineStart > 0 { pending.removeFirst(lineStart) }
                // Everything still buffered has now been tested for a newline.
                scanned = pending.count
            }
        }

        // Trailing bytes with no newline. Claude appends to a live transcript, so
        // these are either the last entry of a finished file (no trailing newline)
        // or a half-written line. Parsing decides: a JSON *object* is only valid
        // once its braces balance, which happens at its final `}` — so a truncated
        // write can't parse, and anything that does parse is a whole entry whose
        // only missing byte is the newline. Emit and consume it; leave a partial
        // line unconsumed so the next pass re-reads it from the same offset.
        //
        // Pooled, and parsed from ONE `Data` rather than a separate `Data(pending)`
        // beside a `String(bytes:)`. The loop's pool ended at its closing brace, so
        // everything here — the copy, the decoded string, and the whole object graph
        // `JSONSerialization` builds on top — was autoreleased into whatever pool the
        // caller happened to have. For the synchronous startup backfill that is the
        // outermost one, which is the exact double-hold this rewrite removed.
        autoreleasepool {
            guard !pending.isEmpty else { return }
            let tailData = Data(pending)
            guard let tail = String(data: tailData, encoding: .utf8),
                  (try? JSONSerialization.jsonObject(with: tailData)) != nil else { return }
            chunk.append(tail)
            emitted += 1
            consumed += Int64(pending.count)
        }
        try flushChunk()

        return StreamResult(bytesConsumed: consumed, linesEmitted: emitted, linesSkipped: skipped)
    }

    /// Cheap identity fingerprint for a transcript file: SHA-256 over TWO
    /// `byteCount`-sized windows of the region `[0, limit)` — the first bytes of
    /// the file, and the last bytes before `limit`. Paired with the file's inode
    /// and size it decides whether a stored byte cursor may be resumed (pure
    /// append) or must be discarded and the file re-read from zero (compacted /
    /// rewritten / replaced).
    ///
    /// `limit` is what keeps that decision stable. Callers pass the byte offset the
    /// fingerprint belongs to, so both windows sit INSIDE the region already
    /// consumed — bytes an append can never touch. Hashing a fixed 4 KB of
    /// any file shorter than that would fold the file's tail into the fingerprint,
    /// and every append to a young transcript would invalidate the cursor it just
    /// wrote, re-reading the whole file forever.
    ///
    /// The window at `limit` is what makes the check mean "the file is unchanged
    /// where I read it" rather than "the file still starts the same way". A head
    /// window alone attests to 4 KB out of a cursor that is routinely megabytes
    /// in: a transcript rewritten below the cursor while keeping its opening
    /// lines — a compaction that preserves the session header, an edit-in-place,
    /// a restore over the same inode at the same length — passes a head-only
    /// check, and the importer then resumes at an offset that now points into
    /// different content, silently skipping everything before it. Reading a
    /// second 4 KB costs one extra `seek`+`read` per file.
    ///
    /// Changing the hashed region invalidates every cursor stored by an earlier
    /// build. That needs no migration: a mismatched fingerprint is already the
    /// "re-read from zero" path, so the first pass after an upgrade re-imports
    /// (deduplicating as it goes) and re-stamps, and every pass after it resumes.
    ///
    /// Pooled here rather than at the call sites: `FileHandle` and the buffer
    /// `read(upToCount:)` returns are both autoreleased, and the importer calls this
    /// up to twice per file inside a synchronous loop over every transcript. Owning
    /// the pool means no caller has to know that.
    public static func resumeFingerprint(
        at url: URL, upTo limit: Int64, byteCount: Int = 4096
    ) throws -> String {
        let wanted = Int(min(limit, Int64(byteCount)))
        guard wanted > 0 else { return SHA256.hash(data: Data()).hexString }
        return try autoreleasepool {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            var hasher = SHA256()
            hasher.update(data: try handle.read(upToCount: wanted) ?? Data())
            // The window ending at `limit`. When the file is shorter than one
            // window the two coincide and the same bytes are hashed twice —
            // harmless, and cheaper than branching on it.
            try handle.seek(toOffset: UInt64(max(0, limit - Int64(wanted))))
            hasher.update(data: try handle.read(upToCount: wanted) ?? Data())
            return hasher.finalize().hexString
        }
    }

    /// Recursively glob for all `.jsonl` files under a directory. Sorted
    /// for deterministic scan order, matching claude-usage.
    public static func discoverFiles(under root: URL) -> [URL] {
        discoverFilesWithModificationDates(under: root).map(\.url)
    }

    /// Every `.jsonl` file under a directory, paired with its modification date.
    ///
    /// The mtime is read here, during the directory walk, rather than by a
    /// follow-up `attributesOfItem` pass over the result — which is what the
    /// importer used to do. Both halves of that matter on a real machine, where
    /// this tree holds ~8,500 transcripts and a periodic import re-walks it
    /// every 300 s to process a batch of 50:
    ///
    /// - The enumerator prefetches `.contentModificationDateKey` as part of the
    ///   directory read it is already performing, instead of one `stat` per file.
    /// - `attributesOfItem` returns an *autoreleased* dictionary of autoreleased
    ///   values; accumulating one per file inside a synchronous loop with no
    ///   suspension point means none of them drain until the loop unwinds. That
    ///   is the same shape as the JSONL-importer and startup-backfill spikes.
    ///   The pool below covers every enumerated entry — including the
    ///   directories and non-`.jsonl` files the filter discards, which are
    ///   autoreleased by the enumerator whether we keep them or not.
    public static func discoverFilesWithModificationDates(
        under root: URL
    ) -> [(url: URL, modified: Date)] {
        let fileManager = FileManager.default
        var results: [(url: URL, modified: Date)] = []
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var finished = false
        while !finished {
            autoreleasepool {
                guard let url = enumerator.nextObject() as? URL else {
                    finished = true
                    return
                }
                guard url.pathExtension == "jsonl" else { return }
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                results.append((url, modified))
            }
        }
        return results.sorted { $0.url.path < $1.url.path }
    }

    // MARK: - Internals

    /// Permissive integer reader: tolerates Int, Int64, Double, NSNumber,
    /// and JSON null (returns 0). Claude's serializer occasionally emits
    /// a null for zero-valued token counts.
    private static func readInt(_ any: Any?) -> Int {
        if any == nil { return 0 }
        if let int = any as? Int { return int }
        if let int64 = any as? Int64 { return Int(int64) }
        if let double = any as? Double { return Int(double) }
        if let number = any as? NSNumber { return number.intValue }
        return 0
    }
}
#endif
