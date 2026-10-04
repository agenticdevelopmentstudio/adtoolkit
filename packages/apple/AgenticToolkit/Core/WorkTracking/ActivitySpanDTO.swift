import Foundation

/// One contiguous stretch of focus on an allowlisted development app.
public struct ActivitySpanDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let bundleId: String
    public let appName: String
    public var windowTitle: String
    public let workingPath: String     // "" = unresolved
    public let repoRoot: String        // "" = no repo
    public let branch: String
    public let startedAt: String       // ISO-8601 UTC
    public var endedAt: String         // "" = open
    public let tz: String // swiftlint:disable:this identifier_name
    public var lastSeenAt: String      // "" = no heartbeat yet

    // swiftlint:disable identifier_name
    public init(id: String = UUID().uuidString, bundleId: String, appName: String, windowTitle: String = "",
                workingPath: String = "", repoRoot: String = "", branch: String = "",
                startedAt: String, endedAt: String = "", tz: String, lastSeenAt: String = "") {
        self.id = id
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
        self.workingPath = workingPath
        self.repoRoot = repoRoot
        self.branch = branch
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.tz = tz
        self.lastSeenAt = lastSeenAt
    }
    // swiftlint:enable identifier_name

    public var isOpen: Bool { endedAt.isEmpty }
}
