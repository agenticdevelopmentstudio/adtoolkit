import Foundation

/// What a focus reading says about the work being done: the app, its window,
/// and (when resolvable) the path, repo root and branch it belongs to.
public struct SpanAttribution: Sendable, Equatable {
    public let bundleId: String
    public let appName: String
    public let windowTitle: String
    public let workingPath: String
    public let repoRoot: String
    public let branch: String
    /// The process the reading came from. Not part of ``key``: it only says
    /// *which* copy of an app a quit belongs to, because two copies can share
    /// a bundle id (Xcode and Xcode-beta are both `com.apple.dt.Xcode`).
    public let pid: Int32?

    public init(bundleId: String, appName: String, windowTitle: String = "", workingPath: String = "",
                repoRoot: String = "", branch: String = "", pid: Int32? = nil) {
        self.pid = pid
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
        self.workingPath = workingPath
        self.repoRoot = repoRoot
        self.branch = branch
    }

    /// What makes two focus readings the same span: same app and same repo +
    /// branch, or — with no repo — the same path.
    public var key: String {
        repoRoot.isEmpty
            ? "\(bundleId)\u{1F}path\u{1F}\(workingPath)"
            : "\(bundleId)\u{1F}repo\u{1F}\(repoRoot)\u{1F}\(branch)"
    }
}

/// Why time stops accruing regardless of focus.
public enum SpanSuspension: Sendable, Hashable { case locked, asleep }

/// What the caller must do to its stored spans.
public enum SpanCommand: Sendable, Equatable {
    case open(SpanAttribution, at: Date)
    case close(at: Date)
    case retitle(String)
}

/// Pure state machine: focus readings in, span open/close/retitle commands out.
public struct ActivitySpanBuilder: Sendable {
    public private(set) var open: SpanAttribution?
    private var lastFocus: SpanAttribution?
    private var suspensions: Set<SpanSuspension> = []

    public init() {}

    /// `nil` = a non-allowed app is frontmost.
    public mutating func focus(_ attribution: SpanAttribution?, at date: Date) -> [SpanCommand] {
        lastFocus = attribution
        guard suspensions.isEmpty else { return [] }
        guard let attribution else { return closeOpen(at: date) }
        if let current = open, current.key == attribution.key {
            open = attribution
            return current.windowTitle == attribution.windowTitle ? [] : [.retitle(attribution.windowTitle)]
        }
        let closed = closeOpen(at: date)
        open = attribution
        return closed + [.open(attribution, at: date)]
    }

    /// An app quit. Matched on the process when both sides know it, so quitting
    /// one copy of an app does not close the span of another copy that shares
    /// its bundle id; on the bundle id alone when either side does not.
    public mutating func appTerminated(bundleId: String, pid: Int32? = nil, at date: Date) -> [SpanCommand] {
        var commands: [SpanCommand] = []
        if let open, Self.matches(open, bundleId: bundleId, pid: pid) { commands = closeOpen(at: date) }
        if let lastFocus, Self.matches(lastFocus, bundleId: bundleId, pid: pid) { self.lastFocus = nil }
        return commands
    }

    private static func matches(_ attribution: SpanAttribution, bundleId: String, pid: Int32?) -> Bool {
        guard attribution.bundleId == bundleId else { return false }
        guard let pid, let own = attribution.pid else { return true }
        return pid == own
    }

    public mutating func suspend(_ reason: SpanSuspension, at date: Date) -> [SpanCommand] {
        let wasEmpty = suspensions.isEmpty
        suspensions.insert(reason)
        return wasEmpty ? closeOpen(at: date) : []
    }

    public mutating func resume(_ reason: SpanSuspension, at date: Date) -> [SpanCommand] {
        guard suspensions.remove(reason) != nil, suspensions.isEmpty, open == nil, let lastFocus else { return [] }
        open = lastFocus
        return [.open(lastFocus, at: date)]
    }

    private mutating func closeOpen(at date: Date) -> [SpanCommand] {
        guard open != nil else { return [] }
        open = nil
        return [.close(at: date)]
    }
}
