import Foundation

/// One labelled value in an event's full detail listing.
///
/// A named type rather than a `(String, String)` tuple so the result is
/// `Equatable` and a test can assert against it directly.
public struct ContextEventField: Sendable, Equatable {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    /// What an absent optional shows as. The listing keeps the field rather
    /// than dropping it: "this event has no window title" and "this kind of
    /// event has no window title at all" are different facts, and a pane that
    /// omitted the row would say the second when it meant the first.
    public static let empty = "—"
}

/// Every field an event carries, labelled, in display order.
///
/// The counterpart to ``ContextEventSummary``, not a replacement for it.
/// `summary` collapses a detail into a short subject and a joined tail for a
/// table column, dropping fields on the way; this drops nothing. Both live in
/// AgenticToolkitActivity for the same reason: "what does this row say" is a question every
/// client has and none should answer in its own view code.
public extension ContextEventDetail {
    var fields: [ContextEventField] {
        switch self {
        case .appFocus(let d):
            return [
                ContextEventField(label: "App name", value: Self.text(d.appName)),
                ContextEventField(label: "Bundle id", value: Self.text(d.bundleID)),
                ContextEventField(label: "Process id", value: "\(d.pid)"),
                ContextEventField(label: "Executable", value: Self.text(d.executablePath)),
                ContextEventField(label: "Window id", value: Self.number(d.windowID)),
                ContextEventField(label: "Window title", value: Self.text(d.windowTitle)),
                ContextEventField(label: "Document path", value: Self.text(d.documentPath)),
                ContextEventField(label: "Document size", value: Self.number(d.documentSize)),
                ContextEventField(label: "Document modified", value: Self.timestamp(d.documentModifiedAt)),
                ContextEventField(label: "Document type", value: Self.text(d.documentType)),
                ContextEventField(label: "URL", value: Self.text(d.url))
            ]

        case .window(let d):
            return [
                ContextEventField(label: "Change", value: d.change.rawValue),
                ContextEventField(label: "App name", value: Self.text(d.appName)),
                ContextEventField(label: "Bundle id", value: Self.text(d.bundleID)),
                ContextEventField(label: "Process id", value: "\(d.pid)"),
                ContextEventField(label: "Window id", value: "\(d.windowID)"),
                ContextEventField(label: "Window title", value: Self.text(d.windowTitle))
            ]

        case .network(let d):
            return [
                ContextEventField(label: "Interface", value: d.interfaceType.rawValue),
                ContextEventField(label: "Reachable", value: d.isSatisfied ? "yes" : "no"),
                ContextEventField(label: "SSID", value: Self.text(d.ssid)),
                ContextEventField(label: "BSSID", value: Self.text(d.bssid)),
                ContextEventField(label: "Expensive", value: Self.flag(d.isExpensive)),
                ContextEventField(label: "Constrained", value: Self.flag(d.isConstrained))
            ]

        case .location(let d):
            return [
                ContextEventField(label: "Latitude", value: Self.fixed(d.latitude, places: 6)),
                ContextEventField(label: "Longitude", value: Self.fixed(d.longitude, places: 6)),
                ContextEventField(label: "Horizontal accuracy", value: Self.decimal(d.horizontalAccuracy, places: 1)),
                ContextEventField(label: "Altitude", value: Self.decimal(d.altitude, places: 1)),
                ContextEventField(label: "Vertical accuracy", value: Self.decimal(d.verticalAccuracy, places: 1)),
                ContextEventField(label: "Speed", value: Self.decimal(d.speed, places: 2)),
                ContextEventField(label: "Course", value: Self.decimal(d.course, places: 1))
            ]

        case .input(let d):
            return [
                ContextEventField(label: "Change", value: d.change.rawValue),
                ContextEventField(label: "Idle seconds", value: Self.decimal(d.idleSeconds, places: 1)),
                ContextEventField(label: "Seconds since key", value: Self.decimal(d.secondsSinceKey, places: 1)),
                ContextEventField(label: "Seconds since mouse move", value: Self.decimal(d.secondsSinceMouseMove, places: 1)),
                ContextEventField(label: "Seconds since click", value: Self.decimal(d.secondsSinceClick, places: 1)),
                ContextEventField(label: "Seconds since scroll", value: Self.decimal(d.secondsSinceScroll, places: 1)),
                ContextEventField(label: "Key count", value: Self.number(d.keyCountDelta)),
                ContextEventField(label: "Mouse count", value: Self.number(d.mouseCountDelta)),
                ContextEventField(label: "Interval (ms)", value: Self.number(d.intervalMs))
            ]

        case .session(let d):
            return [ContextEventField(label: "Change", value: d.change.rawValue)]

        case .power(let d):
            return [
                ContextEventField(label: "Source", value: d.source.rawValue),
                ContextEventField(label: "Percent", value: Self.number(d.percent)),
                ContextEventField(label: "Charging", value: Self.flag(d.isCharging))
            ]

        case .appLifecycle(let d):
            return [
                ContextEventField(label: "Change", value: d.change.rawValue),
                ContextEventField(label: "App name", value: Self.text(d.appName)),
                ContextEventField(label: "Bundle id", value: Self.text(d.bundleID)),
                ContextEventField(label: "Process id", value: "\(d.pid)")
            ]
        }
    }

    // MARK: - Formatting helpers

    private static func text(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return ContextEventField.empty }
        return value
    }

    private static func number(_ value: (some BinaryInteger)?) -> String {
        value.map { "\($0)" } ?? ContextEventField.empty
    }

    private static func flag(_ value: Bool?) -> String {
        value.map { $0 ? "yes" : "no" } ?? ContextEventField.empty
    }

    private static func decimal(_ value: Double?, places: Int) -> String {
        value.map { fixed($0, places: places) } ?? ContextEventField.empty
    }

    /// `String(format:)` with an explicit POSIX locale, for the same reason
    /// ``ContextEventSummary`` uses one: these values are read next to raw
    /// database contents, and a locale that rendered `12,5` would not
    /// round-trip against them.
    private static func fixed(_ value: Double, places: Int) -> String {
        String(format: "%.\(places)f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private static func timestamp(_ value: Date?) -> String {
        value.map(ISO8601Timestamp.string(from:)) ?? ContextEventField.empty
    }
}

public extension ContextEventRecord {
    /// The record's own identity fields, then its detail's. What the preview
    /// pane renders top to bottom.
    var fields: [ContextEventField] {
        [
            ContextEventField(label: "Sequence", value: "\(sequence)"),
            ContextEventField(label: "Event id", value: event.id.uuidString),
            ContextEventField(label: "Machine id", value: event.machineID.uuidString),
            ContextEventField(label: "Occurred", value: ISO8601Timestamp.string(from: event.occurredAt)),
            ContextEventField(label: "Kind", value: event.kind.displayName)
        ] + event.detail.fields
    }
}
