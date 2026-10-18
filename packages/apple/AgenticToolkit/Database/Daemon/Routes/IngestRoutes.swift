#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// The ingestion surface: the capture spool's status, the quarantine list and its
/// retry, and the native `http` hook endpoint that feeds the spool.
enum IngestRoutes {

    static func table(_ services: SessionFeatureServices) -> RouteTable {
        let database = services.database
        let quarantine = services.quarantine
        return RouteTable([
            RouteTable.route("GET", where: { $0 == ["ingestion", "spool"] }) { _, _ in
                spoolStatus(services.spool)
            },
            RouteTable.route("GET", where: { $0 == ["ingestion", "errors"] }) { _, _ in
                .json(quarantine.list())
            },
            RouteTable.route("GET", where: { $0 == ["ingestion", "errors", "count"] }) { _, _ in
                let counts = quarantine.counts()
                return .json(["count": counts.total, "exhausted": counts.exhausted])
            },
            // Persistent ingestion-error log (DB-backed) for tracking recurring
            // failures — includes recovered/cleared history, unlike the live list.
            RouteTable.route("GET", where: { $0 == ["ingestion", "errors", "log"] }) { request, _ in
                do {
                    return .json(
                        try database.recentIngestionErrors(limit: request.boundedLimit(default: 200, max: 1000))
                    )
                } catch {
                    return .failure(error)
                }
            },
            RouteTable.route("GET", where: { $0 == ["ingestion", "errors", "retry", "progress"] }) { _, _ in
                .json(quarantine.retryProgress())
            },
            RouteTable.route("POST", where: { $0 == ["ingestion", "errors", "retry"] }) { _, _ in
                let progress = quarantine.startRetry(
                    parse: services.parseQuarantinedEvent, ingest: services.retryIngest
                )
                return .json(progress, status: 202)
            },
            RouteTable.route("POST", where: { $0 == ["ingestion", "errors", "clear"] }) { _, _ in
                quarantine.clear()
                return .noContent
            },
            RouteTable.route("POST", where: { $0.count == 2 && $0[0] == "hook" }) { request, components in
                hook(event: components[1], request: request, services)
            }
        ])
    }

    /// `GET /ingestion/spool` — how far behind the drain is. `pending` alone
    /// doesn't distinguish "busy" from "stuck", so the age of the oldest
    /// undrained event is the number that actually answers it.
    private static func spoolStatus(_ spool: IngestSpool?) -> RouteResponse {
        guard let spool else {
            // "No spool here" is not "the spool is empty". Reporting `pending: 0`
            // made the two indistinguishable, and a client reads this endpoint to
            // decide whether the drain is stuck — an answer it would have
            // believed. A daemon with no spool can't answer, and says so.
            return RouteResponse(
                status: 503,
                body: Data(#"{"status":"unavailable","error":"no ingest spool on this daemon"}"#.utf8)
            )
        }
        do {
            return .json(try spool.status())
        } catch {
            return .failure(error)
        }
    }

    /// `POST /hook/:event` — the native `http` hook endpoint. Claude Code POSTs
    /// the same JSON payload a `command` hook would receive on stdin; the daemon
    /// builds an event from it and captures it.
    ///
    /// Always replies 2xx with a JSON body: the hook contract forbids ever
    /// blocking Claude on the daemon's behalf, and an `http` hook treats a
    /// non-2xx (or a missing body) as a hook failure. An empty payload, an
    /// untrackable event (no `session_id`), or a headless drop all return
    /// `200 {}` — accepted-and-ignored, never an error.
    private static func hook(
        event: String, request: RouteRequest, _ services: SessionFeatureServices
    ) -> RouteResponse {
        guard !request.body.isEmpty else { return okEmpty }
        guard let parsed = services.buildHookEvent(event, request.body) else {
            // Well-formed but intentionally not ingested (headless, or no session_id).
            return okEmpty
        }
        do {
            try services.captureHook(parsed)
        } catch {
            // Fail-open is still the contract — a hook must never surface an error
            // to Claude. This is a spool write, not a main-database ingest: it takes
            // no schema, no DDL and no shared write lock, so the failures it used to
            // swallow (a migration, a contended writer, a saturated queue) can't
            // reach here at all. Getting this far means the spool file itself is
            // unwritable, and the event really is lost.
            let message = error.localizedDescription
            logger.error("Hook capture failed for \(event, privacy: .public): \(message, privacy: .public)")
        }
        return okEmpty
    }

    /// `200 {}` — the accepted-and-ignored reply every hook delivery returns.
    private static let okEmpty = RouteResponse(status: 200, body: Data("{}".utf8))
}

extension IngestRoutes: Loggable {
    static nonisolated let logger = makeLogger()
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
