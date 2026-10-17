#if canImport(AgenticToolkitCore)
import Foundation

/// Recognises a prompt the human typed while the agent was working, in a
/// transcript entry or in a stored transcript line.
///
/// Lives beside the transcript importer and store because both decide, line by
/// line, whether to record one, and a conversation reader makes the same call;
/// there is exactly one rule for it.
public enum QueuedPrompt {

    /// A substring every queued-prompt line contains: the prefilter a scan of
    /// stored lines runs before parsing any. A false positive costs one parse;
    /// ``queuedPrompt(_:)`` is the real test.
    public static let queuedPromptNeedle = "\"queued_command\""

    /// Whether `rawJSON` is a prompt the human typed while the agent was working.
    public static func isQueuedPrompt(rawJSON: String) -> Bool {
        guard let data = rawJSON.data(using: .utf8),
              let entry = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return isQueuedPrompt(entry: entry)
    }

    /// Whether an already-parsed transcript entry is a prompt the human typed
    /// while the agent was working.
    public static func isQueuedPrompt(entry: [String: Any]) -> Bool {
        queuedPrompt(entry) != nil
    }

    /// The content of a prompt the human typed while the agent was working, or
    /// nil when `entry` is anything else.
    ///
    /// Such a prompt never becomes a `user` entry. Claude Code folds it into the
    /// running turn and records it as an `attachment` of type `queued_command`,
    /// so a feed that reads only user and assistant entries loses it. The same
    /// attachment type carries background-task notifications
    /// (`commandMode: task-notification`) and messages from another agent
    /// (`origin.kind: peer`); neither is the human speaking. An attachment with
    /// no `origin` predates the field and is taken as the human's.
    public static func queuedPrompt(_ entry: [String: Any]) -> Any? {
        guard entry["type"] as? String == "attachment",
              let attachment = entry["attachment"] as? [String: Any],
              attachment["type"] as? String == "queued_command",
              attachment["commandMode"] as? String == "prompt"
        else { return nil }
        if let origin = attachment["origin"] as? [String: Any],
           let kind = origin["kind"] as? String, kind != "human" {
            return nil
        }
        return attachment["prompt"]
    }
}
#endif
