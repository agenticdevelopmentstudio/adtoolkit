import Foundation

/// Fills `{key}` placeholders in step commands.
public enum PartnerStepTemplate {
    // swiftlint:disable:next force_try
    private static let placeholder = try! NSRegularExpression(pattern: #"\{(\w+)\}"#)

    /// Replaces each `{key}` that has a value; unknown keys stay as written.
    ///
    /// One pass over the original command: a value is never scanned again, so a value that itself contains
    /// `{key}` (a commit subject someone else wrote, say) is typed as written, not substituted.
    public static func fill(_ command: String, values: [String: String]) -> String {
        let source = command as NSString
        var result = ""
        var cursor = 0
        for match in placeholder.matches(in: command, range: NSRange(location: 0, length: source.length)) {
            let key = source.substring(with: match.range(at: 1))
            guard let value = values[key] else { continue }
            result += source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            result += value
            cursor = match.range.location + match.range.length
        }
        result += source.substring(from: cursor)
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
