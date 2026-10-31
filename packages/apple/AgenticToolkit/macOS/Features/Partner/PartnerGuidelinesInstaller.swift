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

    /// Seeds `jobs/<id>.md` for every job whose file does not exist yet. The file is where the owner's
    /// edited guidelines live, so an existing one is never overwritten.
    public func writeJobFiles(jobs: [PartnerJob]) throws {
        try fileManager.createDirectory(at: paths.jobsDirectory, withIntermediateDirectories: true)
        for job in jobs {
            let url = try jobFile(job.id)
            if !fileManager.fileExists(atPath: url.path) {
                try job.guidelines.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    /// Each job's guidelines replaced by its file's text when the file exists; otherwise the job is unchanged.
    public func loadGuidelines(jobs: [PartnerJob]) -> [PartnerJob] {
        jobs.map { job in
            guard let url = try? jobFile(job.id),
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return job }
            var loaded = job
            loaded.guidelines = text
            return loaded
        }
    }

    public func saveGuidelines(jobID: String, text: String) throws {
        let url = try jobFile(jobID)
        try fileManager.createDirectory(at: paths.jobsDirectory, withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Removes the edited file so the bundled default applies again; a missing file is not an error.
    public func resetGuidelines(jobID: String) throws {
        let url = try jobFile(jobID)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    /// Enabled jobs get a skill directory; disabled ones have theirs removed, and so does any
    /// `adkitchen-partner-` directory for a job no longer in the list.
    public func installSkills(jobs: [PartnerJob]) throws {
        for job in jobs { _ = try jobFile(job.id) }
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
        let keep = Set(jobs.map { "adkitchen-partner-\($0.id)" })
        let existing = (try? fileManager.contentsOfDirectory(atPath: paths.skillsDirectory.path)) ?? []
        for name in existing where name.hasPrefix("adkitchen-partner-") && !keep.contains(name) {
            try fileManager.removeItem(at: paths.skillsDirectory.appendingPathComponent(name))
        }
    }

    public enum InstallError: Error, Equatable {
        case invalidJobID(String)
    }

    /// `jobs/<id>.md`, after checking the id is safe to put in a path.
    private func jobFile(_ id: String) throws -> URL {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        guard !id.isEmpty, id.unicodeScalars.allSatisfy(allowed.contains) else {
            throw InstallError.invalidJobID(id)
        }
        return paths.jobsDirectory.appendingPathComponent("\(id).md")
    }
}
