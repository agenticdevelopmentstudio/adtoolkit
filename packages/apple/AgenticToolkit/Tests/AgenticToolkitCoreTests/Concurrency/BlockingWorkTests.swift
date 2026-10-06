import Testing
import Foundation
@testable import AgenticToolkitCore

@Suite("BlockingWork")
struct BlockingWorkTests {
    @Test("returns what the work returned")
    func returnsValue() async {
        let value = await BlockingWork.run { 42 }
        #expect(value == 42)
    }

    @Test("rethrows what the work threw")
    func rethrowsWhatTheWorkThrew() async {
        struct Boom: Error {}
        await #expect(throws: Boom.self) {
            try await BlockingWork.run { () throws -> Int in throw Boom() }
        }
    }

    /// Without `enforcedQoS` a block submitted from a user-interactive caller
    /// would run at that class; enforced, it runs at default.
    @Test("enforcedQoS pins the block's class whatever the caller's is")
    func enforcedQoSPinsTheClass() async {
        let observed = await Task(priority: .high) {
            await BlockingWork.run(qos: .default, enforcedQoS: .default) { qos_class_self().rawValue }
        }.value
        #expect(observed == QOS_CLASS_DEFAULT.rawValue)
    }
}
