import Foundation
import Testing
@testable import AgenticToolkitCore

struct HookEventTypeTests {

    @Test func tableNameIsSnakeCaseWithEventsSuffix() {
        #expect(HookEventType.preToolUse.tableName == "pre_tool_use_events")
    }

    @Test func ambientTypesAreNotActivityAndUnknownTypesAre() {
        #expect(!HookEventType.isActivity("ConfigChange"))
        #expect(HookEventType.isActivity("SomethingNew"))
    }

    @Test func caseCountIsPinned() {
        #expect(HookEventType.allCases.count == 28)
    }
}
