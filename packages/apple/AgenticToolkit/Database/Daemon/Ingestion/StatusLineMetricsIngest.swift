#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// MARK: - StatusLine → session metrics
//
// The part of a `StatusLine` payload every session daemon needs: the session's
// context and cost figures in `session_metrics`, and the Claude Code version's
// payload schema in `claude_versions`. Both tables are in the shared schema
// (`SessionSchema`). Oversight reads `session_metrics.context_used_pct` and
// `context_window_size`, so a daemon that skips this sees every session at 0.
//
// A daemon with no StatusLine routing of its own passes
// `DaemonDatabase.statusLineMetricsIngest` as its `statusLineIngest`. One that
// does more (Stenographer's rate-limit snapshots) keeps its own handler.

extension DaemonDatabase {

    /// A ready-made ``StatusLineIngest`` that runs
    /// ``ingestStatusLineMetrics(sessionId:hookData:accountEmail:)``.
    public static let statusLineMetricsIngest: StatusLineIngest = { database, sessionId, hookData, _, accountEmail in
        try database.ingestStatusLineMetrics(sessionId: sessionId, hookData: hookData, accountEmail: accountEmail)
    }

    /// Records a StatusLine payload's version schema in `claude_versions` and its
    /// session figures in `session_metrics` (claude_version, project_dir,
    /// transcript_path, context_window_size, api_duration_ms, lines_added/removed,
    /// context_used_pct, and account_email when the row has none yet).
    ///
    /// Must run inside `ingestEvent`'s write transaction: it calls `execute` /
    /// `query` directly.
    public func ingestStatusLineMetrics(
        sessionId: String,
        hookData: [String: Any],
        accountEmail: String
    ) throws {
        let claudeVersion = hookData["version"] as? String ?? ""
        if !claudeVersion.isEmpty {
            try recordClaudeVersionSchema(claudeVersion: claudeVersion, payload: hookData)
        }

        guard !sessionId.isEmpty else { return }
        let workspace = hookData["workspace"] as? [String: Any] ?? [:]
        let contextWindow = hookData["context_window"] as? [String: Any] ?? [:]
        let cost = hookData["cost"] as? [String: Any] ?? [:]
        let projectDir = workspace["project_dir"] as? String ?? ""
        let transcriptPath = hookData["transcript_path"] as? String ?? ""
        let contextWindowSize = Self.statusLineInt(contextWindow["context_window_size"])
        let apiDurationMs = Self.statusLineInt(cost["total_api_duration_ms"])
        let linesAdded = Self.statusLineInt(cost["total_lines_added"])
        let linesRemoved = Self.statusLineInt(cost["total_lines_removed"])
        let remainingPct = contextWindow["remaining_percentage"] as? Double
            ?? Double(contextWindow["remaining_percentage"] as? Int ?? 100)
        let contextUsedPct = max(0, min(100, 100 - Self.statusLineSaturatingInt(remainingPct.rounded())))

        try execute("""
            INSERT INTO session_metrics (
                session_id, total_input_tokens, total_output_tokens,
                cache_read_tokens, cache_creation_tokens, total_cost_usd,
                turn_count, model, first_turn_at, last_turn_at, updated_at,
                claude_version, project_dir, transcript_path,
                context_window_size, api_duration_ms, lines_added,
                lines_removed, context_used_pct, account_email
            ) VALUES (?, 0, 0, 0, 0, 0, 0, '', '', '', datetime('now'),
                      ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(session_id) DO UPDATE SET
                claude_version = excluded.claude_version,
                project_dir = excluded.project_dir,
                transcript_path = excluded.transcript_path,
                context_window_size = excluded.context_window_size,
                api_duration_ms = excluded.api_duration_ms,
                lines_added = excluded.lines_added,
                lines_removed = excluded.lines_removed,
                context_used_pct = excluded.context_used_pct,
                updated_at = datetime('now'),
                account_email = CASE WHEN excluded.account_email != '' AND session_metrics.account_email = ''
                                      THEN excluded.account_email ELSE session_metrics.account_email END
        """, params: [
            sessionId,
            claudeVersion, projectDir, transcriptPath,
            contextWindowSize, apiDurationMs, linesAdded,
            linesRemoved, contextUsedPct, accountEmail
        ])
    }

    /// First capture of a version stores the payload (minus locally injected keys)
    /// and the sorted union of its field paths; later captures only add newly seen
    /// paths to that union, so a render that omits conditional fields does not look
    /// like Anthropic removed them.
    private func recordClaudeVersionSchema(claudeVersion: String, payload: [String: Any]) throws {
        let observed = payload.filter { !$0.key.hasPrefix(Self.statusLineLocalInjectionPrefix) }
        let newPaths = Set(Self.statusLineFieldPaths(observed))

        var existingPaths: Set<String>?
        try query("""
            SELECT field_paths FROM claude_versions WHERE claude_version = ?
        """, params: [claudeVersion]) { row in
            let raw = string(row, 0)
            if let data = raw.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
                existingPaths = Set(parsed)
            } else {
                existingPaths = []
            }
        }

        if let existingPaths {
            let merged = existingPaths.union(newPaths)
            guard merged != existingPaths else { return }
            let sortedPaths = merged.sorted()
            try execute("""
                UPDATE claude_versions
                   SET field_paths = ?, fields_count = ?
                 WHERE claude_version = ?
            """, params: [Self.statusLineJSON(sortedPaths, fallback: "[]"), sortedPaths.count, claudeVersion])
        } else {
            let sortedPaths = newPaths.sorted()
            let blob = (try? JSONSerialization.data(withJSONObject: observed, options: [.prettyPrinted, .sortedKeys]))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            try execute("""
                INSERT INTO claude_versions
                    (claude_version, fields, fields_count, first_seen, field_paths)
                VALUES (?, ?, ?, datetime('now'), ?)
            """, params: [claudeVersion, blob, sortedPaths.count, Self.statusLineJSON(sortedPaths, fallback: "[]")])
        }
    }

    /// Keys the status-line helper adds to Claude Code's payload before the daemon
    /// sees it (`GitContextFingerprint.payloadKey`, `stenographer_git`). They are kept
    /// out of `claude_versions`, which records Anthropic's schema only.
    static let statusLineLocalInjectionPrefix = "stenographer_"

    /// Dotted field paths of a JSON object: every key of a dictionary (recursing
    /// into its value), and `[]` appended for an array, recursing into its first
    /// element.
    static func statusLineFieldPaths(_ value: Any, prefix: String = "") -> [String] {
        var paths: [String] = []
        if let dict = value as? [String: Any] {
            for (key, val) in dict {
                let path = prefix.isEmpty ? key : "\(prefix).\(key)"
                paths.append(path)
                paths.append(contentsOf: statusLineFieldPaths(val, prefix: path))
            }
        } else if let array = value as? [Any], let first = array.first {
            paths.append(contentsOf: statusLineFieldPaths(first, prefix: prefix + "[]"))
        }
        return paths
    }

    private static func statusLineJSON(_ value: [String], fallback: String) -> String {
        (try? JSONSerialization.data(withJSONObject: value)).flatMap { String(data: $0, encoding: .utf8) } ?? fallback
    }

    private static func statusLineInt(_ value: Any?) -> Int {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let double = value as? Double { return statusLineSaturatingInt(double) }
        if let str = value as? String, let parsed = Int(str) { return parsed }
        return 0
    }

    /// `Int(double)` faults on NaN or an out-of-range value, which would kill the
    /// daemon on a malformed payload instead of failing the event; this saturates.
    static func statusLineSaturatingInt(_ value: Double) -> Int {
        guard !value.isNaN else { return 0 }
        if value >= Double(Int.max) { return .max }
        if value <= Double(Int.min) { return .min }
        return Int(value)
    }
}
#endif
