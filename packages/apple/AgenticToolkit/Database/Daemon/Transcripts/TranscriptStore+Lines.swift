#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import CryptoKit
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Transcript lines (full verbatim JSONL storage)

    /// Insert the verbatim JSONL lines of one transcript file into
    /// `transcript_lines`, deduplicated by `(session_id, line_hash)` via
    /// `INSERT OR IGNORE`. All lines for the file go in ONE transaction (a
    /// single `write`), matching `insertTranscriptTurn`'s pattern. Returns
    /// the number of rows actually inserted (dedup hits excluded), so re-scans
    /// of a grown or already-imported file return the count of only the new
    /// lines. `line_hash` is SHA-256 of the raw line text.
    @discardableResult
    public func insertTranscriptLines(_ lines: [JSONLScanner.RawTranscriptLine], filePath: String) throws -> Int {
        guard !lines.isEmpty else { return 0 }
        return try write { database in
            var inserted = 0
            for line in lines {
                let hash = SHA256.hash(data: Data(line.rawJSON.utf8)).hexString
                try execute("""
                    INSERT OR IGNORE INTO transcript_lines (
                        session_id, file_path, line_no, entry_uuid, parent_uuid,
                        entry_type, role, timestamp, is_sidechain, raw_json, line_hash
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, params: [
                    line.sessionId, filePath, line.lineNo, line.entryUuid, line.parentUuid,
                    line.entryType, line.role, line.timestamp, line.isSidechain ? 1 : 0,
                    line.rawJSON, hash
                ])
                let added = database.changesCount
                inserted += added
                let lineId = database.lastInsertedRowID
                if added > 0, line.isQueuedPrompt {
                    try recordQueuedPrompt(lineId: lineId, sessionId: line.sessionId, timestamp: line.timestamp)
                }
            }
            return inserted
        }
    }

    /// Notes that transcript line `lineId` is a prompt typed while the agent was
    /// working. `INSERT OR IGNORE`, so the importer and the backfill can both
    /// record the same line.
    private func recordQueuedPrompt(lineId: Int64, sessionId: String, timestamp: String) throws {
        try execute("""
            INSERT OR IGNORE INTO conversation_queued_prompts (line_id, session_id, timestamp)
            VALUES (?, ?, ?)
        """, params: [lineId, sessionId, timestamp])
    }

    /// Records the prompts typed mid-turn among one span of already-stored
    /// transcript lines in `conversation_queued_prompts`. Returns whether any
    /// lines are left to look at.
    ///
    /// Lines this daemon imports are recorded as they are stored, so the backfill
    /// covers what was stored without that: everything before migration044, and
    /// anything an older daemon stored after it (two branches' daemons can take
    /// turns on one database). It first walks DOWN from the highest line id seen
    /// on its first run, so the recent conversations, the ones the window shows
    /// first, are done in the first few batches; then it walks UP from that same
    /// point to the current top, and keeps following the top on later runs. Both
    /// positions are kept in `settings`, so a restart carries on where it stopped,
    /// and the walk is finished exactly when both positions have run out, so there
    /// is no separate "done" flag to go stale.
    ///
    /// Each batch reads only the attachment rows in `idSpan` ids, found through
    /// `idx_transcript_lines_type`, and parses only those that contain
    /// ``QueuedPrompt/queuedPromptNeedle``. It runs under the
    /// maintenance read deadline: a span the serving deadline cut short would be
    /// retried from the same place forever.
    public func backfillQueuedPromptsBatch(idSpan: Int = 50_000) -> Bool {
        let top: Int
        let below: Int
        let above: Int
        do {
            var maxId = 0
            try query("SELECT COALESCE(MAX(id), 0) FROM transcript_lines") { row in
                maxId = self.int(row, 0)
            }
            top = maxId + 1
            below = try setting(for: Self.queuedPromptBackfillBelowKey).flatMap { Int($0) } ?? top
            above = try setting(for: Self.queuedPromptBackfillAboveKey).flatMap { Int($0) } ?? top
        } catch {
            // Nothing is written on a failed read, so the next run starts over
            // from the same positions rather than taking the failure for "done".
            logger.error("queued-prompt backfill: \(error.localizedDescription, privacy: .public)")
            return false
        }

        let lower: Int
        let upper: Int
        var nextBelow = below
        var nextAbove = above
        if below > 1 {
            lower = max(below - idSpan, 1)
            upper = below
            nextBelow = lower
        } else if above < top {
            lower = above
            upper = min(above + idSpan, top)
            nextAbove = upper
        } else {
            return false
        }

        var found: [(id: Int64, sessionId: String, timestamp: String)] = []
        do {
            try query("""
                SELECT id, session_id, timestamp, raw_json
                FROM transcript_lines INDEXED BY idx_transcript_lines_type
                WHERE entry_type = 'attachment' AND id >= ? AND id < ?
                  AND instr(raw_json, ?) > 0
            """, params: [lower, upper, QueuedPrompt.queuedPromptNeedle],
               deadline: DaemonDatabase.maintenanceReadDeadline) { row in
                guard QueuedPrompt.isQueuedPrompt(rawJSON: self.string(row, 3)) else { return }
                found.append((id: self.int64(row, 0), sessionId: self.string(row, 1), timestamp: self.string(row, 2)))
            }
            try transaction {
                for prompt in found {
                    try recordQueuedPrompt(lineId: prompt.id, sessionId: prompt.sessionId, timestamp: prompt.timestamp)
                }
                try setSetting(Self.queuedPromptBackfillBelowKey, String(nextBelow))
                try setSetting(Self.queuedPromptBackfillAboveKey, String(nextAbove))
            }
        } catch {
            // The positions only move with the rows they cover, so a failed span
            // is retried on the next run from the same place.
            logger.error("queued-prompt backfill: \(error.localizedDescription, privacy: .public)")
            return false
        }
        return true
    }

    private static let queuedPromptBackfillBelowKey = "queued_prompt_backfill_below"
    private static let queuedPromptBackfillAboveKey = "queued_prompt_backfill_above"

    /// What the imported transcript lines can say about a session's custom title.
    ///
    /// The three cases exist because "no title" and "can't tell yet" must not be
    /// confused: the first is authoritative and lets the caller stop looking, the
    /// second means the importer simply hasn't reached this session and the file
    /// is still the only source of truth.
    public enum ImportedTitle: Equatable {
        /// The most recent `custom-title` line the importer has stored.
        case found(String)
        /// Lines exist for this session and none is a `custom-title` — an
        /// authoritative "there is no title", so re-reading the file adds nothing.
        case absent
        /// No lines stored for this session at all; the DB cannot answer.
        case notImported
    }

    /// The latest `custom-title` for a session, read from the already-imported
    /// `transcript_lines` instead of the transcript file.
    ///
    /// The startup enrichment pass used to answer this by streaming the whole
    /// `.jsonl` — and the sessions that reach it are the *worst* case for that:
    /// they are the live ones, which are never stamped (see
    /// `stampSessionEnrichment`), so the same files were re-read on every launch,
    /// and being live they are also the largest (163 MB / 90 MB / 60 MB here).
    /// Each line became a short-lived Swift `String`, and the resulting
    /// `MALLOC_SMALL` churn — not any retained object — was 40 MB of the daemon's
    /// 87 MB startup peak (measured A/B on one build: 87 MB with the pass, 47 MB
    /// with it skipped, while the live heap stayed ~4 MB in both).
    ///
    /// Reading it back out of the DB is the same answer for a fraction of the
    /// memory: the importer already stored every one of those lines, so the scan
    /// was re-deriving what the daemon had written down.
    public func latestCustomTitle(sessionId: String) throws -> ImportedTitle {
        try read { _ in
            var title: String?
            // Ordered by `line_no` so "latest" matches the file's last occurrence,
            // which is what the whole-file scan returned.
            //
            // Every `custom-title` line, not `LIMIT 1`: the file scan takes the last
            // line that *parses to a non-empty title*, skipping the rest, so stopping
            // at the last line full stop disagrees with it whenever the final one is
            // empty or malformed — the DB path then reports `.absent`, which the
            // enricher trusts as authoritative and writes no summary at all, dropping
            // a title the file scan would have found. Sessions carry a handful of
            // these lines at most (one per rename), so reading them all is cheap.
            try query("""
                SELECT raw_json FROM transcript_lines
                WHERE session_id = ? AND entry_type = 'custom-title'
                ORDER BY line_no DESC
            """, params: [sessionId]) { row in
                guard title == nil,
                      let raw = optionalString(row, 0),
                      let parsed = Self.customTitle(fromRawJSON: raw),
                      !parsed.isEmpty else { return }
                title = parsed
            }
            if let title {
                return .found(title)
            }
            // Distinguish "swept and empty" from "not imported yet": only the
            // former justifies not falling back to the file.
            var anyLine = false
            try query("SELECT 1 FROM transcript_lines WHERE session_id = ? LIMIT 1", params: [sessionId]) { _ in
                anyLine = true
            }
            return anyLine ? .absent : .notImported
        }
    }

    /// Pulls `customTitle` out of one stored `custom-title` line. Returns nil when
    /// the line isn't the shape we expect — treated as "no title", same as the
    /// file-scanning path does for a line it can't decode.
    public static func customTitle(fromRawJSON raw: String) -> String? {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let title = obj["customTitle"] as? String else { return nil }
        return title
    }
}
#endif
