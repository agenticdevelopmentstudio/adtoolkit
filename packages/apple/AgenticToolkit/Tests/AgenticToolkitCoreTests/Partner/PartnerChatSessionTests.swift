import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("PartnerChatSession") struct PartnerChatSessionTests {
    private func session(_ initial: [ChatMessage] = []) -> PartnerChatSession {
        PartnerChatSession(initial: initial, send: { _ in }, interrupt: {})
    }
    private func assistant(_ blocks: [ClaudeStreamMessage.Block]) -> ClaudeStreamMessage {
        .init(kind: .assistant, subtype: nil, sessionID: "s", blocks: blocks, isError: false, resultText: nil)
    }

    @Test func assistantTextBecomesAStreamedMessage() async {
        let chat = session()
        var events: [ChatEvent] = []
        let stream = chat.events()
        let persisted = chat.apply(assistant([.init(kind: .text, text: "hello", name: nil, id: nil, toolUseID: nil)]))
        for await event in stream.prefix(4) { events.append(event) }
        #expect(persisted.count == 1 && persisted[0].role == .assistant && persisted[0].text == "hello")
        #expect(events.contains { if case .responseDelta(_, let text) = $0 { return text == "hello" }; return false })
    }

    @Test func toolUseThenToolResultEmitStartedAndCompleted() async {
        let chat = session()
        var events: [ChatEvent] = []
        let stream = chat.events()
        _ = chat.apply(assistant([.init(kind: .toolUse, name: "n", id: "t1")]))
        _ = chat.apply(.init(kind: .user, blocks: [.init(kind: .toolResult, toolUseID: "t1")]))
        for await event in stream.prefix(3) { events.append(event) }
        #expect(events.contains { if case .toolCall(_, "n", .started) = $0 { return true }; return false })
        #expect(events.contains { if case .toolCall(_, "n", .completed) = $0 { return true }; return false })
    }

    @Test func errorResultEmitsTurnFailedAndReadyState() async {
        let chat = session()
        var events: [ChatEvent] = []
        let stream = chat.events()
        _ = chat.apply(.init(kind: .result, subtype: "error_max_turns", isError: true, resultText: "boom"))
        for await event in stream.prefix(3) { events.append(event) }
        #expect(events[1] == .turnFailed(ChatError(message: "boom", isRetryable: true)))
        #expect(events[2] == .stateChanged(.ready))
    }

    @Test func initialTranscriptIsReplayedOnSubscribe() async {
        let note = ChatMessage(role: .user, text: "earlier")
        var first: ChatEvent?
        for await event in session([note]).events() { first = event; break }
        #expect(first == .transcriptLoaded([note]))
    }

    @Test func ownerEchoProducesNothingAndUserNoteEmits() async {
        let chat = session()
        let stream = chat.events()
        #expect(chat.apply(.init(kind: .user, blocks: [.init(kind: .text, text: "hi")])).isEmpty)
        let note = ChatMessage(role: .user, text: "hi")
        chat.noteUserMessage(note)
        var events: [ChatEvent] = []
        for await event in stream.prefix(2) { events.append(event) }
        #expect(events[1] == .userMessage(note))
    }
}
