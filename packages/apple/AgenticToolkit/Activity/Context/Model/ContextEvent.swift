import Foundation

// MARK: - Supporting enums (raw values are schema contract)

public enum WindowChange: String, Sendable, CaseIterable, Codable {
    case created, destroyed
    case titleChanged = "title_changed"
}

public enum NetworkInterfaceType: String, Sendable, CaseIterable, Codable {
    case wifi, ethernet, cellular, other, none
}

public enum SessionChange: String, Sendable, CaseIterable, Codable {
    case idle, active, lock, unlock, sleep, wake
}

/// What an `input` event says happened to the user's presence at the keyboard.
///
/// The trigger reports *transitions*, not readings: `inactive` marks the
/// moment input stopped, `active` the moment it resumed. Between the two there
/// is nothing to record, which is the whole point — a poll that emitted every
/// half-minute wrote 11,731 rows in four days to say "nothing changed".
///
/// `sample` is that former behaviour and is **never emitted**. It exists so
/// the rows already in the database stay readable and keep meaning what they
/// meant: one periodic reading of the input statistics, taken whether or not
/// anything had happened. Rows written before the `change` column existed
/// migrate to it (see ``OlyloSchema``), so a legacy row is not silently
/// reinterpreted as a transition it never witnessed.
public enum InputChange: String, Sendable, CaseIterable, Codable {
    case active, inactive, sample
}

/// Named `PowerSourceKind`, not `PowerSource`: `AgenticToolkitActivity` already has a
/// `public protocol PowerSource` (the lock/sleep observation seam in
/// `Capture/ObservationSources.swift`), and the two would collide in this module.
public enum PowerSourceKind: String, Sendable, CaseIterable, Codable {
    case ac, battery
}

/// Whether an application started or ended. Distinct from `window` (a window
/// opening is not the app starting) and from `app_focus` (an app can run for
/// hours without ever being frontmost).
public enum AppLifecycleChange: String, Sendable, CaseIterable, Codable {
    case launched, terminated
}

// MARK: - Detail payloads

/// Which app/window/document the user is looking at. Every field beyond the
/// app identity is optional because the Accessibility API returns nothing for
/// apps that expose no focused window and no document.
public struct AppFocusDetail: Sendable, Equatable, Codable {
    public let bundleID: String
    public let appName: String
    public let pid: Int32
    public let executablePath: String?
    public let windowID: UInt32?
    public let windowTitle: String?
    public let documentPath: String?
    public let documentSize: Int64?
    public let documentModifiedAt: Date?
    public let documentType: String?
    /// The page a browser window was showing. Held apart from
    /// `documentPath` so that asking what files were open does not answer
    /// with web pages — see ``WindowAddress``. Defaulted because every
    /// non-browser row leaves it empty.
    public let url: String?

    public init(bundleID: String, appName: String, pid: Int32, executablePath: String?,
                windowID: UInt32?, windowTitle: String?, documentPath: String?,
                documentSize: Int64?, documentModifiedAt: Date?, documentType: String?,
                url: String? = nil) {
        self.bundleID = bundleID; self.appName = appName; self.pid = pid
        self.executablePath = executablePath; self.windowID = windowID
        self.windowTitle = windowTitle; self.documentPath = documentPath
        self.documentSize = documentSize; self.documentModifiedAt = documentModifiedAt
        self.documentType = documentType; self.url = url
    }
}

public struct WindowDetail: Sendable, Equatable, Codable {
    public let change: WindowChange
    public let bundleID: String
    public let appName: String
    public let pid: Int32
    public let windowID: UInt32
    public let windowTitle: String?

    public init(change: WindowChange, bundleID: String, appName: String, pid: Int32,
                windowID: UInt32, windowTitle: String?) {
        self.change = change; self.bundleID = bundleID; self.appName = appName
        self.pid = pid; self.windowID = windowID; self.windowTitle = windowTitle
    }
}

public struct NetworkDetail: Sendable, Equatable, Codable {
    public let interfaceType: NetworkInterfaceType
    public let isSatisfied: Bool
    public let ssid: String?
    public let bssid: String?
    public let isExpensive: Bool?
    public let isConstrained: Bool?

    public init(interfaceType: NetworkInterfaceType, isSatisfied: Bool, ssid: String?,
                bssid: String?, isExpensive: Bool?, isConstrained: Bool?) {
        self.interfaceType = interfaceType; self.isSatisfied = isSatisfied
        self.ssid = ssid; self.bssid = bssid
        self.isExpensive = isExpensive; self.isConstrained = isConstrained
    }
}

public struct LocationDetail: Sendable, Equatable, Codable {
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracy: Double?
    public let altitude: Double?
    public let verticalAccuracy: Double?
    public let speed: Double?
    public let course: Double?

    public init(latitude: Double, longitude: Double, horizontalAccuracy: Double?,
                altitude: Double?, verticalAccuracy: Double?, speed: Double?, course: Double?) {
        self.latitude = latitude; self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy; self.altitude = altitude
        self.verticalAccuracy = verticalAccuracy; self.speed = speed; self.course = course
    }
}

/// Whether the user is physically present, derived from CGEventSource
/// statistics only — no key codes, no content, no event tap.
/// A change in whether anybody is at the keyboard, plus the statistics that
/// were true when it was noticed.
///
/// The statistics are kept even though the event is now a transition: measured
/// between one emission and the next, `keyCountDelta` and `mouseCountDelta` on
/// an `inactive` event say how much happened during the active stretch that
/// just ended, and `intervalMs` says how long that stretch was. At two rows
/// per idle period they cost nothing, and they are the only evidence of *how
/// busy* a block of work was.
public struct InputDetail: Sendable, Equatable, Codable {
    /// Which transition this row records. See ``InputChange``.
    public let change: InputChange

    /// How long the user had been away, in seconds.
    ///
    /// Set on `active` — the length of the absence that just ended, measured
    /// from the last real input to the first new one, so it is the number the
    /// timeline uses to decide whether a new block of work started.
    ///
    /// Also set on an `inactive` event that the trigger emitted as its *first*
    /// reading, where it means "already idle this long when we started
    /// watching". A normal `inactive` event is timestamped at the moment input
    /// stopped and so carries no interval of its own: `nil`.
    public let idleSeconds: Double?

    public let secondsSinceKey: Double?
    public let secondsSinceMouseMove: Double?
    public let secondsSinceClick: Double?
    public let secondsSinceScroll: Double?
    public let keyCountDelta: Int64?
    public let mouseCountDelta: Int64?
    public let intervalMs: Int64?

    public init(change: InputChange, idleSeconds: Double? = nil,
                secondsSinceKey: Double?, secondsSinceMouseMove: Double?,
                secondsSinceClick: Double?, secondsSinceScroll: Double?,
                keyCountDelta: Int64?, mouseCountDelta: Int64?, intervalMs: Int64?) {
        self.change = change; self.idleSeconds = idleSeconds
        self.secondsSinceKey = secondsSinceKey; self.secondsSinceMouseMove = secondsSinceMouseMove
        self.secondsSinceClick = secondsSinceClick; self.secondsSinceScroll = secondsSinceScroll
        self.keyCountDelta = keyCountDelta; self.mouseCountDelta = mouseCountDelta
        self.intervalMs = intervalMs
    }
}

public struct SessionDetail: Sendable, Equatable, Codable {
    public let change: SessionChange
    public init(change: SessionChange) { self.change = change }
}

public struct PowerDetail: Sendable, Equatable, Codable {
    public let source: PowerSourceKind
    public let percent: Int?
    public let isCharging: Bool?
    public init(source: PowerSourceKind, percent: Int?, isCharging: Bool?) {
        self.source = source; self.percent = percent; self.isCharging = isCharging
    }
}

/// An application starting or ending. The same identity fields as
/// ``WindowDetail`` minus the window, because that is exactly the identity
/// `NSWorkspace` hands over with these notifications.
public struct AppLifecycleDetail: Sendable, Equatable, Codable {
    public let change: AppLifecycleChange
    public let bundleID: String
    public let appName: String
    public let pid: Int32

    public init(change: AppLifecycleChange, bundleID: String, appName: String, pid: Int32) {
        self.change = change; self.bundleID = bundleID
        self.appName = appName; self.pid = pid
    }
}

// MARK: - Event

/// Exactly one detail per event, and the detail decides the kind — an enum
/// rather than a bag of optionals, so "kind and payload disagree" is not a
/// representable state.
public enum ContextEventDetail: Sendable, Equatable {
    case appFocus(AppFocusDetail)
    case window(WindowDetail)
    case network(NetworkDetail)
    case location(LocationDetail)
    case input(InputDetail)
    case session(SessionDetail)
    case power(PowerDetail)
    case appLifecycle(AppLifecycleDetail)

    public var kind: ContextEventKind {
        switch self {
        case .appFocus:      return .appFocus
        case .window:        return .window
        case .network:       return .network
        case .location:      return .location
        case .input:         return .input
        case .session:       return .session
        case .power:         return .power
        case .appLifecycle:  return .appLifecycle
        }
    }
}

/// One row of `context_event` plus its detail row. `machineID` is mandatory —
/// this data syncs across a fleet of devices, so an event with no device is
/// unattributable and therefore not representable.
public struct ContextEvent: Sendable, Equatable, Codable {
    public let id: UUID
    public let machineID: UUID
    public let occurredAt: Date
    public let detail: ContextEventDetail

    public var kind: ContextEventKind { detail.kind }

    public init(id: UUID = UUID(), machineID: UUID, occurredAt: Date, detail: ContextEventDetail) {
        self.id = id; self.machineID = machineID
        self.occurredAt = occurredAt; self.detail = detail
    }
}
