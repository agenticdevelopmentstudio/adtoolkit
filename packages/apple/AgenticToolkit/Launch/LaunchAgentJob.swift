import Foundation
import AgenticToolkitCore

/// A launch job whose command failed; carries what ran, its exit status and
/// what it printed.
public enum LaunchJobError: Error, LocalizedError {
    case command(String, Int32, String)

    public var errorDescription: String? {
        switch self {
        case .command(let what, let status, let output): return "\(what) exited \(status): \(output)"
        }
    }
}

/// Queues ``LaunchAgentJob`` when the installed plist is missing or means
/// something other than ``LaunchAgentSpec``, or a superseded plist is still on disk.
public struct LaunchAgentAssessment: PreparationJob {
    public let spec: LaunchAgentSpec
    public let plistURL: URL
    public let directoriesToCreate: [URL]
    public let stopMarkerURL: URL
    public let supersededLabels: [String]
    public let supersededPlistURLs: [URL]
    public let title: String
    public let commands: any CommandRunning

    public init(spec: LaunchAgentSpec, plistURL: URL, directoriesToCreate: [URL], stopMarkerURL: URL,
                supersededLabels: [String] = [], supersededPlistURLs: [URL] = [],
                title: String = "Registering the daemon", commands: any CommandRunning) {
        self.spec = spec
        self.plistURL = plistURL
        self.directoriesToCreate = directoriesToCreate
        self.stopMarkerURL = stopMarkerURL
        self.supersededLabels = supersededLabels
        self.supersededPlistURLs = supersededPlistURLs
        self.title = title
        self.commands = commands
    }

    public func assess() async -> [any StartupJob] {
        let superseded = supersededPlistURLs.contains { FileManager.default.fileExists(atPath: $0.path) }
        guard differsFromWanted() || superseded else { return [] }
        return [makeJob()]
    }

    func makeJob() -> LaunchAgentJob {
        LaunchAgentJob(spec: spec, plistURL: plistURL, directoriesToCreate: directoriesToCreate,
                       stopMarkerURL: stopMarkerURL, supersededLabels: supersededLabels,
                       supersededPlistURLs: supersededPlistURLs, title: title, commands: commands)
    }

    /// Compares parsed values, not bytes: a plist written by an earlier version
    /// may differ in layout or key order from `render` while meaning the same
    /// thing. An unreadable or unparsable file counts as differing.
    private func differsFromWanted() -> Bool {
        let wanted = try? PropertyListSerialization.propertyList(
            from: LaunchAgentPlist.render(spec), format: nil)
        guard let installed = NSDictionary(contentsOf: plistURL),
              let wantedDictionary = wanted as? NSDictionary else { return true }
        return !installed.isEqual(wantedDictionary)
    }
}

/// Writes the LaunchAgent plist and registers it with launchd, leaving the
/// daemon stopped when the user stopped it on purpose.
public struct LaunchAgentJob: StartupJob {
    public let id = "launch-agent"
    public let title: String
    public let spec: LaunchAgentSpec
    public let plistURL: URL
    /// Created before the plist is written: launchd refuses to spawn a job
    /// whose working directory is missing.
    public let directoriesToCreate: [URL]
    /// Present when the user stopped the daemon on purpose: the job still writes
    /// the plist but leaves the daemon stopped.
    public let stopMarkerURL: URL
    /// Earlier labels and plists this job replaces: each is booted out and its
    /// plist removed.
    public let supersededLabels: [String]
    public let supersededPlistURLs: [URL]
    public let commands: any CommandRunning

    public init(spec: LaunchAgentSpec, plistURL: URL, directoriesToCreate: [URL], stopMarkerURL: URL,
                supersededLabels: [String] = [], supersededPlistURLs: [URL] = [],
                title: String = "Registering the daemon", commands: any CommandRunning) {
        self.spec = spec
        self.plistURL = plistURL
        self.directoriesToCreate = directoriesToCreate
        self.stopMarkerURL = stopMarkerURL
        self.supersededLabels = supersededLabels
        self.supersededPlistURLs = supersededPlistURLs
        self.title = title
        self.commands = commands
    }

    @MainActor public func run(context: StartupJobContext) async throws {
        let files = FileManager.default
        for directory in directoriesToCreate {
            try files.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let domain = Launchctl.guiDomain()
        let label = spec.label

        // A loaded job means the stop marker is stale (login re-loads a daemon the
        // user once stopped). Read the marker before the probe, as ensureRunning does.
        let markerBeforeProbe = DaemonBootstrap.markerStamp(at: stopMarkerURL)
        let currentLoaded = await launchctl("print", "\(domain)/\(label)").status == 0
        var supersededLoaded = false
        for old in supersededLabels {
            if await launchctl("print", "\(domain)/\(old)").status == 0 { supersededLoaded = true }
        }

        let existingSuperseded = supersededPlistURLs.filter { files.fileExists(atPath: $0.path) }
        if supersededLoaded || !existingSuperseded.isEmpty {
            for old in supersededLabels {
                _ = await launchctl("bootout", "\(domain)/\(old)")
                try await waitToLeave(label: old, domain: domain)
            }
        }
        for url in existingSuperseded { try files.removeItem(at: url) }

        try files.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try LaunchAgentPlist.render(spec).write(to: plistURL, options: .atomic)
        // The plist changed, so a running daemon would keep the stale config.
        _ = await launchctl("bootout", "\(domain)/\(label)")
        try await waitToLeave(label: label, domain: domain)

        if currentLoaded || supersededLoaded, let markerBeforeProbe,
           DaemonBootstrap.markerStamp(at: stopMarkerURL) == markerBeforeProbe {
            DaemonBootstrap.clearDeliberateStop(at: stopMarkerURL)
        }
        guard !DaemonBootstrap.wasStoppedDeliberately(at: stopMarkerURL) else { return }

        var result = await launchctl("bootstrap", domain, plistURL.path)
        if result.status == 5 || result.status == 37 {
            // launchd may still be tearing the old job down: wait once more, retry once.
            try await waitToLeave(label: label, domain: domain)
            result = await launchctl("bootstrap", domain, plistURL.path)
        }
        guard result.status == 0 else {
            throw LaunchJobError.command("launchctl bootstrap", result.status, result.output)
        }
    }

    private func launchctl(_ arguments: String...) async -> (status: Int32, output: String) {
        await commands.run([Launchctl.path] + arguments)
    }

    /// Bounded wait (20 x 250 ms) for a job to leave launchd: a superseded
    /// daemon's lock can gate a data migration, and bootstrap right after
    /// bootout races launchd's teardown. Proceeds regardless once the bound is spent.
    private func waitToLeave(label: String, domain: String) async throws {
        for _ in 0..<20 {
            if await launchctl("print", "\(domain)/\(label)").status != 0 { return }
            try await Task.sleep(for: .milliseconds(250))
        }
    }
}
