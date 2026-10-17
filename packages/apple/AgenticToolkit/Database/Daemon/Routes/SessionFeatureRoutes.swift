#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// The HTTP surface of the session-daemon core: sessions and events, ingestion,
/// import, preferences, oversight, the AI log and the Conversations feed.
///
/// A daemon mounts ``table(_:)`` ahead of its own routes and bridges the
/// `RouteResponse` into its transport. Live event streaming (SSE) is a transport
/// concern and stays outside this table.
public enum SessionFeatureRoutes {

    /// Most sessions `GET /sessions` will ever return in one response. A ceiling
    /// and not a page size: that endpoint has always returned every session, so
    /// quietly paging it would truncate existing callers with no signal.
    public static let sessionListCeiling = 10_000

    /// Every route the session-daemon core serves, built from `services`.
    public static func table(_ services: SessionFeatureServices) -> RouteTable {
        SessionRoutes.table(services)
            .merging(IngestRoutes.table(services))
            .merging(ImportRoutes.table(services))
            .merging(PreferenceRoutes.table(services))
            .merging(OversightRoutes.table(services))
            .merging(AILogRoutes.table(services))
    }

    /// Whether a path can be answered while the database migrates: the routes
    /// that touch no schema. A daemon whose listener comes up ahead of its
    /// migration gates everything else behind readiness.
    ///
    /// `hook/*` is the one that matters: a native `http` hook neither retries nor
    /// spools, so a delivery refused during a migration is an event destroyed, not
    /// delayed. It is servable because it writes to the capture spool, which has no
    /// migrations to wait for.
    public static func isServableWhileMigrating(_ pathComponents: [String]) -> Bool {
        if pathComponents.isEmpty { return true }                       // endpoint index
        if pathComponents.count == 2, pathComponents[0] == "hook" { return true }
        return pathComponents == ["health"] || pathComponents == ["ingestion", "spool"]
    }
}
#endif
