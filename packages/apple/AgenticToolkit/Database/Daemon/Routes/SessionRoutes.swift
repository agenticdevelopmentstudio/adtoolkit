#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// The endpoint index, `/health`, `/db/stats`, and the session and event reads, plus
/// the one session write (`POST /sessions/:id/summarize`).
enum SessionRoutes {

    /// Most sessions `GET /sessions` will ever return in one response. See
    /// `listSessions` for why this is a ceiling and not a page size.
    static let sessionListCeiling = 10_000

    static func table(_ services: SessionFeatureServices) -> RouteTable {
        let database = services.database
        return RouteTable([
            RouteTable.route("GET", where: { $0.isEmpty }) { _, _ in root(services) },
            RouteTable.route("GET", where: { $0 == ["health"] }) { _, _ in health(services) },
            RouteTable.route("GET", where: { $0 == ["db", "stats"] }) { _, _ in
                .json(database.dbStats())
            },
            RouteTable.route("GET", where: { $0 == ["import", "cursors"] }) { _, _ in
                do {
                    return .json(try database.transcriptCursorStats())
                } catch {
                    return .failure(error)
                }
            },
            RouteTable.route("GET", where: { $0 == ["sessions"] }) { request, _ in
                listSessions(request, database: database)
            },
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "sessions" }) { _, components in
                getSession(components[1], database: database)
            },
            RouteTable.route("GET", where: { $0.count == 3 && $0[0] == "sessions" && $0[2] == "events" }) {
                request, components in
                sessionEvents(components[1], request, database: database)
            },
            RouteTable.route("GET", where: { $0.count == 3 && $0[0] == "sessions" && $0[2] == "metrics" }) {
                _, components in
                sessionMetrics(components[1], database: database)
            },
            RouteTable.route("GET", where: { $0 == ["events"] }) { request, _ in
                queryEvents(request, database: database)
            },
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "events" && $0[1] != "stream" }) {
                _, components in
                getEvent(components[1], database: database)
            },
            RouteTable.route("POST", where: { $0.count == 3 && $0[0] == "sessions" && $0[2] == "summarize" }) {
                _, components in
                await summarize(components[1], services)
            }
        ])
    }

    // MARK: - Handlers

    private static func root(_ services: SessionFeatureServices) -> RouteResponse {
        let endpoints = services.endpointIndex.map { "    \"\($0)\"" }.joined(separator: ",\n")
        let body = """
        {
          "name": "\(services.daemonName)",
          "version": "\(services.daemonVersion)",
          "endpoints": [
        \(endpoints)
          ]
        }
        """
        return RouteResponse(status: 200, body: Data(body.utf8))
    }

    private static func health(_ services: SessionFeatureServices) -> RouteResponse {
        // Pure liveness probe — no DB access. A saturated DB queue (retention,
        // import) must not block /health, since the daemon is alive regardless.
        // Callers that need counts use /insights/summary.
        let uptime = Date().timeIntervalSince(services.startTime)
        // Memory is a kernel read, not a DB read, so it keeps /health DB-free
        // while making "how big is the daemon right now?" a single curl.
        let memory = services.memorySample()
        let dto = HealthDTO(
            // The daemon is up either way; "migrating" says the schema isn't
            // current yet, which is why the other endpoints are answering 503.
            status: services.database.isReady ? "ok" : "migrating",
            uptime: uptime,
            version: services.daemonVersion,
            startupDurationMs: services.startupDurationMs(),
            memoryFootprintMb: memory?.footprintMB,
            memoryPeakMb: memory?.peakMB,
            statusLineError: services.hookInstaller.statusLineError
        )
        return .json(dto)
    }

    private static func listSessions(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let statusFilter: SessionStatus?
        if let status = request.query("status") {
            statusFilter = SessionStatus(rawValue: status)
        } else {
            statusFilter = nil
        }
        let projectFilter = request.query("project")
        // Callers that don't render the per-session event count (e.g. the Sessions-window
        // poll) pass ?counts=false to skip the event_log COUNT join.
        let includeCounts = request.query("counts") != "false"
        // `sessions` has no retention, so an unbounded list here is a response whose
        // size tracks how long the install has existed — 5,810 rows / 3.4 MB when
        // this ceiling was added. The default *is* the ceiling rather than a page
        // size: this endpoint has always returned every session, and quietly paging
        // it would truncate existing callers with no signal. `?limit=` asks for
        // less, `?since_hours=` asks for a window (the XPC list path, which the
        // Sessions window uses, always passes one).
        let limit = request.boundedLimit(default: sessionListCeiling, max: sessionListCeiling)
        let sinceHours = request.queryInt("since_hours", default: 0)

        do {
            // `project` goes into the query, never a `.filter` on the result: `limit`
            // is applied by SQL, so filtering afterwards narrows the newest `limit`
            // rows and reports "no sessions" for any project whose sessions sit
            // outside that slice — which, at the default ceiling on an old install,
            // is most of them.
            let sessions = try database.fetchSessions(
                status: statusFilter,
                sinceHours: sinceHours > 0 ? sinceHours : nil,
                project: projectFilter,
                includeEventCount: includeCounts,
                limit: limit
            )
            return .json(sessions)
        } catch {
            return .failure(error)
        }
    }

    private static func getSession(_ id: String, database: DaemonDatabase) -> RouteResponse {
        do {
            guard let detail = try database.fetchSessionDetail(sessionId: id, recentLimit: 20) else {
                return .notFound("Session not found: \(id)")
            }
            return .json(detail)
        } catch {
            return .failure(error)
        }
    }

    private static func sessionEvents(
        _ id: String, _ request: RouteRequest, database: DaemonDatabase
    ) -> RouteResponse {
        let eventType = request.query("type")

        do {
            let events = try database.fetchEvents(
                sessionId: id,
                eventType: eventType,
                limit: request.boundedLimit(default: 50, max: 500),
                offset: request.boundedOffset()
            )
            return .json(events)
        } catch {
            return .failure(error)
        }
    }

    private static func sessionMetrics(_ sessionId: String, database: DaemonDatabase) -> RouteResponse {
        do {
            guard let metrics = try database.metricsForSession(sessionId: sessionId) else {
                return .notFound("No metrics for session: \(sessionId)")
            }
            return .json(metrics)
        } catch {
            return .failure(error)
        }
    }

    private static func getEvent(_ idString: String, database: DaemonDatabase) -> RouteResponse {
        guard let eventId = Int64(idString) else {
            return .error("Invalid event id: \(idString)", status: 400)
        }
        do {
            guard let detail = try database.fetchEventDetail(eventLogId: eventId) else {
                return .notFound("Event not found: \(idString)")
            }
            let body = try JSONSerialization.data(
                withJSONObject: detail,
                options: [.sortedKeys, .prettyPrinted]
            )
            return RouteResponse(status: 200, body: body)
        } catch {
            return .failure(error)
        }
    }

    private static func queryEvents(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let eventType = request.query("type")
        let since = request.query("since")

        do {
            let events = try database.fetchEvents(
                eventType: eventType,
                since: since,
                limit: request.boundedLimit(default: 50, max: 500)
            )
            return .json(events)
        } catch {
            return .failure(error)
        }
    }

    /// `POST /sessions/:id/summarize` — generates and stores an AI summary now,
    /// overriding any existing summary. Returns `{session_id, summary}`.
    private static func summarize(_ sessionId: String, _ services: SessionFeatureServices) async -> RouteResponse {
        do {
            // Honor the injected secret store so the summarize path resolves
            // plugin secrets from the same place the preferences path wrote them (and
            // tests stay off the real Keychain).
            let summary = try await DaemonSessionSummarizer.summarizeAndStore(
                sessionId: sessionId, database: services.database, secretStore: services.secretStore
            )
            return .json(["session_id": sessionId, "summary": summary])
        } catch {
            return .error("Summarize failed: \(error.localizedDescription)", status: 500)
        }
    }
}
#endif
