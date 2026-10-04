import Foundation

/// The closed set of things a trigger can report. The raw values are the
/// `context_event.kind` column and the detail-table suffixes, so they are the
/// cross-platform schema contract and must stay snake_case.
public enum ContextEventKind: String, Sendable, CaseIterable, Codable {
    case appFocus = "app_focus"
    case window = "window"
    case network = "network"
    case location = "location"
    case input = "input"
    case session = "session"
    case power = "power"
    case appLifecycle = "app_lifecycle"

    /// The detail table this kind's payload is written to.
    public var detailTable: String { "context_event_\(rawValue)" }
}
