#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Session metrics (JSONL import)

    /// UPSERT per-session rollups from the importer. `updated_at` is
    /// refreshed by the row default on insert and by the SET clause on
    /// update so downstream consumers can tell when the numbers changed.
    public func upsertSessionMetrics(_ metrics: SessionMetricsDTO, accountEmail: String) throws {
        try write { _ in
            try execute("""
                INSERT INTO session_metrics (
                    session_id, total_input_tokens, total_output_tokens,
                    cache_read_tokens, cache_creation_tokens, total_cost_usd,
                    turn_count, model, first_turn_at, last_turn_at, updated_at,
                    account_email
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), ?)
                ON CONFLICT(session_id) DO UPDATE SET
                    total_input_tokens = excluded.total_input_tokens,
                    total_output_tokens = excluded.total_output_tokens,
                    cache_read_tokens = excluded.cache_read_tokens,
                    cache_creation_tokens = excluded.cache_creation_tokens,
                    total_cost_usd = excluded.total_cost_usd,
                    turn_count = excluded.turn_count,
                    model = excluded.model,
                    first_turn_at = excluded.first_turn_at,
                    last_turn_at = excluded.last_turn_at,
                    updated_at = datetime('now'),
                    account_email = CASE WHEN excluded.account_email != '' AND session_metrics.account_email = ''
                                          THEN excluded.account_email ELSE session_metrics.account_email END
            """, params: [
                metrics.sessionId,
                metrics.totalInputTokens,
                metrics.totalOutputTokens,
                metrics.cacheReadTokens,
                metrics.cacheCreationTokens,
                metrics.totalCostUsd,
                metrics.turnCount,
                metrics.model,
                metrics.firstTurnAt,
                metrics.lastTurnAt,
                accountEmail
            ])
        }
    }

    /// Aggregate a single session's metrics directly from the persisted,
    /// deduplicated `transcript_turns` rows — the source of truth the JSONL
    /// importer upserts into `session_metrics`. Sourcing from the table
    /// (not an in-memory per-run bucket) keeps totals correct no matter how
    /// the import was chunked: a session whose turns arrive across several
    /// files/chunks, or a growing live file re-scanned with a `since`
    /// turn-filter, sums every persisted turn instead of letting the
    /// REPLACE upsert overwrite earlier slices. Idempotent — a re-import
    /// inserts zero new turns, so the aggregate is unchanged.
    ///
    /// Tokens are grouped by model so each model's rate is applied only to
    /// its own tokens (a session that switched models is costed correctly);
    /// `model` reports the chronologically-latest non-empty model, breaking
    /// exact-timestamp ties by model name so the result is deterministic.
    /// Returns nil when the session has no turns.
    public func sessionMetricsFromTranscriptTurns(sessionId: String) throws -> SessionMetricsDTO? {
        struct ModelBucket {
            var turnCount = 0
            var input = 0
            var output = 0
            var cacheRead = 0
            var cacheCreate = 0
            var cacheCreate1h = 0
            var lastTs = ""
        }
        var perModel: [String: ModelBucket] = [:]
        var totalTurns = 0
        var firstTs = ""
        var lastTs = ""

        try query("""
            SELECT model,
                   COUNT(*),
                   COALESCE(SUM(input_tokens), 0),
                   COALESCE(SUM(output_tokens), 0),
                   COALESCE(SUM(cache_read_tokens), 0),
                   COALESCE(SUM(cache_creation_tokens), 0),
                   COALESCE(SUM(cache_creation_1h_tokens), 0),
                   COALESCE(MIN(NULLIF(timestamp, '')), ''),
                   COALESCE(MAX(NULLIF(timestamp, '')), '')
            FROM transcript_turns
            WHERE session_id = ?
            GROUP BY model
            """, params: [sessionId]) { row in
            let model = string(row, 0)
            var bucket = ModelBucket()
            bucket.turnCount = Int(int64(row, 1))
            bucket.input = Int(int64(row, 2))
            bucket.output = Int(int64(row, 3))
            bucket.cacheRead = Int(int64(row, 4))
            bucket.cacheCreate = Int(int64(row, 5))
            bucket.cacheCreate1h = Int(int64(row, 6))
            let groupFirst = string(row, 7)
            let groupLast = string(row, 8)
            bucket.lastTs = groupLast
            perModel[model] = bucket
            totalTurns += bucket.turnCount
            if !groupFirst.isEmpty, firstTs.isEmpty || groupFirst < firstTs { firstTs = groupFirst }
            if groupLast > lastTs { lastTs = groupLast }
        }

        guard totalTurns > 0 else { return nil }

        var input = 0, output = 0, cacheRead = 0, cacheCreate = 0
        var cost = 0.0
        var latestModel = ""
        var latestModelTs = ""
        for (model, bucket) in perModel {
            input += bucket.input
            output += bucket.output
            cacheRead += bucket.cacheRead
            cacheCreate += bucket.cacheCreate
            cost += TranscriptPricing.cost(
                model: model,
                inputTokens: bucket.input,
                outputTokens: bucket.output,
                cacheReadTokens: bucket.cacheRead,
                cacheCreationTokens: bucket.cacheCreate,
                cacheCreation1hTokens: bucket.cacheCreate1h
            )
            // `perModel` is a Dictionary, so iteration order is unstable.
            // Break ties on `lastTs` deterministically by model name so the
            // representative model doesn't flip between otherwise-identical
            // imports.
            if !model.isEmpty,
               latestModel.isEmpty
                || bucket.lastTs > latestModelTs
                || (bucket.lastTs == latestModelTs && model > latestModel) {
                latestModel = model
                latestModelTs = bucket.lastTs
            }
        }

        return SessionMetricsDTO(
            sessionId: sessionId,
            totalInputTokens: input,
            totalOutputTokens: output,
            cacheReadTokens: cacheRead,
            cacheCreationTokens: cacheCreate,
            totalCostUsd: cost,
            turnCount: totalTurns,
            model: latestModel,
            firstTurnAt: firstTs,
            lastTurnAt: lastTs,
            updatedAt: ""
        )
    }

    public func metricsForSession(sessionId: String) throws -> SessionMetricsDTO? {
        var result: SessionMetricsDTO?
        try query("""
            SELECT total_input_tokens, total_output_tokens, cache_read_tokens,
                   cache_creation_tokens, total_cost_usd, turn_count, model,
                   first_turn_at, last_turn_at, updated_at
            FROM session_metrics
            WHERE session_id = ?
        """, params: [sessionId]) { row in
            result = SessionMetricsDTO(
                sessionId: sessionId,
                totalInputTokens: Int(int64(row, 0)),
                totalOutputTokens: Int(int64(row, 1)),
                cacheReadTokens: Int(int64(row, 2)),
                cacheCreationTokens: Int(int64(row, 3)),
                totalCostUsd: double(row, 4),
                turnCount: Int(int64(row, 5)),
                model: self.string(row, 6),
                firstTurnAt: self.string(row, 7),
                lastTurnAt: self.string(row, 8),
                updatedAt: self.string(row, 9)
            )
        }
        return result
    }

    /// The `settings` key holding the ``TranscriptPricing/revision`` the
    /// persisted `session_metrics.total_cost_usd` values were computed at.
    private static let pricingRevisionKey = "transcript_pricing_revision"

    /// Re-cost every persisted `session_metrics` row when the pricing table
    /// moves, and record the revision that produced the numbers now on disk.
    ///
    /// `total_cost_usd` is the one figure a daemon *stores* rather than
    /// recomputes: `/turns` and `/insights/usage-rows` price live from
    /// `transcript_turns` on every request, but `/sessions/:id/metrics` serves
    /// what the importer wrote. And the importer never revisits a transcript
    /// whose mtime hasn't moved (`JSONLImporter.run`), so a finished session's
    /// `.jsonl` is read exactly once, ever. Without this pass a price
    /// correction reaches new sessions only, and the two endpoints disagree
    /// about the same session forever — the kind of divergence that is
    /// invisible until someone reconciles two screens.
    ///
    /// Idempotent, and nothing at all on every launch after the first at a given
    /// revision — but NOT cheap: the scan below groups the whole of
    /// `transcript_turns`, which on a multi-gigabyte DB takes minutes.
    ///
    /// Which is why this is maintenance that runs AFTER the listener is up
    /// (the daemon's run loop), never from `runMigrations()`. It did run there,
    /// and on a 39 GB database the scan exceeded the serving read deadline,
    /// threw, aborted the daemon's startup phase A, and left launchd restarting
    /// the daemon every ten seconds — the whole daemon down over a cost figure.
    /// A migration gates startup because a wrong schema must not serve; a
    /// maintenance pass must not gate it, because a stale cost figure is not
    /// worth an outage.
    ///
    /// So it cannot throw at all: the only caller gets the logged version, and
    /// the revision is recorded only on success, so a failed pass simply runs
    /// again next launch.
    public func repriceSessionMetricsIfNeeded() {
        do {
            try repriceSessionMetrics()
        } catch {
            logger.error("repricing failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func repriceSessionMetrics() throws {
        let recorded = (try? setting(for: Self.pricingRevisionKey)) ?? nil
        guard recorded != String(TranscriptPricing.revision) else { return }

        // A DB whose `transcript_turns` predates these columns holds nothing
        // this pass could reprice, so there is nothing to do and nothing to
        // report.
        let priced = ["session_id", "model", "input_tokens", "output_tokens",
                      "cache_read_tokens", "cache_creation_tokens", "cache_creation_1h_tokens"]
        let present = columnNames(of: "transcript_turns")
        guard priced.allSatisfy(present.contains) else {
            logger.info("repricing skipped: transcript_turns predates the priced columns")
            return
        }

        // Group by (session, model) so each model's rate is applied only to its
        // own tokens — the same rule `sessionMetricsFromTranscriptTurns` follows
        // for a single session, which is what keeps the two agreeing.
        var costs: [String: Double] = [:]
        try query("""
            SELECT session_id, model,
                   COALESCE(SUM(input_tokens), 0),
                   COALESCE(SUM(output_tokens), 0),
                   COALESCE(SUM(cache_read_tokens), 0),
                   COALESCE(SUM(cache_creation_tokens), 0),
                   COALESCE(SUM(cache_creation_1h_tokens), 0)
            FROM transcript_turns
            GROUP BY session_id, model
            """, deadline: DaemonDatabase.maintenanceReadDeadline) { row in
            let sessionId = self.string(row, 0)
            costs[sessionId, default: 0] += TranscriptPricing.cost(
                model: self.string(row, 1),
                inputTokens: Int(self.int64(row, 2)),
                outputTokens: Int(self.int64(row, 3)),
                cacheReadTokens: Int(self.int64(row, 4)),
                cacheCreationTokens: Int(self.int64(row, 5)),
                cacheCreation1hTokens: Int(self.int64(row, 6))
            )
        }

        try migrationTransaction {
            for (sessionId, cost) in costs {
                try execute(
                    "UPDATE session_metrics SET total_cost_usd = ? WHERE session_id = ?",
                    params: [cost, sessionId]
                )
            }
            try setSetting(Self.pricingRevisionKey, String(TranscriptPricing.revision))
        }
        logger.info("""
            repriced \(costs.count, privacy: .public) sessions at pricing revision \
            \(TranscriptPricing.revision, privacy: .public)
            """)
    }
}
#endif
