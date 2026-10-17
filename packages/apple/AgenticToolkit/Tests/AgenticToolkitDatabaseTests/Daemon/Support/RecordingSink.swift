import AgenticToolkitCore
import Foundation

/// A ``SessionEventSink`` that remembers what it was given, so a test can assert
/// on what ingestion published without a transport.
final class RecordingSink: SessionEventSink, @unchecked Sendable {
    struct Event {
        let eventType: String
        let payload: Data
        let sessionId: String?
    }

    private let lock = NSLock()
    private var recordedEvents: [Event] = []
    private var recordedStatuses: [(sessionId: String, status: SessionStatus)] = []

    var events: [Event] { lock.withLock { recordedEvents } }
    var eventTypes: [String] { lock.withLock { recordedEvents.map(\.eventType) } }
    var statuses: [(sessionId: String, status: SessionStatus)] { lock.withLock { recordedStatuses } }

    func broadcast(eventType: String, payload: Data, sessionId: String?) {
        lock.withLock {
            recordedEvents.append(Event(eventType: eventType, payload: payload, sessionId: sessionId))
        }
    }

    func broadcastSessionStatus(sessionId: String, status: SessionStatus) {
        lock.withLock { recordedStatuses.append((sessionId, status)) }
    }
}
