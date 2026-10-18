#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure closure_parameter_position

/// The AI interaction log and the Conversations feed.
enum AILogRoutes {

    static func table(_ services: SessionFeatureServices) -> RouteTable {
        let database = services.database
        let conversations = services.conversations
        return RouteTable([
            // Recent LLM calls the daemon made, newest first, long text fields
            // truncated for the list (`truncated` flags a cut row).
            RouteTable.route("GET", where: { $0 == ["ai", "interactions"] }) { request, _ in
                do {
                    return .json(
                        try database.fetchAIInteractions(limit: request.boundedLimit(default: 200, max: 500))
                    )
                } catch {
                    return .failure(error)
                }
            },
            // One interaction with its full prompt/response text.
            RouteTable.route("GET", where: { $0.count == 3 && $0[0] == "ai" && $0[1] == "interactions" }) {
                _, components in
                guard let id = Int(components[2]) else { return .error("Invalid interaction id", status: 400) }
                do {
                    guard let row = try database.fetchAIInteraction(id: id) else {
                        return .error("Interaction not found", status: 404)
                    }
                    return .json(row)
                } catch {
                    return .failure(error)
                }
            },
            // The newest conversation lines across every observed session, newest
            // first, for a group-chat feed.
            //
            // `?work=true` adds the agent's mid-turn narration and its thinking; both
            // are off by default because together they outnumber the replies they
            // surround roughly three to one. `?before=<iso8601>` pages backwards,
            // taking the timestamp of the oldest entry of the previous page.
            // `?session_id=<id>` narrows to one session's conversation — a different
            // query, not a sieve over the merged page, which holds only a fraction of
            // any one session.
            RouteTable.route("GET", where: { $0 == ["conversations"] }) { request, _ in
                do {
                    return .json(
                        try conversations.conversationEntries(
                            limit: request.boundedLimit(default: 200, max: 500),
                            includeWorkOutput: request.query("work") == "true",
                            before: request.query("before"),
                            sessionId: request.query("session_id")
                        )
                    )
                } catch {
                    return .failure(error)
                }
            }
        ])
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure closure_parameter_position
