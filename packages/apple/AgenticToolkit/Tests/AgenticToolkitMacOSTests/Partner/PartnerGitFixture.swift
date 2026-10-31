import Foundation
@testable import AgenticToolkitMacOS

/// A temp git repo for the review git tests; commits carry explicit dates so ordering is deterministic.
final class PartnerGitFixture {
    let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerGitFixture-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try git("init", "-b", "main")
        try git("config", "user.name", "Ann")
        try git("config", "user.email", "ann@example.com")
    }

    deinit { try? FileManager.default.removeItem(at: directory) }

    @discardableResult
    func git(_ arguments: String...) throws -> String {
        try ReviewGit().run(arguments, in: directory)
    }

    /// Writes `file`, commits it dated `day` of January 2026, and returns the sha.
    @discardableResult
    func commit(file: String, day: Int, message: String, content: String? = nil) throws -> String {
        try (content ?? "\(message)\n")
            .write(to: directory.appendingPathComponent(file), atomically: true, encoding: .utf8)
        try git("add", file)
        try dated(["commit", "-m", message], day: day)
        return try git("rev-parse", "HEAD").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func merge(branch: String, day: Int) throws {
        try dated(["merge", "--no-ff", "-m", "merge \(branch)", branch], day: day)
    }

    private func dated(_ arguments: [String], day: Int) throws {
        let date = String(format: "2026-01-%02dT12:00:00Z", day)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = ProcessInfo.processInfo.environment
            .merging(["GIT_COMMITTER_DATE": date, "GIT_AUTHOR_DATE": date]) { $1 }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw GitError(status: process.terminationStatus, stderr: "git \(arguments.joined(separator: " ")) failed")
        }
    }
}
