import XCTest
@testable import AgenticToolkitCore

final class StenographerPreferenceDTOsTests: XCTestCase {

    func testSummaryRequestEncodesSnakeCaseAndOmitsNils() throws {
        var request = SummaryPreferenceRequest()
        request.enabled = false
        request.selectedConfigId = "abc"
        request.maxWords = 12
        let data = try StenographerWire.encoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["enabled"] as? Bool, false)
        XCTAssertEqual(object["selected_config_id"] as? String, "abc")
        XCTAssertEqual(object["max_words"] as? Int, 12)
        XCTAssertNil(object["prompt"])
    }

    func testSummaryResponseDecodesSnakeCase() throws {
        let json = Data("""
        {"enabled":true,"selected_config_id":"","prompt":"p","max_words":8,"activity_lines":60,
         "detail_chars":120,"interval_minutes":5,"max_per_run":5,"timeout_seconds":60}
        """.utf8)
        let response = try StenographerWire.decoder().decode(SummaryPreferenceResponse.self, from: json)
        XCTAssertEqual(response, SummaryPreferenceResponse(
            enabled: true, selectedConfigId: "", prompt: "p", maxWords: 8, activityLines: 60,
            detailChars: 120, intervalMinutes: 5, maxPerRun: 5, timeoutSeconds: 60))
    }

    func testOversightRoundTrip() throws {
        let response = OversightPreferenceResponse(
            enabled: true, contextThresholdPct: 80, llmEnabled: false, selectedConfigId: "claude-cli", model: "")
        let data = try StenographerWire.encoder().encode(response)
        XCTAssertEqual(try StenographerWire.decoder().decode(OversightPreferenceResponse.self, from: data), response)
    }

    func testSessionDTOStillDecodesFromDaemonJSON() throws {
        let json = Data("""
        {"session_id":"s1","cwd":"/x","model":"m","started_at":"2026-10-12T00:00:00Z",
         "last_activity_at":"2026-10-12T00:00:01Z","last_tool":"Bash","status":"active",
         "git_branch":"main","summary":"s","pid":1,"term_program":"iTerm.app",
         "term_session_id":"t","project_root":"/x","event_count":3}
        """.utf8)
        let dto = try StenographerWire.decoder().decode(SessionDTO.self, from: json)
        XCTAssertEqual(dto.sessionId, "s1")
        XCTAssertEqual(dto.eventCount, 3)
    }
}
