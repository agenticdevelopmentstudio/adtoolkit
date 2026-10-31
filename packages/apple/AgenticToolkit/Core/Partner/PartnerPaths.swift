import Foundation

/// Where the partner keeps its files, derived from the app's storage token.
public struct PartnerPaths: Sendable, Equatable {
    public let home: URL
    public let token: String

    public init(home: URL, token: String) {
        self.home = home
        self.token = token
    }

    public var directory: URL { home.appendingPathComponent(".\(token)").appendingPathComponent("partner") }
    public var mcpConfig: URL { directory.appendingPathComponent("mcp.json") }
    public var systemPrompt: URL { directory.appendingPathComponent("system-prompt.md") }
    public var jobsDirectory: URL { directory.appendingPathComponent("jobs") }
    public var reviewsDirectory: URL { directory.appendingPathComponent("reviews") }
    public var skillsDirectory: URL { home.appendingPathComponent(".claude").appendingPathComponent("skills") }

    public func skillFile(jobID: String) -> URL {
        skillsDirectory.appendingPathComponent("adkitchen-partner-\(jobID)").appendingPathComponent("SKILL.md")
    }
}
