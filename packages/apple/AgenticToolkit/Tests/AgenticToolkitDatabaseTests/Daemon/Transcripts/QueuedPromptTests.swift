import XCTest
@testable import AgenticToolkitDatabase

final class QueuedPromptTests: XCTestCase {

    private func attachment(_ fields: String) -> String {
        #"{"type":"attachment","attachment":{"type":"queued_command",\#(fields)}}"#
    }

    func testNeedleDetectsAQueuedCommandLine() {
        let raw = attachment(#""commandMode":"prompt","prompt":"hello""#)
        XCTAssertTrue(QueuedPrompt.isQueuedPrompt(rawJSON: raw))
    }

    func testPeerAndTaskNotificationsAreNotTheHuman() {
        let peer = attachment(#""commandMode":"prompt","origin":{"kind":"peer"},"prompt":"x""#)
        let task = attachment(#""commandMode":"task-notification","prompt":"x""#)
        XCTAssertFalse(QueuedPrompt.isQueuedPrompt(rawJSON: peer))
        XCTAssertFalse(QueuedPrompt.isQueuedPrompt(rawJSON: task))
    }

    func testOrdinaryLineIsNotAQueuedPrompt() {
        let raw = #"{"type":"user","message":{"role":"user","content":"hello"}}"#
        XCTAssertFalse(QueuedPrompt.isQueuedPrompt(rawJSON: raw))
    }

    func testEntryWithoutAnAttachmentIsNotAQueuedPrompt() {
        XCTAssertFalse(QueuedPrompt.isQueuedPrompt(entry: ["type": "user"]))
        XCTAssertNil(QueuedPrompt.queuedPrompt(["type": "user"]))
    }
}
