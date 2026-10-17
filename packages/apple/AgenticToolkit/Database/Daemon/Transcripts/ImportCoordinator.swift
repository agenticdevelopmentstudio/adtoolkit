#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Entry point for running a JSONL transcript import from outside the daemon
/// that owns the database. The caller supplies the database (or a way to open
/// one), so the importer never decides where the data lives.
///
/// Used by a CLI `import` command; tests can also call this directly to
/// exercise the pipeline end-to-end.
public enum ImportCoordinator {

    public static func runJSONLImport(
        database: DaemonDatabase,
        sourceDirectory: URL? = nil,
        options: JSONLImporter.Options = JSONLImporter.Options()
    ) throws -> ImportSummary {
        let source = sourceDirectory ?? JSONLImporter.defaultSourceDirectory
        let importer = JSONLImporter(sourceDirectory: source, database: database, options: options)
        return try importer.run()
    }

    /// An import as asked over either door (HTTP or XPC), against the daemon's
    /// own database: `~` in the source directory is expanded, and a missing one
    /// means the default transcripts directory. `openDatabase` receives the
    /// database path to open (nil for the daemon's default).
    public static func run(
        _ request: ImportRequestDTO,
        openDatabase: @Sendable (String?) throws -> DaemonDatabase
    ) throws -> ImportSummary {
        let sourceURL = request.sourceDirectory.map {
            URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath)
        }
        return try runJSONLImport(
            database: try openDatabase(nil),
            sourceDirectory: sourceURL,
            options: JSONLImporter.Options(since: request.since, dryRun: request.dryRun ?? false)
        )
    }

    /// The import body's wire spelling — snake_case with an ISO-8601 `since` —
    /// shared by both doors so neither can drift from what a client sends.
    public static func makeRequestDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
#endif
