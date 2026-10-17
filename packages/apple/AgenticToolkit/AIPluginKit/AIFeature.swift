import Foundation

/// Which daemon feature asked for a completion — the `ai_interactions` log discriminator.
public enum AIFeature: String, Sendable {
    case summarize
    case oversight
}
