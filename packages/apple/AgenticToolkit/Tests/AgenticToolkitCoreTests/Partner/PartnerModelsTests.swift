import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("Partner models") struct PartnerModelsTests {
    @Test func fillReplacesKnownAndKeepsUnknown() {
        let filled = PartnerStepTemplate.fill("/code-review high {sha} {nope}", values: ["sha": "abc"])
        #expect(filled == "/code-review high abc {nope}")
    }
    @Test func fillIsOnePassSoAValueIsNeverReSubstituted() {
        let filled = PartnerStepTemplate.fill("{subject} {sha}",
                                              values: ["subject": "fix {sha} {nope}", "sha": "abc"])
        #expect(filled == "fix {sha} {nope} abc")
    }
    @Test func ticksForSameJobCoalesceAndOwnerMessagesDoNot() {
        var queue = PartnerTurnQueue()
        queue.enqueue(.tick(jobID: "a", jobName: "A", previousTick: nil, summary: nil))
        queue.enqueue(.tick(jobID: "a", jobName: "A", previousTick: nil, summary: "2 queued"))
        queue.enqueue(.owner(text: "hi", attribution: nil)); queue.enqueue(.owner(text: "hi", attribution: nil))
        #expect(queue.count == 3)
        #expect(queue.next()?.text.contains("2 queued") == true)
    }
    @Test func sessionIdleCoalescesPerSessionAndKind() {
        var queue = PartnerTurnQueue()
        queue.enqueue(.sessionIdle(sessionID: "s1", title: "t"))
        queue.enqueue(.sessionIdle(sessionID: "s1", title: "t"))
        queue.enqueue(.sessionExited(sessionID: "s1", title: "t"))
        #expect(queue.count == 2)
    }
    @Test func enqueueFirstGoesAheadOfEverything() {
        var queue = PartnerTurnQueue()
        queue.enqueue(.owner(text: "waiting", attribution: nil))
        queue.enqueueFirst(.lifecycle(.turnTimedOut))
        #expect(queue.count == 2)
        #expect(queue.next() == .lifecycle(.turnTimedOut))
        #expect(queue.next()?.text == "waiting")
    }
    @Test func defaultsHaveTheTwoBuiltInJobs() {
        let ids = PartnerJobDefaults.all.map(\.id)
        #expect(ids == ["general", "code-reviews"])
        #expect(PartnerJobDefaults.codeReviews().steps.map(\.name) == ["open session", "review", "fix"])
    }
    @Test func inboundTextNamesTheEvent() {
        #expect(PartnerInbound.sessionExited(sessionID: "s1", title: "review abc").text.contains("s1"))
        #expect(PartnerInbound.lifecycle(.willQuit(endingSessions: ["s1"])).text.contains("quit"))
    }
}
