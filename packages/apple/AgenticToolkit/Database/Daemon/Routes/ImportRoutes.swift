#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// `POST /import` — a JSONL backfill run in-process.
enum ImportRoutes {

    /// Body: `{"source_directory"?: String, "since"?: ISO8601, "dry_run"?: Bool}`.
    /// Runs the daemon's import against its own database (SQLite WAL lets it coexist
    /// with reads) and returns the `ImportSummary`.
    static func table(_ services: SessionFeatureServices) -> RouteTable {
        RouteTable([
            RouteTable.route("POST", where: { $0 == ["import"] }) { request, _ in
                let importRequest: ImportRequestDTO
                if !request.body.isEmpty {
                    do {
                        importRequest = try ImportCoordinator.makeRequestDecoder()
                            .decode(ImportRequestDTO.self, from: request.body)
                    } catch {
                        return .error("Invalid import request body: \(error.localizedDescription)", status: 400)
                    }
                } else {
                    importRequest = ImportRequestDTO()
                }
                do {
                    return .json(try services.runImport(importRequest))
                } catch {
                    return .failure(error)
                }
            }
        ])
    }
}
#endif
