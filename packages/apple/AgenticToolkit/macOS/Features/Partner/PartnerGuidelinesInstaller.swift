import Foundation
import AgenticToolkitCore

/// Writes the files the partner reads: the system prompt, a file per job, and a Claude Code skill per
/// enabled job.
public struct PartnerGuidelinesInstaller {
    private let paths: PartnerPaths
    private let fileManager: FileManager

    public init(paths: PartnerPaths, fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    @discardableResult
    public func writeSystemPrompt(jobs: [PartnerJob]) throws -> URL {
        let url = paths.systemPrompt
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try PartnerBasePrompt.systemPrompt(jobs: jobs).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// `jobs/<id>.md` for every job, enabled or not.
    public func writeJobFiles(jobs: [PartnerJob]) throws {
        try fileManager.createDirectory(at: paths.jobsDirectory, withIntermediateDirectories: true)
        for job in jobs {
            let url = paths.jobsDirectory.appendingPathComponent("\(job.id).md")
            try job.guidelines.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// Enabled jobs get a skill directory; disabled ones have theirs removed.
    public func installSkills(jobs: [PartnerJob]) throws {
        for job in jobs {
            let file = paths.skillFile(jobID: job.id)
            let directory = file.deletingLastPathComponent()
            if job.isEnabled {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                try PartnerBasePrompt.skillMarkdown(for: job).write(to: file, atomically: true, encoding: .utf8)
            } else if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
        }
    }
}
