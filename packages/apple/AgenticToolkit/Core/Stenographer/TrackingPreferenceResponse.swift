import Foundation

/// Result of a tracking-preference read/write.
public struct TrackingPreferenceResponse: Encodable, Sendable {
    public let enabled: Bool
    public let disabledMarkerPresent: Bool
    public let outcome: String

    public init(enabled: Bool, disabledMarkerPresent: Bool, outcome: String) {
        self.enabled = enabled
        self.disabledMarkerPresent = disabledMarkerPresent
        self.outcome = outcome
    }
}
