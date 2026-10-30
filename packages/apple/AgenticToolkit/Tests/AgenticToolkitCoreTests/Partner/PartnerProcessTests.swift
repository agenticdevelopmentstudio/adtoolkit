import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("PartnerProcess") struct PartnerProcessTests {
    @Test func catEchoDecodesAndTerminateEndsTheStream() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        #expect(await process.isRunning)
        try await process.send("x")
        var received: [ClaudeStreamMessage] = []
        for await message in process.messages() {
            received.append(message)
            break
        }
        // cat echoes the user line back, which is itself valid stream-json.
        #expect(received.first?.kind == .user && received.first?.blocks.first?.text == "x")
        await process.terminate()
        #expect(await process.isRunning == false)
        var rest = 0
        for await _ in process.messages() { rest += 1 }
        #expect(rest == 0)
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
