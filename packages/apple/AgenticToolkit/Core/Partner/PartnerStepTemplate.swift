import Foundation

/// Fills `{key}` placeholders in step commands.
public enum PartnerStepTemplate {
    /// Replaces each `{key}` that has a value; unknown keys stay as written.
    public static func fill(_ command: String, values: [String: String]) -> String {
        var result = command
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }

    public static func fill(_ steps: [PartnerJobStep], values: [String: String]) -> [PartnerJobStep] {
        steps.map { step in
            var filled = step
            filled.command = fill(step.command, values: values)
            return filled
        }
    }
}
