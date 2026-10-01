import Foundation

/// One thing Universal Control wrote to the unified log about its session.
/// Macs are named by their IDS ids ("8A330823"), the only name the log gives.
///
/// Not the screen arrangement — that is `UniversalControlLog` in
/// AgenticToolkitDisplays, read from UC's ByHost preferences.
public enum UniversalControlSessionEvent: Sendable, Equatable {
    /// "no virtual service; dropping events": input arrived from the source
    /// Mac after this Mac tore its side of the session down, and was thrown
    /// away. The source does not notice, so while it keeps sending, neither
    /// Mac takes input.
    case droppedInput
    /// "Current Source Device: A -> B": which Mac's keyboard and mouse drive
    /// this one. `nil` is none.
    case sourceChanged(previous: String?, current: String?)
    /// "Connected Devices IDS: [A,B]": the Macs this one has a session with.
    case connectedDevices([String])
    /// "Local: A, Source: …": this Mac's own id.
    case localDevice(String)
}

/// A `UniversalControlSessionEvent` and when it was logged.
public struct UniversalControlSessionEntry: Sendable, Equatable {
    public let date: Date
    public let event: UniversalControlSessionEvent

    public init(date: Date, event: UniversalControlSessionEvent) {
        self.date = date
        self.event = event
    }
}

/// Reading Universal Control's session messages: the `log` commands that
/// select them, and the parse of what those commands print.
public enum UniversalControlSessionLog {

    /// Only the messages `UniversalControlSessionEvent` names, so a busy
    /// session streams a few lines a second rather than hundreds.
    public static let predicate = """
        subsystem == "com.apple.universalcontrol" AND \
        (composedMessage ENDSWITH "no virtual service; dropping events" \
        OR composedMessage BEGINSWITH "Current Source Device:" \
        OR composedMessage BEGINSWITH "Connected Devices IDS:" \
        OR composedMessage BEGINSWITH "Local: ")
        """

    public static let logTool = URL(fileURLWithPath: "/usr/bin/log")

    /// Follows the log as it is written. `--timeout` bounds a stream whose
    /// reader is gone: nothing else stops `log` if the app that started it
    /// dies without terminating it.
    public static func streamArguments(timeout: Duration = .seconds(600)) -> [String] {
        ["stream", "--style", "ndjson", "--timeout", "\(timeout.components.seconds)s", "--predicate", predicate]
    }

    /// What was logged in the last `lookback`, so a monitor started
    /// mid-session knows the session's state before the stream says anything.
    public static func historyArguments(lookback: Duration = .seconds(3600)) -> [String] {
        ["show", "--style", "ndjson", "--last", "\(lookback.components.seconds)s", "--predicate", predicate]
    }

    /// One `--style ndjson` line, or `nil` for anything else `log` prints —
    /// its "Filtering the log data…" banner, the closing count, a message
    /// this type does not name.
    public static func parse(line: Data) -> UniversalControlSessionEntry? {
        guard let record = try? JSONDecoder().decode(Record.self, from: line),
              let message = record.eventMessage,
              let stamp = record.timestamp,
              let date = try? timestampStyle.parse(stamp),
              let event = event(in: message) else {
            return nil
        }
        return UniversalControlSessionEntry(date: date, event: event)
    }

    /// The event a message records, or `nil` if it records none.
    public static func event(in message: String) -> UniversalControlSessionEvent? {
        if message.hasSuffix("no virtual service; dropping events") {
            return .droppedInput
        }
        if let rest = message.droppingPrefix("Current Source Device: ") {
            let sides = rest.components(separatedBy: " -> ")
            guard sides.count == 2 else { return nil }
            return .sourceChanged(previous: deviceID(sides[0]), current: deviceID(sides[1]))
        }
        if let rest = message.droppingPrefix("Connected Devices IDS: ") {
            let list = rest.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            return .connectedDevices(list.split(separator: ",").compactMap { deviceID(String($0)) })
        }
        if let rest = message.droppingPrefix("Local: "), let id = rest.split(separator: ",").first {
            return deviceID(String(id)).map(UniversalControlSessionEvent.localDevice)
        }
        return nil
    }

    private struct Record: Decodable {
        let timestamp: String?
        let eventMessage: String?
    }

    /// `log`'s "2026-10-01 08:23:57.722969-0700".
    private static let timestampStyle = Date.ISO8601FormatStyle(
        dateTimeSeparator: .space,
        timeZoneSeparator: .omitted,
        includingFractionalSeconds: true
    )

    /// An id, or `nil` for "nil", "<private>" and blanks.
    private static func deviceID(_ text: String) -> String? {
        let id = text.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, id != "nil", !id.hasPrefix("<") else { return nil }
        return id
    }
}

private extension String {
    func droppingPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
