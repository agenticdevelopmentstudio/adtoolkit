#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// The `/preferences/*` reads and writes. The business rules live in
/// `PreferencesService`, shared with the XPC surface; this only decodes and replies.
enum PreferenceRoutes {

    private struct TrackingPreferenceRequest: Decodable, Sendable {
        let enabled: Bool
    }

    static func table(_ services: SessionFeatureServices) -> RouteTable {
        let preferences = services.preferences
        return RouteTable([
            RouteTable.route("GET", where: { $0 == ["preferences", "tracking"] }) { _, _ in
                .json(preferences.currentTracking())
            },
            RouteTable.route("POST", where: { $0 == ["preferences", "tracking"] }) { request, _ in
                setTracking(request, preferences)
            },
            // The daemon's known provider-config identities (registry index).
            // Secret-free: no field values or credentials.
            RouteTable.route("GET", where: { $0 == ["preferences", "ai", "configs"] }) { _, _ in
                .json(preferences.storedConfigurations())
            },
            RouteTable.route("GET", where: { $0 == ["preferences", "ai"] }) { _, _ in
                .json(preferences.currentAIPreferences())
            },
            RouteTable.route("POST", where: { $0 == ["preferences", "ai"] }) { request, _ in
                setAI(request, preferences)
            },
            RouteTable.route("GET", where: { $0 == ["preferences", "oversight"] }) { _, _ in
                .json(preferences.currentOversight())
            },
            RouteTable.route("POST", where: { $0 == ["preferences", "oversight"] }) { request, _ in
                setOversight(request, preferences)
            },
            RouteTable.route("GET", where: { $0 == ["preferences", "summaries"] }) { _, _ in
                .json(preferences.currentSummary())
            },
            RouteTable.route("POST", where: { $0 == ["preferences", "summaries"] }) { request, _ in
                setSummary(request, preferences)
            }
        ])
    }

    private static func snakeCaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// `POST /preferences/tracking` — body: `{"enabled": Bool}`. Performs the hook
    /// install/uninstall. The app still owns the cross-process tracking-disabled
    /// marker (so a toggle while the daemon is offline self-heals at the daemon's
    /// next boot); this endpoint is the live-enforcement path.
    private static func setTracking(_ request: RouteRequest, _ preferences: PreferencesService) -> RouteResponse {
        guard !request.body.isEmpty else {
            return .error("Missing body: expected {\"enabled\": Bool}", status: 400)
        }
        let decoded: TrackingPreferenceRequest
        do {
            decoded = try JSONDecoder().decode(TrackingPreferenceRequest.self, from: request.body)
        } catch {
            return .error("Invalid tracking preference body: \(error.localizedDescription)", status: 400)
        }
        do {
            return .json(try preferences.setTracking(enabled: decoded.enabled))
        } catch PreferencesService.PreferencesError.hookInstallFailed(let message) {
            return .error("Hook install failed: \(message)", status: 500)
        } catch PreferencesService.PreferencesError.passiveInstance {
            return .error("this daemon instance does not manage hooks", status: 409)
        } catch {
            return .error("Tracking update failed: \(error.localizedDescription)", status: 500)
        }
    }

    /// `POST /preferences/ai` — body: an `AIProviderConfigSync` JSON object with
    /// camelCase keys (`{enabled, selectedConfigId?, configs:[{id, name,
    /// pluginIdentifier, templateId, model, values, secrets}]}`, encoded by a plain
    /// `JSONEncoder`). Reconciles the daemon's provider-config registry against the
    /// pushed set: `secrets` go to the daemon's Keychain namespace; the body is never
    /// logged (it carries plugin API keys in the clear over loopback). A malformed
    /// body returns 400 (no partial wipe). The reply echoes a separate, secret-free
    /// snake_case summary, not this full sync shape.
    private static func setAI(_ request: RouteRequest, _ preferences: PreferencesService) -> RouteResponse {
        guard !request.body.isEmpty else {
            return .error("Missing body: expected an AIProviderConfigSync JSON object", status: 400)
        }
        guard preferences.applyAIProviderSync(from: request.body) else {
            return .error("Malformed body: expected an AIProviderConfigSync JSON object", status: 400)
        }
        return .json(preferences.currentAIPreferences())
    }

    /// `POST /preferences/oversight` — body `{enabled?, context_threshold_pct?,
    /// llm_enabled?, selected_config_id?, model?}`. Omitted fields are left unchanged
    /// ("" is a meaningful write for the selection/model). Replies the resulting state.
    private static func setOversight(_ request: RouteRequest, _ preferences: PreferencesService) -> RouteResponse {
        guard !request.body.isEmpty else {
            return .error(
                "Missing body: expected {\"enabled\": Bool} and/or {\"context_threshold_pct\": Int}",
                status: 400
            )
        }
        let decoded: OversightPreferenceRequest
        do {
            decoded = try snakeCaseDecoder().decode(OversightPreferenceRequest.self, from: request.body)
        } catch {
            return .error("Invalid oversight preference body: \(error.localizedDescription)", status: 400)
        }
        return .json(preferences.setOversight(decoded))
    }

    /// `POST /preferences/summaries` — body `{prompt?, max_words?, activity_lines?,
    /// detail_chars?, interval_minutes?, max_per_run?, timeout_seconds?}`. Omitted
    /// fields are left unchanged, numbers are clamped to their accepted ranges, and
    /// `"prompt": ""` restores the shipped template. Replies the effective state.
    private static func setSummary(_ request: RouteRequest, _ preferences: PreferencesService) -> RouteResponse {
        guard !request.body.isEmpty else {
            return .error(
                "Missing body: expected any of {\"prompt\": String, \"max_words\": Int, …}",
                status: 400
            )
        }
        let decoded: SummaryPreferenceRequest
        do {
            decoded = try snakeCaseDecoder().decode(SummaryPreferenceRequest.self, from: request.body)
        } catch {
            return .error("Invalid summary preference body: \(error.localizedDescription)", status: 400)
        }
        return .json(preferences.setSummary(decoded))
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
