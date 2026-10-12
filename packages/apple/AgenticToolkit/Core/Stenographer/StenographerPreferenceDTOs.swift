import Foundation

/// `POST /preferences/oversight` body. Every field optional: an omitted field
/// leaves the daemon's stored value alone (the snapshot push always sends all).
public struct OversightPreferenceRequest: Codable, Sendable {
    public var enabled: Bool?
    public var contextThresholdPct: Int?
    public var llmEnabled: Bool?
    public var selectedConfigId: String?
    public var model: String?

    public init(
        enabled: Bool? = nil, contextThresholdPct: Int? = nil, llmEnabled: Bool? = nil,
        selectedConfigId: String? = nil, model: String? = nil
    ) {
        self.enabled = enabled
        self.contextThresholdPct = contextThresholdPct
        self.llmEnabled = llmEnabled
        self.selectedConfigId = selectedConfigId
        self.model = model
    }
}

/// `GET /preferences/oversight` and the reply to the POST: what the daemon runs with.
public struct OversightPreferenceResponse: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let contextThresholdPct: Int
    public let llmEnabled: Bool
    public let selectedConfigId: String
    public let model: String

    public init(enabled: Bool, contextThresholdPct: Int, llmEnabled: Bool, selectedConfigId: String, model: String) {
        self.enabled = enabled
        self.contextThresholdPct = contextThresholdPct
        self.llmEnabled = llmEnabled
        self.selectedConfigId = selectedConfigId
        self.model = model
    }
}

/// `POST /preferences/summaries` body. `enabled` and `selectedConfigId` are the
/// summaries switch and provider choice, owned by whichever app shows the AI
/// Summaries pane (the Kitchen); the rest are the tuning knobs, clamped by the
/// daemon through ``SummaryLimits``. All optional: omitted = unchanged.
public struct SummaryPreferenceRequest: Codable, Sendable {
    public var enabled: Bool?
    public var selectedConfigId: String?
    public var prompt: String?
    public var maxWords: Int?
    public var activityLines: Int?
    public var detailChars: Int?
    public var intervalMinutes: Int?
    public var maxPerRun: Int?
    public var timeoutSeconds: Int?

    public init(
        enabled: Bool? = nil, selectedConfigId: String? = nil, prompt: String? = nil,
        maxWords: Int? = nil, activityLines: Int? = nil, detailChars: Int? = nil,
        intervalMinutes: Int? = nil, maxPerRun: Int? = nil, timeoutSeconds: Int? = nil
    ) {
        self.enabled = enabled
        self.selectedConfigId = selectedConfigId
        self.prompt = prompt
        self.maxWords = maxWords
        self.activityLines = activityLines
        self.detailChars = detailChars
        self.intervalMinutes = intervalMinutes
        self.maxPerRun = maxPerRun
        self.timeoutSeconds = timeoutSeconds
    }
}

/// `GET /preferences/summaries` and the reply to the POST.
public struct SummaryPreferenceResponse: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let selectedConfigId: String
    public let prompt: String
    public let maxWords: Int
    public let activityLines: Int
    public let detailChars: Int
    public let intervalMinutes: Int
    public let maxPerRun: Int
    public let timeoutSeconds: Int

    public init(
        enabled: Bool, selectedConfigId: String, prompt: String, maxWords: Int, activityLines: Int,
        detailChars: Int, intervalMinutes: Int, maxPerRun: Int, timeoutSeconds: Int
    ) {
        self.enabled = enabled
        self.selectedConfigId = selectedConfigId
        self.prompt = prompt
        self.maxWords = maxWords
        self.activityLines = activityLines
        self.detailChars = detailChars
        self.intervalMinutes = intervalMinutes
        self.maxPerRun = maxPerRun
        self.timeoutSeconds = timeoutSeconds
    }
}
