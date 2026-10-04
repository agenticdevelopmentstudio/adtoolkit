import Foundation

// `AppInfo`, `WindowFocus`, and `WindowLifecycleKind` are `public`: they
// appear in the observation-source protocols' public callback signatures
// (`ObservationSources.swift`), which both the real macOS adapters and the
// iOS no-op adapters conform to across the `AgenticToolkitActivity` module boundary.
// The other domain types below (`EndReason`, `FocusSegment`, `FocusEvent`)
// are used only inside `AgenticToolkitActivity` (by
// `UsageStore`/`UsageCollector`/`FocusTracker`) and stay internal —
// `olylod` never names them directly.
//
// `WindowLifecycleKind` outlives the retired `usage_window_events` table
// because it still names the shape of a window change; the row struct that
// went with that table does not.
public struct AppInfo: Equatable, Sendable {
    let bundleID: String
    let name: String
    let pid: Int32
}

public struct WindowFocus: Equatable, Sendable {
    let app: AppInfo
    let windowID: UInt32
    let title: String
    /// A document on disk, never a web address — see ``WindowAddress``.
    let documentPath: String?
    /// The page a browser window is showing. Separate from `documentPath`
    /// because they answer different questions, and because only one of them
    /// has a size and an mtime worth reading.
    let url: String?

    /// Defaults `url` so the usage pipeline — which stores focus segments
    /// without one, and reads them back the same way — is unaffected by a
    /// field only the context triggers record.
    init(app: AppInfo, windowID: UInt32, title: String,
         documentPath: String?, url: String? = nil) {
        self.app = app
        self.windowID = windowID
        self.title = title
        self.documentPath = documentPath
        self.url = url
    }
}

enum EndReason: String, Sendable {
    case focusChange = "focus_change"
    case titleChange = "title_change"
    case idle, lock, sleep
    case appQuit = "app_quit"
    case collectorStop = "collector_stop"
}

struct FocusSegment: Equatable, Sendable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    let focus: WindowFocus
    var endReason: EndReason?
    // `max(0, …)`: a backward wall-clock step (NTP correction / manual set)
    // between a segment opening and closing would otherwise yield a negative
    // duration and corrupt any later aggregate — a segment can't be negative-length.
    var durationMs: Int? { endedAt.map { max(0, Int($0.timeIntervalSince(startedAt) * 1000)) } }
}

public enum WindowLifecycleKind: String, Sendable {
    case created, destroyed
    case titleChanged = "title_changed"
}

enum FocusEvent: Equatable, Sendable {
    case focus(WindowFocus)
    case idle, lock, sleep
    case appQuit(pid: Int32)
}
