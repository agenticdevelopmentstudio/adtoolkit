#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

// `db` parameters are the one name for the shared DaemonDatabase, as in the toolkit.

/// Pulls a session's transcript into the database the moment that session
/// writes, rather than when the next sweep comes round to it.
///
/// ## Why this exists
///
/// `JSONLImportTask` walks `~/.claude/projects` every five minutes, so anything
/// read out of `transcript_lines` — the Conversations feed most visibly — was up
/// to five minutes stale, and a turn straddling a pass showed the human's
/// question with no answer under it until the following one. The interval was
/// never a judgment about freshness; it is what a poll costs when it has to
/// re-walk 4,600 files to find the handful that changed.
///
/// It doesn't have to. A hook fires the instant a session writes and its payload
/// names the file, so the change that the sweep goes looking for is announced.
/// Given the name, the work is one `stat` and the file's new tail: no walk, and
/// nothing proportional to how much history is on the machine.
///
/// ## What it does not change
///
/// The import itself. A tail is `JSONLImporter` scoped to one file
/// (``JSONLImporter/Options/only``), so the byte cursor, per-line dedup and
/// synthesized events are the sweep's, unmodified — which is what makes the two
/// paths safe to run against the same file: whichever arrives first writes the
/// rows, and the other finds nothing to do. The sweep stays exactly as it was,
/// and still owns everything no hook announces: sessions on other machines,
/// files restored from a backup, the backfill of history that predates the
/// daemon.
///
/// The one part a tail takes off the import's own pass is the metrics recompute
/// (``JSONLImporter/Options/refreshesSessionMetrics``), because that one step is
/// a whole-session aggregate whose cost is the session's entire history rather
/// than the tail's few new lines. It is not dropped — the tail consumes the
/// bytes, so the sweep would never see them again — but moved onto a clock of
/// its own: ``refreshMetrics(for:)``.
///
/// ## Pacing
///
/// Leading-edge, per file. The first hook after a quiet spell imports
/// immediately — latency is the point, and making the first one wait would trade
/// away the whole benefit — and further hooks inside ``quietPeriod`` collapse
/// into one catch-up pass at the end of it. So a tool-heavy turn firing a hook
/// every few hundred milliseconds costs one small read per file per quiet
/// period, and a turn that ends mid-period is still picked up by the catch-up.
///
/// Every hook counts as activity, not just the two that produce conversation: a
/// `PreToolUse` is a session writing a line as surely as a `Stop` is, the read it
/// triggers is the same few kilobytes, and keying off one event type would leave
/// the feed's work-output view on the old five-minute lag for no saving.
public actor TranscriptTailer {

    /// How long one file's imports stay collapsed after a pass starts. Long
    /// enough that a burst of hooks is one read; short enough that "immediately"
    /// survives the catch-up case, where a turn ends inside the window and its
    /// reply waits out the remainder.
    public static let defaultQuietPeriod: Duration = .seconds(2)

    /// The most often a tailed session's metrics are recomputed while it is
    /// still writing. See ``refreshMetrics(for:)`` for why this is not simply
    /// every pass.
    public static let defaultMetricsInterval: Duration = .seconds(60)

    private let database: DaemonDatabase
    /// Where the blocking import runs.
    ///
    /// `JSONLImporter.run()` is synchronous: it reads a file and writes SQLite,
    /// and blocks for as long as both take. Run on a `Task.detached`, that block
    /// parks a *cooperative pool* thread — the pool holds about one per core and
    /// is not allowed to grow, so a handful of sessions tailing at once can park
    /// most of it, and every unrelated `await` in the daemon waits behind work
    /// that is not even running. Blocking work belongs on a queue of its own.
    ///
    /// Serial, because these imports serialize anyway on the database's single
    /// write lane. Saying so costs one thread in total instead of one per active
    /// session, and changes no ordering that was not already forced.
    private let importQueue: DispatchQueue
    private let quietPeriod: Duration
    private let metricsInterval: Duration

    /// Files inside their quiet period — an import is running, or just ran.
    private var cooling: Set<String> = []

    /// Files that saw activity while cooling, so a catch-up pass is owed. A set,
    /// not a count: what is owed is one more read of the file's tail, however
    /// many hooks asked for it.
    private var owed: Set<String> = []

    /// The session each cooling file belongs to, as the hook that announced it
    /// said. The importer reads the id out of the lines themselves; this is the
    /// same id arriving a step earlier, which is what lets the metrics refresh
    /// happen on a pass that read no new lines.
    private var sessions: [String: String] = [:]

    /// When each cooling file's metrics were last recomputed.
    private var meteredAt: [String: ContinuousClock.Instant] = [:]

    /// - Parameter queueLabel: label of the serial import queue, so a daemon
    ///   can put it under its own subsystem.
    public init(
        database: DaemonDatabase,
        queueLabel: String = "transcript-tailer",
        quietPeriod: Duration = TranscriptTailer.defaultQuietPeriod,
        metricsInterval: Duration = TranscriptTailer.defaultMetricsInterval
    ) {
        self.database = database
        self.importQueue = DispatchQueue(label: queueLabel, qos: .utility)
        self.quietPeriod = quietPeriod
        self.metricsInterval = metricsInterval
    }

    /// Notes that `sessionId`, whose transcript is `transcriptPath`, just wrote
    /// something.
    ///
    /// Returns as soon as the pass is scheduled; the import runs off this actor.
    /// Cheap enough to call from the ingestion path on every event, which is the
    /// point — the caller has no business deciding which hooks are worth a read.
    public func noteActivity(transcriptPath: String, sessionId: String) {
        guard !transcriptPath.isEmpty else { return }
        if !sessionId.isEmpty { sessions[transcriptPath] = sessionId }
        guard !cooling.contains(transcriptPath) else {
            owed.insert(transcriptPath)
            return
        }
        cooling.insert(transcriptPath)
        Task { await self.pull(transcriptPath) }
    }

    /// Imports one file, waits out the quiet period, and repeats for as long as
    /// hooks kept arriving during the wait.
    ///
    /// A loop rather than a tail call: a session under steady tool use owes a
    /// catch-up every period for as long as it runs, and recursing would grow a
    /// continuation chain one frame per two seconds for the life of the session.
    private func pull(_ path: String) async {
        /// Lines have been written that no metrics recompute has counted yet.
        var unmetered = false
        repeat {
            unmetered = await importNow(path: path, database: database) > 0 || unmetered
            if unmetered, isDueForMetrics(path) {
                await refreshMetrics(for: path)
                unmetered = false
            }
            try? await Task.sleep(for: quietPeriod)
        } while owed.remove(path) != nil
        cooling.remove(path)

        // The burst is over, so this is where the session's totals become right
        // again — and where they stay right, because nothing else will read this
        // file: the tail consumed its bytes, so the five-minute sweep now finds
        // it unchanged and passes over it.
        if unmetered { await refreshMetrics(for: path) }
        sessions.removeValue(forKey: path)
        meteredAt.removeValue(forKey: path)
    }

    private func isDueForMetrics(_ path: String) -> Bool {
        guard let last = meteredAt[path] else { return true }
        return ContinuousClock.now - last >= metricsInterval
    }

    /// Recomputes one session's metrics from its persisted turns.
    ///
    /// Split out of the import because it is the one part of a pass whose cost
    /// is the session's whole history rather than the tail's few new lines: a
    /// `GROUP BY model` over every turn the session has ever taken, 40–50 ms on
    /// the long ones, on the database's single write lane. A sweep pays that
    /// once per session per five minutes, which is what it was measured
    /// against. Paying it on every tail — up to once per quiet period, for as
    /// long as a session runs — is hundreds of times the work to keep a token
    /// total that nothing reads in real time a couple of seconds fresher.
    ///
    /// So it runs on a clock of its own: once when the writing stops, and at
    /// most once per ``metricsInterval`` while it continues.
    private func refreshMetrics(for path: String) async {
        guard let sessionId = sessions[path], !sessionId.isEmpty else { return }
        meteredAt[path] = .now
        let database = self.database
        let importQueue = self.importQueue
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            importQueue.async {
                do {
                    if let metrics = try database.sessionMetricsFromTranscriptTurns(
                        sessionId: sessionId
                    ) {
                        try database.upsertSessionMetrics(
                            metrics,
                            accountEmail: database.resolvedAccountForSession(sessionId)
                        )
                    }
                } catch {
                    // Costs accuracy in a total, never a line: the next sweep or
                    // the next burst recomputes from the same persisted turns.
                    Self.logger.warning("""
                        Metrics refresh failed for \(sessionId, privacy: .public): \
                        \(error.localizedDescription, privacy: .public)
                        """)
                }
                continuation.resume()
            }
        }
    }

    /// The import, off the actor: holding the actor across it would serialize
    /// every other session's tail behind this one file. Returns how many lines
    /// it wrote, which is what tells the caller whether anything is owed a
    /// metrics recompute.
    private nonisolated func importNow(path: String, database: DaemonDatabase) async -> Int {
        let url = URL(fileURLWithPath: path)
        let importQueue = self.importQueue
        return await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            importQueue.async {
                let importer = JSONLImporter(
                    // Unused under `only` — discovery and the cursor prune are
                    // the only things that read it, and a scoped run does
                    // neither — but the file's own directory is the honest
                    // answer to "under what".
                    sourceDirectory: url.deletingLastPathComponent(),
                    database: database,
                    options: JSONLImporter.Options(
                        only: [url],
                        // The lines are what a tail is for. The metrics
                        // recompute runs on its own clock instead — see
                        // `refreshMetrics(for:)`.
                        refreshesSessionMetrics: false
                    )
                )
                do {
                    let summary = try importer.run()
                    // Quiet in the steady state: a tail that read nothing new
                    // (the hook beat the write to disk, or the sweep got there
                    // first) is the ordinary case, not news.
                    if summary.linesInserted > 0 {
                        Self.logger.debug("""
                            Tailed \(url.lastPathComponent, privacy: .public): \
                            \(summary.linesInserted) line(s), \(summary.bytesRead) byte(s)
                            """)
                    }
                    for error in summary.errors {
                        Self.logger.warning("""
                            Tail error for \(url.lastPathComponent, privacy: .public): \
                            \(error, privacy: .public)
                            """)
                    }
                    continuation.resume(returning: summary.linesInserted)
                    return
                } catch {
                    // A failed tail costs freshness, never data: the byte cursor
                    // isn't advanced past what failed, so the five-minute sweep
                    // re-reads exactly this file.
                    Self.logger.warning("""
                        Tail failed for \(url.lastPathComponent, privacy: .public): \
                        \(error.localizedDescription, privacy: .public)
                        """)
                }
                continuation.resume(returning: 0)
            }
        }
    }
}

extension TranscriptTailer: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
