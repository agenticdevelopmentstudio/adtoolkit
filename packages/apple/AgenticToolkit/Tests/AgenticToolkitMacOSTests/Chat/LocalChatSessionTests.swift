// Tests/AgenticToolkitMacOSTests/Chat/LocalChatSessionTests.swift
import Testing
import Foundation
import AIPluginKit
@testable import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Collects ChatEvents in isolation-safe storage for async tests.
private actor EventCollector {
    private(set) var deltas: [String] = []
    private(set) var finished = false
    private(set) var responseStartedReceived = false
    func appendDelta(_ text: String) { deltas.append(text) }
    func setFinished() { finished = true }
    func setResponseStarted() { responseStartedReceived = true }
}

@Suite("LocalChatSession")
struct LocalChatSessionTests {

    @Test("streams deltas from the injected transport and finishes")
    func streamsAndFinishes() async {
        // Fake transport: yields two text deltas then end, ignoring spec/plugin.
        let factory: LocalChatSession.EventStreamFactory = { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.textDelta("Hel"))
                continuation.yield(.textDelta("lo"))
                continuation.yield(.end(stopReason: "end_turn"))
                continuation.finish()
            }
        }
        let session = LocalChatSession(
            resolvePlugin: { StubPlugin() },
            makeContext: { _ in
                AIChatContext(messages: [], model: "m", systemPrompt: nil, tools: [], config: AIPluginConfig([:]))
            },
            eventStreamFactory: factory,
            toolSource: nil
        )

        let collector = EventCollector()

        let collectorTask = Task {
            for await event in session.events() {
                if case .responseStarted = event { await collector.setResponseStarted() }
                if case .responseDelta(_, let text) = event { await collector.appendDelta(text) }
                if case .responseFinished = event { await collector.setFinished(); break }
            }
        }
        try? await Task.sleep(for: .milliseconds(20))
        session.send("hi")

        // Bounded wait: poll up to ~2 s (200 × 10 ms) so a regression can't hang the suite.
        for _ in 0..<200 {
            if await collector.finished { break }
            try? await Task.sleep(for: .milliseconds(10))
        }
        collectorTask.cancel()
        session.close()

        let deltas = await collector.deltas
        let finished = await collector.finished
        let startedReceived = await collector.responseStartedReceived

        #expect(startedReceived, "expected .responseStarted before deltas")
        #expect(deltas.joined() == "Hello")
        #expect(finished)
    }

    @Test("the tool caller reaches the tool source")
    func toolCallerReachesTheToolSource() async {
        let calls = CallRecorder()
        let source = CallerRecordingSource(calls)
        // First request asks for a tool; the follow-up request (after the
        // result) just ends the turn.
        let requests = RequestCounter()
        let factory: LocalChatSession.EventStreamFactory = { _, _ in
            let first = requests.next() == 0
            return AsyncThrowingStream { continuation in
                if first {
                    continuation.yield(.toolUse(id: "t1", name: "probe", argumentsJSON: Data("{}".utf8)))
                }
                continuation.yield(.end(stopReason: "end_turn"))
                continuation.finish()
            }
        }
        let session = LocalChatSession(
            resolvePlugin: { StubPlugin() },
            makeContext: { _ in
                AIChatContext(messages: [], model: "m", systemPrompt: nil, tools: [], config: AIPluginConfig([:]))
            },
            eventStreamFactory: factory,
            toolSource: source,
            toolCaller: "pane-42"
        )
        let finished = FinishFlag()
        let collectorTask = Task {
            for await event in session.events() {
                if case .stateChanged(.ready) = event, await calls.callers.count > 0 { await finished.set(); break }
            }
        }
        try? await Task.sleep(for: .milliseconds(20))
        session.send("go")
        for _ in 0..<200 {
            if await finished.value { break }
            try? await Task.sleep(for: .milliseconds(10))
        }
        collectorTask.cancel()
        session.close()

        #expect(await calls.callers == ["pane-42"])
    }
}

private actor CallRecorder {
    private(set) var callers: [String?] = []
    func record(_ caller: String?) { callers.append(caller) }
}

private actor FinishFlag {
    private(set) var value = false
    func set() { value = true }
}

private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func next() -> Int { lock.lock(); defer { lock.unlock() }; defer { count += 1 }; return count }
}

private final class CallerRecordingSource: ChatToolSource, @unchecked Sendable {
    private let recorder: CallRecorder
    init(_ recorder: CallRecorder) { self.recorder = recorder }
    func toolDefinitions() async -> [ToolDefinition] {
        let schema = ToolJSONSchema.object(properties: [:])
        return [ToolDefinition(name: "probe", description: "probe", parametersJSONSchema: schema)]
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        await recorder.record(caller)
        return ("ok", false)
    }
}

/// Minimal plugin stub — never actually invoked by the fake factory.
private final class StubPlugin: AIPlugin, @unchecked Sendable {
    init() {}
    func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        .command(executableURL: URL(fileURLWithPath: "/bin/echo"), arguments: [], stdin: nil, environment: [:])
    }
    func makeDecoder() -> any AIStreamDecoder { PassthroughDecoder() }
}

private final class PassthroughDecoder: AIStreamDecoder {
    func consume(_ data: Data) -> [AIStreamEvent] { [] }
}
