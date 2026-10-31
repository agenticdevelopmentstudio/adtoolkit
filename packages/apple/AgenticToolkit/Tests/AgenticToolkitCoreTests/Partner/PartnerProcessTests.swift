import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("PartnerProcess") struct PartnerProcessTests {
    @Test func catEchoDecodesAndTerminateEndsTheStream() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        #expect(await process.isRunning)
        let stream = process.messages()
        let consumer = Task { () -> [ClaudeStreamMessage] in
            var received: [ClaudeStreamMessage] = []
            for await message in stream { received.append(message) }
            return received
        }
        try await process.send("x")
        try await Task.sleep(for: .milliseconds(300))
        await process.terminate()
        #expect(await process.isRunning == false)
        let finished = await withTaskGroup(of: [ClaudeStreamMessage]?.self) { group in
            group.addTask { await consumer.value }
            group.addTask { try? await Task.sleep(for: .seconds(10)); return nil }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        let received = try #require(finished, "terminate() did not end the stream")
        // cat echoes the user line back, which is itself valid stream-json.
        #expect(received.first?.kind == .user && received.first?.blocks.first?.text == "x")
    }

    @Test func secondMessagesCallReturnsAFinishedStream() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        _ = process.messages()
        var count = 0
        for await _ in process.messages() { count += 1 }
        #expect(count == 0)
        await process.terminate()
    }

    @Test func undecodableLinesAreSkipped() async throws {
        let process = PartnerProcess(executable: "/bin/echo", arguments: ["not json"], environment: [:])
        try await process.start()
        var count = 0
        for await _ in process.messages() { count += 1 }
        #expect(count == 0)
    }

    @Test func resultLineDecodes() async throws {
        let line = #"{"type":"result","subtype":"success","is_error":false,"result":"ok","session_id":"s"}"#
        let process = PartnerProcess(executable: "/bin/echo", arguments: [line], environment: [:])
        try await process.start()
        var got: [ClaudeStreamMessage] = []
        for await message in process.messages() { got.append(message) }
        #expect(got.count == 1 && got[0].kind == .result && got[0].resultText == "ok")
    }
}
