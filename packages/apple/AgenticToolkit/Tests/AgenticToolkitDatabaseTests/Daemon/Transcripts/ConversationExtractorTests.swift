import XCTest
@testable import AgenticToolkitDatabase

/// Pins the rules that decide what the Conversations window shows a human.
///
/// The feature's whole premise is that "output meant for the human" can be told
/// from "the agent narrating its own work" **deterministically** — no classifier
/// agent watching the transcript. These tests are where that claim is kept
/// honest, so each one names the transcript shape it stands for rather than
/// exercising a code path for coverage's sake.
final class ConversationExtractorTests: XCTestCase {

    // MARK: - Helpers

    private func extract(_ json: String) -> [ConversationExtractor.Line] {
        ConversationExtractor.extract(rawJSON: json)
    }

    private func assistant(stopReason: String, blocks: String) -> String {
        #"{"type":"assistant","message":{"role":"assistant","stop_reason":"\#(stopReason)","content":[\#(blocks)]}}"#
    }

    private func user(_ content: String) -> String {
        #"{"type":"user","message":{"role":"user","content":\#(content)}}"#
    }

    // MARK: - The reply / progress split

    func testTextThatEndsATurnIsAReply() {
        let lines = extract(assistant(
            stopReason: "end_turn",
            blocks: #"{"type":"text","text":"Done — the migration is in."}"#
        ))
        XCTAssertEqual(lines, [.init(kind: .reply, text: "Done — the migration is in.")])
    }

    func testTextBeforeAToolCallIsProgress() {
        // The entry that carries narration still says `tool_use`, because Claude
        // Code writes one entry per content block — the tool call lands in the
        // next one. That is what makes a single field enough to tell them apart.
        let lines = extract(assistant(
            stopReason: "tool_use",
            blocks: #"{"type":"text","text":"Let me check the schema."}"#
        ))
        XCTAssertEqual(lines, [.init(kind: .progress, text: "Let me check the schema.")])
    }

    func testTruncatedTurnsStillReadAsRepliesNotProgress() {
        // `max_tokens` and `stop_sequence` hand the floor back to the human just
        // as `end_turn` does. The text is cut off, but it was addressed to them —
        // quota notices arrive this way, and hiding those would be the worst
        // possible thing to hide.
        for stop in ["max_tokens", "stop_sequence"] {
            let lines = extract(assistant(
                stopReason: stop, blocks: #"{"type":"text","text":"Approaching the limit."}"#
            ))
            XCTAssertEqual(lines.first?.kind, .reply, "stop_reason \(stop)")
        }
    }

    func testAMissingStopReasonIsTreatedAsProgress() {
        // Streaming and interrupted entries can land without one. Progress is the
        // safe default: it is hidden by default, so an unclassifiable line stays
        // out of the feed rather than masquerading as something the agent said.
        let lines = extract(
            #"{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"hm"}]}}"#
        )
        XCTAssertEqual(lines, [.init(kind: .progress, text: "hm")])
    }

    func testThinkingIsItsOwnKindWhateverTheTurnDid() {
        let lines = extract(assistant(
            stopReason: "end_turn",
            blocks: #"{"type":"thinking","thinking":"The user probably means…"},"#
                + #"{"type":"text","text":"Yes."}"#
        ))
        XCTAssertEqual(lines, [
            .init(kind: .thinking, text: "The user probably means…"),
            .init(kind: .reply, text: "Yes.")
        ])
    }

    func testToolUseBlocksProduceNothing() {
        let lines = extract(assistant(
            stopReason: "tool_use",
            blocks: #"{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"ls"}}"#
        ))
        XCTAssertTrue(lines.isEmpty)
    }

    // MARK: - The human side

    func testAPlainStringPromptIsAPrompt() {
        XCTAssertEqual(extract(user(#""great, go""#)),
                       [.init(kind: .prompt, text: "great, go")])
    }

    func testABlockPromptIsAPrompt() {
        XCTAssertEqual(extract(user(#"[{"type":"text","text":"ship it"}]"#)),
                       [.init(kind: .prompt, text: "ship it")])
    }

    func testAToolResultWearingTheUserRoleIsNotSomebodyTalking() {
        // Tool results come back as user-role entries. They are the bulk of the
        // user-role volume and none of it is conversation.
        let lines = extract(user(
            #"[{"type":"tool_result","tool_use_id":"t1","content":"total 0"}]"#
        ))
        XCTAssertTrue(lines.isEmpty)
    }

    func testASlashCommandRendersAsTheCommandTheHumanTyped() {
        // `<command-name>` already carries the leading slash, and the human never
        // sees the markup — they see what they typed.
        let lines = extract(user(
            #""<command-message>cwt</command-message>\n<command-name>/cwt</command-name>\n"#
            + #"<command-args>conversations</command-args>""#
        ))
        XCTAssertEqual(lines, [.init(kind: .prompt, text: "/cwt conversations")])
    }

    func testASlashCommandWithNoArgumentsIsJustTheCommand() {
        let lines = extract(user(#""<command-name>/clear</command-name>""#))
        XCTAssertEqual(lines, [.init(kind: .prompt, text: "/clear")])
    }

    /// A `<system-reminder>` routinely quotes the commands a session has run, so
    /// searching the raw text for `<command-name>` finds the *injected* one
    /// first — and the human's typed prompt was replaced wholesale by a command
    /// they never typed, which is the one thing this feed exists not to do.
    func testACommandNameInsideAnInjectedBlockNeverReplacesTheHumansPrompt() {
        let lines = extract(user(
            #""<system-reminder>earlier: <command-name>/compact</command-name></system-reminder>\n"#
            + #"what changed in the router?""#
        ))
        XCTAssertEqual(lines, [.init(kind: .prompt, text: "what changed in the router?")])
    }

    /// The mirror image: a real slash command still renders as the command,
    /// because `command-name` isn't among the stripped wrappers.
    func testARealSlashCommandSurvivesTheStrippingThatRunsBeforeIt() {
        let lines = extract(user(
            #""<system-reminder>be careful</system-reminder>\n"#
            + #"<command-name>/ship</command-name>\n<command-args>docs</command-args>""#
        ))
        XCTAssertEqual(lines, [.init(kind: .prompt, text: "/ship docs")])
    }

    // MARK: - Pasted content

    /// `<pasted_content id="…">` wraps something the human pasted in. Unlike
    /// every other wrapper here, its body is the message — so the markers go
    /// and the text stays.
    func testPastedContentKeepsItsBodyAndLosesItsMarkers() {
        let lines = extract(user(
            #""look at \n\n<pasted_content id=\"460c\">\nthe router\n"#
            + #"</pasted_content id=\"460c\">\n\n and tell me why""#
        ))
        XCTAssertEqual(lines, [.init(
            kind: .prompt,
            text: "look at \n\n\nthe router\n\n\n and tell me why")])
    }

    /// Several pastes in one prompt, each unwrapped where it stands.
    func testEveryPastedBlockInAPromptIsUnwrapped() {
        let lines = extract(user(
            #""<pasted_content id=\"a1\">first</pasted_content id=\"a1\">"#
            + #" and <pasted_content id=\"b2\">second</pasted_content id=\"b2\">""#
        ))
        XCTAssertEqual(lines, [.init(kind: .prompt, text: "first and second")])
    }

    /// A prompt *about* the tag rather than wrapped in it: no `>` closes the
    /// supposed marker before the next `<`, so nothing is a marker and nothing
    /// is eaten.
    func testProseMentioningTheTagIsLeftAlone() {
        let lines = extract(user(
            #""don't render <pasted_content <- that thing""#
        ))
        XCTAssertEqual(
            lines, [.init(kind: .prompt, text: "don't render <pasted_content <- that thing")])
    }

    /// Naming the tag in prose, a stray open with a `>` further on, and a longer
    /// name sharing the prefix are none of them markers — only the tag followed by
    /// an attribute is.
    func testOnlyAMarkerWithAttributesIsRemoved() {
        for text in [
            "strip the <pasted_content> markers",
            "<pasted_content leak? a => b",
            "the <pasted_contents id=\\\"x\\\"> tag and <pasted_content_v2 id=\\\"y\\\">"
        ] {
            let lines = extract(user("\"\(text)\""))
            let expected = text.replacingOccurrences(of: "\\\"", with: "\"")
            XCTAssertEqual(lines, [.init(kind: .prompt, text: expected)], text)
        }
    }

    func testInjectedWrappersAreStrippedFromWhatTheHumanSaid() {
        let lines = extract(user(
            #""<system-reminder>be careful</system-reminder>\nfix the test""#
        ))
        XCTAssertEqual(lines, [.init(kind: .prompt, text: "fix the test")])
    }

    func testAPromptThatWasNothingButMachineryIsDropped() {
        // `/login`'s echo, for instance: a caveat line and the command's stdout,
        // with not a word from the human in it.
        let lines = extract(user(
            #""Caveat: The messages below were generated by the user while running local commands.\n"#
            + #"<local-command-stdout>Login successful</local-command-stdout>""#
        ))
        XCTAssertTrue(lines.isEmpty)
    }

    func testAnInterruptIsANoticeRatherThanSomethingTheHumanSaid() {
        let lines = extract(user(#""[Request interrupted by user]""#))
        XCTAssertEqual(lines, [.init(kind: .notice, text: "[Request interrupted by user]")])
    }

    func testACompactionHandOffIsNotSomethingTheHumanSaid() {
        // The real thing runs to thousands of words of summary the human never
        // wrote. Every long session compacts, so even the one-line notice this
        // used to collapse to filled the feed with status nobody asked for.
        let lines = extract(user(
            #""This session is being continued from a previous conversation that ran out of "#
            + #"context. The summary below covers the earlier portion.\n\nSummary:\n1. …""#
        ))
        XCTAssertTrue(lines.isEmpty)
    }

    func testATaskNotificationIsTheHarnessTalkingToTheAgent() {
        // Verbatim shape of a main-session notification: a background child
        // finished and the harness says so under the user's role. It reads as
        // the human typing an XML block they have never seen.
        let lines = extract(user(
            #""<task-notification>\n<task-id>afab8cf7c96cde56c</task-id>\n"#
            + #"<status>completed</status>\n"#
            + #"<summary>Agent \"Angle A line-by-line scan\" finished</summary>\n"#
            + #"</task-notification>""#
        ))
        XCTAssertTrue(lines.isEmpty)
    }

    func testATaskNotificationBehindItsSystemPreambleIsStillDropped() {
        // The sub-agent flavour arrives with a paragraph of warning in front of
        // the tag, so matching on a prefix would let this one through.
        let lines = extract(user(
            #""[SYSTEM NOTIFICATION - NOT USER INPUT]\nThis is an automated background-task "#
            + #"event, NOT a message from the user.\n\n<task-notification>\n"#
            + #"<status>completed</status>\n</task-notification>""#
        ))
        XCTAssertTrue(lines.isEmpty)
    }

    /// The harness has started saying, in the entry itself, what it wrote. A
    /// field is a stronger test than a sentence: it survives the wording
    /// changing, and it cannot be typed by a human quoting the feature.
    func testATaskNotificationIsDroppedOnItsOwnFieldWhateverItSays() {
        let lines = extract(
            #"{"type":"user","turnOrigin":"task_notification","message":{"role":"user","#
            + #""content":"Agent finished. Nothing here looks like the tag."}}"#
        )
        XCTAssertTrue(lines.isEmpty)
    }

    func testACompactionHandOffIsDroppedOnItsOwnFieldWhateverItSays() {
        let lines = extract(
            #"{"type":"user","isCompactSummary":true,"message":{"role":"user","#
            + #""content":"Recap: we were rebasing the feature branch."}}"#
        )
        XCTAssertTrue(lines.isEmpty)
    }

    // MARK: - Prompts typed while the agent works

    private func queued(_ prompt: String, mode: String = "prompt", origin: String? = "human") -> String {
        let originField = origin.map { #","origin":{"kind":"\#($0)"}"# } ?? ""
        return #"{"type":"attachment","attachment":{"type":"queued_command","prompt":\#(prompt),"#
            + #""commandMode":"\#(mode)"\#(originField)}}"#
    }

    func testAPromptTypedMidTurnIsAPrompt() {
        // Claude Code folds it into the running turn as an attachment, never as
        // a user entry, so without this rule it was missing from the window.
        XCTAssertEqual(extract(queued(#""also rebase the submodules""#)),
                       [.init(kind: .prompt, text: "also rebase the submodules")])
    }

    func testAMidTurnPromptWithAnImageKeepsItsText() {
        let blocks = #"[{"type":"text","text":"this bubble"},{"type":"image","source":{}}]"#
        XCTAssertEqual(extract(queued(blocks)), [.init(kind: .prompt, text: "this bubble")])
    }

    func testAMidTurnPromptLosesItsPasteMarkers() {
        let text = #""<pasted_content id=\"96cf\">\nAdd these\n</pasted_content id=\"96cf\">""#
        XCTAssertEqual(extract(queued(text)), [.init(kind: .prompt, text: "Add these")])
    }

    func testAMidTurnPromptFromBeforeOriginsExistedIsTheHumans() {
        XCTAssertEqual(extract(queued(#""go on""#, origin: nil)), [.init(kind: .prompt, text: "go on")])
    }

    func testAQueuedTaskNotificationIsNotAPrompt() {
        XCTAssertEqual(extract(queued(#""<task-notification>done</task-notification>""#,
                                      mode: "task-notification", origin: nil)), [])
    }

    func testAQueuedMessageFromAnotherAgentIsNotAPrompt() {
        XCTAssertEqual(extract(queued(#""hello from a peer""#, origin: "peer")), [])
    }

    func testOtherAttachmentsAreNotConversation() {
        XCTAssertEqual(extract(#"{"type":"attachment","attachment":{"type":"hook_success","content":"ok"}}"#), [])
    }

    // MARK: - What is never conversation

    func testSidechainTrafficIsAnotherConversationEntirely() {
        let lines = extract(
            #"{"type":"assistant","isSidechain":true,"message":{"role":"assistant","#
            + #""stop_reason":"end_turn","content":[{"type":"text","text":"subagent says hi"}]}}"#
        )
        XCTAssertTrue(lines.isEmpty)
    }

    func testMetaEntriesAreTheHarnessTalkingToItself() {
        let lines = extract(
            #"{"type":"user","isMeta":true,"message":{"role":"user","content":"#
            + #""<system-reminder>The user named this session \"x\".</system-reminder>"}}"#
        )
        XCTAssertTrue(lines.isEmpty)
    }

    func testAnSDKDrivenSessionIsAProgramTalkingToItself() {
        // Both halves: the instructions the calling program sent, and whatever
        // format it asked back. Neither is anybody talking.
        XCTAssertTrue(extract(
            #"{"type":"user","entrypoint":"sdk-cli","message":{"role":"user","#
            + #""content":"You are reviewing writing the way a careful editor would."}}"#
        ).isEmpty)
        XCTAssertTrue(extract(
            #"{"type":"assistant","entrypoint":"sdk-cli","message":{"role":"assistant","#
            + #""stop_reason":"end_turn","content":[{"type":"text","text":"[{\"title\":\"x\"}]"}]}}"#
        ).isEmpty)
    }

    func testEveryOtherEntrypointIsAPersonAndSoIsAMissingOne() {
        // An allow-list would silence a front end that hasn't shipped yet, and a
        // field that disappeared would empty the window. Only `sdk-` is refused.
        XCTAssertEqual(
            extract(#"{"type":"user","entrypoint":"claude-desktop","message":{"role":"user","content":"hi"}}"#),
            [.init(kind: .prompt, text: "hi")])
        XCTAssertEqual(
            extract(#"{"type":"user","entrypoint":"cli","message":{"role":"user","content":"hi"}}"#),
            [.init(kind: .prompt, text: "hi")])
        XCTAssertEqual(extract(user(#""hi""#)), [.init(kind: .prompt, text: "hi")])
    }

    func testAnUnreadableLineIsSkippedRatherThanSurfaced() {
        XCTAssertTrue(extract("{not json at all").isEmpty)
        XCTAssertTrue(extract("").isEmpty)
        XCTAssertTrue(extract(#"{"type":"summary","summary":"Fixing the parser"}"#).isEmpty)
    }

    func testWhitespaceOnlyTextIsNotALine() {
        XCTAssertTrue(extract(assistant(
            stopReason: "end_turn", blocks: #"{"type":"text","text":"   \n  "}"#
        )).isEmpty)
        XCTAssertTrue(extract(user(#""   ""#)).isEmpty)
    }
}
