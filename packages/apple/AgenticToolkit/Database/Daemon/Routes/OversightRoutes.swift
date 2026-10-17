#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Oversight findings and the scripts that decide what the observers record.
enum OversightRoutes {

    static func table(_ services: SessionFeatureServices) -> RouteTable {
        let database = services.database
        return RouteTable([
            // Findings the observers have recorded. `?status=pending|acted|dismissed|stale`
            // filters to one lifecycle state; omitted returns all.
            RouteTable.route("GET", where: { $0 == ["oversight", "findings"] }) { request, _ in
                do {
                    return .json(try database.fetchOversightFindings(status: request.query("status")))
                } catch {
                    return .failure(error)
                }
            },
            // `{"pending":N}` — the count a badge polls.
            RouteTable.route("GET", where: { $0 == ["oversight", "findings", "count"] }) { _, _ in
                do {
                    return .json(["pending": try database.oversightFindingCount(status: "pending")])
                } catch {
                    return .failure(error)
                }
            },
            // Whether the finding can be acted on now and, if so, the terminal target
            // to inject into. Always 200 with an `OversightActionTargetDTO` (a `blocked`
            // one when it can't be acted on), so the client uniformly reads
            // `actionable` + `reason`.
            RouteTable.route("GET", where: { $0.count == 4 && $0[0] == "oversight"
                && $0[1] == "findings" && $0[3] == "action" }) { _, components in
                guard let id = Int(components[2]) else { return .error("Invalid finding id", status: 400) }
                return .json(OversightActionService.target(findingId: id, database: database))
            },
            // Record that the finding was acted on (mark it `acted`). 404 if the
            // finding is gone, 409 if it's already resolved.
            RouteTable.route("POST", where: { $0.count == 4 && $0[0] == "oversight"
                && $0[1] == "findings" && $0[3] == "act" }) { _, components in
                act(components[2], database: database)
            },
            RouteTable.route("GET", where: { $0 == ["oversight", "scripts"] }) { _, _ in
                .json(ScriptStore.scripts(database: database))
            },
            RouteTable.route("GET", where: { $0.count == 3 && $0[0] == "oversight" && $0[1] == "scripts" }) {
                _, components in
                guard let script = ScriptStore.script(id: components[2], database: database) else {
                    return .error("Script not found", status: 404)
                }
                return .json(script)
            },
            // `POST /oversight/scripts` (create) and `POST /oversight/scripts/:id`
            // (update) share a body: one whole script. Built-ins updated here are
            // stamped `user_modified` so the shipped upgrader leaves them alone.
            RouteTable.route("POST", where: { $0 == ["oversight", "scripts"] }) { request, _ in
                save(request, database: database)
            },
            RouteTable.route("POST", where: { $0.count == 3 && $0[0] == "oversight" && $0[1] == "scripts" }) {
                request, _ in
                save(request, database: database)
            },
            RouteTable.route("POST", where: { $0.count == 4 && $0[0] == "oversight"
                && $0[1] == "scripts" && $0[3] == "delete" }) { _, components in
                delete(components[2], database: database)
            },
            RouteTable.route("POST", where: { $0.count == 4 && $0[0] == "oversight"
                && $0[1] == "scripts" && $0[3] == "reset" }) { _, components in
                reset(components[2], database: database)
            }
        ])
    }

    private static func act(_ idString: String, database: DaemonDatabase) -> RouteResponse {
        guard let id = Int(idString) else { return .error("Invalid finding id", status: 400) }
        switch OversightActionService.act(findingId: id, database: database) {
        case .acted(let finding):
            return .json(finding)
        case .notFound:
            return .error("Finding not found", status: 404)
        case .notPending(let status):
            return .error("Finding is already \(status)", status: 409)
        case .failed(let message):
            return .error(message, status: 500)
        }
    }

    private static func save(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        guard !request.body.isEmpty else {
            return .error("Missing body: expected an oversight script", status: 400)
        }
        let script: OversightScript
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            script = try decoder.decode(OversightScript.self, from: request.body)
        } catch {
            return .error("Invalid script body: \(error.localizedDescription)", status: 400)
        }
        do {
            return .json(try ScriptStore.save(script, database: database))
        } catch {
            return .error(error.localizedDescription, status: 400)
        }
    }

    private static func delete(_ id: String, database: DaemonDatabase) -> RouteResponse {
        do {
            try ScriptStore.delete(id: id, database: database)
            return .noContent
        } catch ScriptStore.ScriptError.notFound {
            return .error("Script not found", status: 404)
        } catch {
            return .error(error.localizedDescription, status: 400)
        }
    }

    private static func reset(_ id: String, database: DaemonDatabase) -> RouteResponse {
        do {
            return .json(try ScriptStore.reset(id: id, database: database))
        } catch ScriptStore.ScriptError.notFound {
            return .error("Script not found", status: 404)
        } catch {
            return .error(error.localizedDescription, status: 400)
        }
    }
}
#endif
