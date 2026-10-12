import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class SummarizeReplyMappingTests: XCTestCase {

    final class FailingDaemon: StubDaemonService, @unchecked Sendable {
        var failure: Error?
        override func summarize(sessionId: String) async throws { if let failure { throw failure } }
    }

    func testDaemonReasonIsSurfaced() async {
        let daemon = FailingDaemon()
        daemon.failure = SummarizeDaemonFailure(reason: "model too large")
        do {
            try await StenographerSummarizing(service: daemon).summarize(sessionId: "s")
            XCTFail("expected a throw")
        } catch {
            XCTAssertEqual(error.localizedDescription, "model too large")
        }
    }

    func testTransportFailureHasGenericText() async {
        let daemon = FailingDaemon()
        daemon.failure = URLError(.cannotConnectToHost)
        do {
            try await StenographerSummarizing(service: daemon).summarize(sessionId: "s")
            XCTFail("expected a throw")
        } catch {
            XCTAssertEqual(error.localizedDescription, "the daemon could not generate a summary")
        }
    }
}
