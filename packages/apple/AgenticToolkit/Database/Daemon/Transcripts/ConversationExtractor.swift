#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Turns one captured transcript line into the zero or more conversation lines
/// worth showing a human.
///
/// Pure and static on purpose: the rules below are the whole feature's judgment,
/// and they are only trustworthy if they can be exercised against fixtures
/// without a database, a daemon, or a window.
///
/// ## Why the transcript, and not a summary
///
/// Summarization writes one title per *ended* session; oversight upserts a
/// current-state finding. Neither is a running narration, so there is no stream
/// to surface — the transcript already is the conversation, verbatim.
///
/// ## Reply vs. progress, deterministically
///
/// The open question was whether "output meant for the human" can be told from
/// "the agent narrating its own work" without a classifier watching. It can:
/// `message.stop_reason` separates them cleanly. Measured over twelve live
/// transcripts:
///
/// | `stop_reason`   | text blocks | avg length |
/// |-----------------|-------------|------------|
/// | `end_turn`      | 489         | 1450 chars |
/// | `tool_use`      | 997         | 115 chars  |
/// | `stop_sequence` | 32          | 68 chars   |
/// | `max_tokens`    | 1           | 63 chars   |
///
/// A turn that ends (`end_turn`, and the two truncation stops that also hand the
/// floor back) carries the answer; a turn that stops to call a tool carries the
/// "let me check X" narration. Claude Code writes one entry per content block,
/// so a text block and a `tool_use` block never share an entry — the narration
/// entry still carries `stop_reason: "tool_use"`, which is what makes the split
/// readable off a single field.
///
/// **Only the reply is conversation.** Narration is the agent talking about its
/// own work, and a window for watching people and agents talk has no room for
/// it: what a reader wants under their question is the answer, not the six "let
/// me check X" lines that preceded it. So `progress` joins `thinking` behind the
/// work-output filter, which is off by default — with it off the feed is prompts
/// and replies and nothing else.
///
/// A reply is where a turn ends, which is also where a question to the human is
/// asked, so "the answer" and "the agent asking me something" are the same case
/// and need no rule of their own.
///
/// `stop_reason` is the whole of the signal here, and it will not divide any
/// finer. It says what the model did next, not who it was addressing: a sentence
/// meant for the human and a note about what the agent is about to compile are
/// the same block type with the same stop reason. Everything else the window
/// excludes — thinking, tool calls, tool results — is excluded on block type,
/// which is exact.
public enum ConversationExtractor {

    /// What a conversation line is. Mirrors `ConversationEntryDTO.kind`; the DTO
    /// carries the raw string because it crosses XPC and HTTP, this enum is the
    /// in-daemon vocabulary.
    public enum Kind: String, Sendable, Equatable {
        /// The human typed it.
        case prompt
        /// The agent addressing the human — the end of a turn.
        case reply
        /// The agent narrating its own work mid-turn, before a tool call.
        case progress
        /// Extended thinking.
        case thinking
        /// A transcript event worth a centred status line rather than a bubble.
        case notice

        /// The agent talking about its own work rather than to the human. The
        /// feed's one filter, and the whole of it — see the type's doc.
        public var isWorkOutput: Bool { ConversationEntryDTO.workOutputKinds.contains(rawValue) }
    }

    public struct Line: Sendable, Equatable {
        public let kind: Kind
        public let text: String

        public init(kind: Kind, text: String) {
            self.kind = kind
            self.text = text
        }
    }

    /// The stop reasons that mean the agent handed the floor back to the human.
    /// `max_tokens` and `stop_sequence` are truncations rather than completions,
    /// but the text they leave behind was still addressed to the human — a
    /// quota notice, a cut-off answer — so they read as replies, not narration.
    private static let replyStopReasons: Set<String> = ["end_turn", "max_tokens", "stop_sequence"]

    /// Blocks Claude Code wraps around machinery that is not conversation. Each
    /// is removed whole, tags included, before the remainder is considered.
    private static let strippedTags = [
        "system-reminder",
        "local-command-stdout",
        "command-message",
        "user-prompt-submit-hook"
    ]

    /// Wrappers around text the human *did* mean to say. `<pasted_content
    /// id="4f0a">` marks where they pasted something in from somewhere else —
    /// bookkeeping for the agent, so it knows that stretch was not typed — and
    /// the body inside it is part of the message. So only the markers go; a
    /// block whose body were dropped with them would take half the prompt with
    /// it.
    private static let unwrappedTags = [
        "pasted_content"
    ]

    /// Extracts every showable line from one `transcript_lines.raw_json`.
    ///
    /// Returns an empty array for anything that isn't conversation — a tool
    /// result, a sub-agent's sidechain, a meta entry, a compaction hand-off or
    /// task notification the harness wrote under the user's role, an entry whose
    /// text is nothing but wrappers, or a line that doesn't parse. "Not conversation"
    /// and "malformed" collapse to the same answer deliberately: a feed that
    /// silently skips a line it can't read is right, and one that surfaces
    /// `{"type":…` at the human is not.
    public static func extract(rawJSON: String) -> [Line] {
        guard let data = rawJSON.data(using: .utf8),
              let entry = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }

        // Sub-agent traffic is a different conversation, and meta entries are
        // the harness talking to itself.
        if entry["isSidechain"] as? Bool == true { return [] }
        if entry["isMeta"] as? Bool == true { return [] }
        if isSDKDriven(entry) { return [] }

        // The harness says what it wrote, where it says so. `turnOrigin` and
        // `isCompactSummary` are the entry's own account of not being typed by
        // anybody, and an entry that carries one is dropped without reading a
        // character of it — which is the only test a human *quoting* one of
        // these cannot accidentally answer to.
        //
        // Both fields are recent (122 of the last 5,000 notifications carry
        // `turnOrigin`), so the text tests in `humanLines` stay as the fallback
        // for everything written before them.
        if entry["turnOrigin"] as? String == "task_notification" { return [] }
        if entry["isCompactSummary"] as? Bool == true { return [] }

        if let prompt = QueuedPrompt.queuedPrompt(entry) { return humanLines(content: prompt) }

        guard let message = entry["message"] as? [String: Any] else { return [] }
        switch message["role"] as? String {
        case "user": return humanLines(content: message["content"])
        case "assistant": return agentLines(message)
        default: return []
        }
    }

    /// Whether a program, rather than a person, is holding this end of the
    /// conversation.
    ///
    /// `entrypoint` says how the session was started. A human's is `cli` or
    /// `claude-desktop`; an `sdk-`prefixed one is the SDK or `claude -p` being
    /// driven by a script. Both sides of such a session are machinery: the
    /// "prompt" is the calling program's instructions — 30,000 characters of
    /// them in the case that prompted this rule — and the "reply" is whatever
    /// format that program asked for, routinely a JSON array. Neither is anybody
    /// talking, and either one alone fills the window.
    ///
    /// A prefix rather than an allow-list of the three values seen in a 2.9M-row
    /// transcript table (`cli`, `sdk-cli`, `claude-desktop`): a new editor
    /// integration is a person typing and should appear, a new SDK binding is
    /// not. An entry with no `entrypoint` at all is treated as a person's, so a
    /// field that disappears empties nothing.
    private static func isSDKDriven(_ entry: [String: Any]) -> Bool {
        (entry["entrypoint"] as? String)?.hasPrefix("sdk") == true
    }

    // MARK: - Human side

    /// The human's own words, with the harness's scaffolding taken back off.
    ///
    /// `content` is either a bare string or an array of blocks; a `tool_result`
    /// block anywhere means this entry is a tool's answer wearing the user role,
    /// not a person typing.
    private static func humanLines(content: Any?) -> [Line] {
        var text: String
        switch content {
        case let string as String:
            text = string
        case let blocks as [Any]:
            let dictionaries = blocks.compactMap { $0 as? [String: Any] }
            if dictionaries.contains(where: { $0["type"] as? String == "tool_result" }) { return [] }
            text = dictionaries
                .filter { $0["type"] as? String == "text" }
                .compactMap { $0["text"] as? String }
                .joined()
        default:
            return []
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        // An interrupt is the human's doing and worth seeing, but it is an event,
        // not something they said.
        if text.hasPrefix("[Request interrupted") {
            return [Line(kind: .notice, text: firstLine(of: text))]
        }

        // Two things arrive under the user role that the human did not write,
        // and neither belongs in a record of what people said.
        //
        // A compaction hand-off is the harness re-seeding a session with a
        // summary of what came before — thousands of words, none of them typed.
        // A task notification is the harness telling the agent that one of its
        // background children finished.
        //
        // Both used to be dropped only as far as a one-line notice. In a feed
        // watching a dozen sessions that is still noise: every session compacts,
        // and a session running background work notifies on every completion, so
        // the actual conversation scrolled away behind status lines nobody asked
        // for. They are dropped outright.
        // `extract` drops both structurally, where the entry admits to it
        // (`turnOrigin`, `isCompactSummary`). These two text tests are the
        // fallback for everything written before those fields existed — which,
        // measured live, is most of it: only 122 of 5,000 recent notification
        // entries carry `turnOrigin`.
        //
        // The notification test is a `contains` rather than a prefix because the
        // sub-agent flavour arrives behind a paragraph of `[SYSTEM NOTIFICATION
        // — NOT USER INPUT]` preamble, and a prefix test lets every one of those
        // through (`testATaskNotificationBehindItsSystemPreambleIsStillDropped`).
        // The cost is that a human asking "why does `<task-notification>` arrive
        // twice?" is dropped with them; the structural fields are what will
        // eventually let this test go, not a narrower match on the same text.
        if text.hasPrefix("This session is being continued from a previous conversation") { return [] }
        if text.contains("<task-notification>") { return [] }

        // Strip the harness's wrappers BEFORE looking for a slash command.
        // `<command-name>` turns up inside injected blocks too — a
        // `<system-reminder>` listing the commands a session has run, a
        // `<command-message>` quoting one — and searching the raw text finds
        // those first. The result was that a human's typed prompt was replaced
        // wholesale by a command name they hadn't typed, which is the one thing
        // this feed exists not to do. Stripping first leaves exactly the markup
        // a real slash command is made of, because `command-name`/`command-args`
        // are not among the stripped tags.
        text = stripWrappers(from: text)

        // A slash command arrives as its own markup rather than as typed text.
        // `<command-name>` already carries the leading slash.
        if let name = tagged("command-name", in: text) {
            let arguments = tagged("command-args", in: text)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let rendered = arguments.isEmpty ? name : "\(name) \(arguments)"
            return [Line(kind: .prompt, text: rendered)]
        }

        guard !text.isEmpty else { return [] }
        return [Line(kind: .prompt, text: text)]
    }

    // MARK: - Agent side

    /// One line per content block. `stop_reason` decides what the entry's text
    /// blocks are *for* — see the type's table.
    private static func agentLines(_ message: [String: Any]) -> [Line] {
        guard let blocks = message["content"] as? [Any] else { return [] }
        let stopReason = message["stop_reason"] as? String ?? ""
        let textKind: Kind = replyStopReasons.contains(stopReason) ? .reply : .progress

        var lines: [Line] = []
        for case let block as [String: Any] in blocks {
            switch block["type"] as? String {
            case "text":
                let text = (block["text"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                lines.append(Line(kind: textKind, text: text))
            case "thinking":
                let text = (block["thinking"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                lines.append(Line(kind: .thinking, text: text))
            default:
                continue
            }
        }
        return lines
    }

    // MARK: - Text scrubbing

    /// The contents of the first `<tag>…</tag>` pair, or nil when the pair isn't
    /// there. Deliberately not a regular expression: these tags never nest and
    /// their bodies routinely contain newlines, angle brackets and whole files.
    private static func tagged(_ tag: String, in text: String) -> String? {
        guard let open = text.range(of: "<\(tag)>"),
              let close = text.range(of: "</\(tag)>", range: open.upperBound..<text.endIndex)
        else { return nil }
        return String(text[open.upperBound..<close.lowerBound])
    }

    /// Removes every wrapped block the harness injected, plus the caveat line it
    /// prefixes local-command output with, and trims what's left.
    ///
    /// A prompt that was *nothing but* wrappers comes back empty, and the caller
    /// drops it — that is the whole point: a `/login` whose entire content is a
    /// caveat and the command's stdout is not a thing the human said.
    private static func stripWrappers(from text: String) -> String {
        var result = text
        for tag in strippedTags {
            while let open = result.range(of: "<\(tag)>"),
                  let close = result.range(of: "</\(tag)>", range: open.upperBound..<result.endIndex) {
                result.removeSubrange(open.lowerBound..<close.upperBound)
            }
        }
        for tag in unwrappedTags {
            result = removingMarkers(of: tag, from: result)
        }
        if result.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("Caveat: The messages below") {
            result = String(result.drop(while: { $0 != "\n" }))
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `text` with every `<tag …>` and `</tag …>` marker taken out and
    /// everything between them left where it was.
    ///
    /// Both ends carry the attributes — the close is `</pasted_content
    /// id="4f0a">`, not the bare `</pasted_content>` the XML-shaped
    /// ``tagged(_:in:)`` looks for — so a marker is the exact tag name followed
    /// by one or more whitespace-separated `name="value"` attributes and nothing
    /// else, on one line, closed by `>`. Anything else is kept verbatim: prose
    /// that names the tag (`strip the <pasted_content> markers`), a stray
    /// `<pasted_content` with an `=` and a `>` somewhere later on the line
    /// (`<pasted_content leak? a => b`), or a longer name that merely shares the
    /// prefix (`<pasted_contents id="x">`).
    private static func removingMarkers(of tag: String, from text: String) -> String {
        let name = NSRegularExpression.escapedPattern(for: tag)
        guard let marker = try? NSRegularExpression(
            pattern: "</?\(name)(?:[ \t]+[A-Za-z_][A-Za-z0-9_-]*=\"[^\"\n]*\")+[ \t]*>")
        else { return text }
        let whole = NSRange(text.startIndex..., in: text)
        return marker.stringByReplacingMatches(in: text, range: whole, withTemplate: "")
    }

    private static func firstLine(of text: String) -> String {
        String(text.prefix(while: { $0 != "\n" }))
    }
}
#endif
