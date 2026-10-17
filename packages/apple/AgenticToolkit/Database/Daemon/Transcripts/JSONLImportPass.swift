#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// One bounded pass of the periodic JSONL import: reads the resume cutoff from
/// `settings`, imports at most `filesPerBatch` changed transcripts, advances the
/// cutoff, and says whether to run again at once.
///
/// Uses `setting('jsonl_import_last_run_at')` as the `since` cutoff so each pass
/// only walks files modified after the previous run. The importer itself is
/// fully idempotent, so a duplicate scan is harmless.
public struct JSONLImportPass: Sendable {

    public static let lastRunKey = "jsonl_import_last_run_at"

    public struct Outcome: Sendable {
        public let summary: ImportSummary
        /// True when more files are waiting and this pass was clean, so the
        /// caller should chain the next pass at zero delay.
        public let rerunImmediately: Bool

        public init(summary: ImportSummary, rerunImmediately: Bool) {
            self.summary = summary
            self.rerunImmediately = rerunImmediately
        }
    }

    private let database: DaemonDatabase
    private let sourceDirectory: URL
    private let filesPerBatch: Int
    private let initialImportWindow: TimeInterval?

    /// - Parameter initialImportWindow: how far back the very first pass (no
    ///   stored cutoff) reaches, in seconds. Nil imports everything.
    public init(
        database: DaemonDatabase,
        sourceDirectory: URL = JSONLImporter.defaultSourceDirectory,
        filesPerBatch: Int = 50,
        initialImportWindow: TimeInterval? = nil
    ) {
        self.database = database
        self.sourceDirectory = sourceDirectory
        self.filesPerBatch = filesPerBatch
        self.initialImportWindow = initialImportWindow
    }

    public func run() throws -> Outcome {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let since: Date?
        if let raw = try? database.setting(for: Self.lastRunKey), !raw.isEmpty {
            since = formatter.date(from: raw)
        } else if let window = initialImportWindow {
            since = Date().addingTimeInterval(-window)
        } else {
            since = nil
        }

        let importer = JSONLImporter(
            sourceDirectory: sourceDirectory,
            database: database,
            options: JSONLImporter.Options(since: since, dryRun: false, maxFiles: filesPerBatch)
        )
        let summary = try importer.run()

        // Advance the cutoff. Prefer the latest-processed file's mtime so a
        // resumed drain doesn't re-scan handled files. When nothing was
        // eligible, only seed the cutoff on the very first run (since == nil)
        // so a fresh install stops replaying from the beginning; once a
        // cutoff exists, an empty pass leaves it untouched — it's already a
        // valid resume point.
        //
        // `filesScanned == 0` is what makes "nothing was eligible" distinct from
        // "the importer held the cutoff back because a file errored": seeding
        // `now` in the latter case would skip exactly the history that failed.
        //
        // A first pass bounded by `initialImportWindow` has `since != nil`, so if it
        // scans nothing it does NOT seed the cutoff. That follows the same rule: the
        // window is already the lower bound, and it slides forward with `now` on each
        // pass until a file is imported and `cutoffISO` takes over. Re-scanning an
        // empty window is cheap and the importer is idempotent.
        if let cutoffISO = summary.cutoffISO {
            try database.setSetting(Self.lastRunKey, cutoffISO)
        } else if since == nil, summary.filesScanned == 0 {
            try database.setSetting(Self.lastRunKey, formatter.string(from: Date()))
        }

        // Chain to the next chunk at zero delay ONLY when this pass was clean.
        // A file-scoped error holds the mtime cursor back (see `JSONLImporter`),
        // so the next pass re-selects the very same batch — chaining immediately
        // on a persistent failure spins the writer lane forever at zero delay,
        // starving ingest and HTTP. Any error therefore drops the drain back to
        // its regular interval: a transient one clears itself on the next tick,
        // a permanent one keeps surfacing in `errors` without pinning the daemon.
        // Pacing down on the rarer errors that DON'T park the cursor (a pass-2
        // session materialize) is deliberate — a drain hitting DB errors should
        // slow, not sprint.
        return Outcome(summary: summary, rerunImmediately: summary.hasMore && summary.errors.isEmpty)
    }
}
#endif
