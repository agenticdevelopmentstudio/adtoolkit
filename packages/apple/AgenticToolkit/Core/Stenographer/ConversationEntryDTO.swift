import Foundation

/// One line of the conversation between a human and an observed Claude session,
/// extracted from the captured transcript (`transcript_lines`) rather than from
/// any summarization pass — the transcript already *is* the conversation, and a
/// summary would be one sentence per ended session, not a running feed.
///
/// The Conversations window renders these as a group chat: every observed
/// session's dialogue interleaved on one timeline, each row labelled with the
/// project, branch and session name it came from.
///
/// Attribution travels with the entry rather than being looked up per row: the
/// feed spans many sessions, so a row without it cannot be labelled, and the
/// join that supplies it costs nothing at query time.
public struct ConversationEntryDTO: Codable, Sendable, Equatable {
    /// Stable row identity: `transcript_lines.id * 1000` plus the block's index
    /// within that entry, because one captured entry can yield more than one
    /// line. The index is the block's position in the *unfiltered* entry, so it
    /// doesn't move when the caller changes what it asks to see. Identity only —
    /// pages are cut on ``timestamp``, not on this.
    public let id: Int
    public let sessionId: String
    /// What this line is: `prompt` (the human typed it) | `reply` (the agent
    /// addressed the human) | `progress` (the agent narrating its own work
    /// mid-turn) | `thinking` (extended thinking) | `notice` (an interruption or
    /// other transcript event worth showing).
    ///
    /// One field rather than three flags: the combinations are mutually
    /// exclusive and a boolean triple would admit states that cannot happen.
    public let kind: String
    public let text: String
    /// ISO-8601, as written in the transcript.
    public let timestamp: String
    /// Last path component of the session's project root ("" when unknown).
    public let projectName: String
    /// The session's git branch ("" when not in a repo).
    public let gitBranch: String
    /// The session's title ("" when it has none). Never its summary: that says
    /// what the session is doing, not what it is called.
    public let sessionName: String
    /// The session's `TERM_PROGRAM` ("" when unknown) — which terminal it is
    /// running in, so a row can be headed with that application's icon the way
    /// the Sessions window heads its own.
    public let termProgram: String

    /// True when the human wrote it. The one place the `kind` vocabulary is
    /// folded into the two-sided split a chat transcript needs, shared by the
    /// bubble's side selection and its icon.
    public var isFromUser: Bool { kind == "prompt" }

    /// True for the two kinds that narrate the agent's work rather than address
    /// the human. Both are off by default in the window — they outnumber the
    /// replies roughly three to one.
    public var isWorkOutput: Bool { Self.workOutputKinds.contains(kind) }

    /// The kinds that are work output — the one list the daemon's filter and
    /// the app's mapping both read, so a kind added to one cannot be missed by
    /// the other.
    public static let workOutputKinds: Set<String> = ["progress", "thinking"]

    public init(
        id: Int,
        sessionId: String,
        kind: String,
        text: String,
        timestamp: String,
        projectName: String,
        gitBranch: String,
        sessionName: String,
        termProgram: String = ""
    ) {
        self.id = id
        self.sessionId = sessionId
        self.kind = kind
        self.text = text
        self.timestamp = timestamp
        self.projectName = projectName
        self.gitBranch = gitBranch
        self.sessionName = sessionName
        self.termProgram = termProgram
    }

    private enum CodingKeys: String, CodingKey {
        case id, sessionId, kind, text, timestamp
        case projectName, gitBranch, sessionName, termProgram
    }

    /// Tolerant decode: this DTO crosses the app↔daemon boundary, and the two
    /// binaries are installed separately, so an app can be newer than the
    /// daemon answering it. Swift's synthesized `Decodable` does not fall back
    /// to a property's default for a missing key — it throws `keyNotFound`,
    /// which here would blank the whole feed over one field. The fields that
    /// have always been there stay required; the ones added later decode to
    /// their absence, which is the same "" the daemon sends when it has
    /// nothing to say.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.kind = try container.decode(String.self, forKey: .kind)
        self.text = try container.decode(String.self, forKey: .text)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
        self.projectName = try container.decode(String.self, forKey: .projectName)
        self.gitBranch = try container.decode(String.self, forKey: .gitBranch)
        self.sessionName = try container.decode(String.self, forKey: .sessionName)
        self.termProgram = try container.decodeIfPresent(String.self, forKey: .termProgram) ?? ""
    }
}
