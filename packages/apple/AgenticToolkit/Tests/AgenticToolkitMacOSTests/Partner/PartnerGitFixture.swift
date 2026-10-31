import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// A temp git repo for the review git tests; commits carry explicit dates so ordering is deterministic.
///
/// The fixture builds its repo with the system git directly, so it never depends on the code under test;
/// `review` is the facade under test, over a `GitClient` with an explicit `/usr/bin/git` configuration.
final class PartnerGitFixture {
    let directory: URL
    let review = ReviewGit(client: GitClient(configuration: GitClientConfiguration(
        executableURL: URL(fileURLWithPath: "/usr/bin/git"), timeout: 30, submoduleHandling: .include)))

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerGitFixture-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try git("init", "-b", "main")
        try git("config", "user.name", "Ann")
        try git("config", "user.email", "ann@example.com")
        try git("config", "commit.gpgsign", "false")
    }

    deinit { try? FileManager.default.removeItem(at: directory) }

    @discardableResult
    func git(_ arguments: String...) throws -> String {
        try exec(arguments, day: nil, in: directory)
    }

    /// Runs git inside `subdirectory` of the repo (a submodule's working tree, say).
    @discardableResult
    func git(in subdirectory: String, _ arguments: String...) throws -> String {
        try exec(arguments, day: nil, in: directory.appendingPathComponent(subdirectory))
    }

    /// Writes `file`, commits it dated `day` of January 2026, and returns the sha.
    @discardableResult
    func commit(file: String, day: Int, message: String, content: String? = nil) throws -> String {
        try (content ?? "\(message)\n")
            .write(to: directory.appendingPathComponent(file), atomically: true, encoding: .utf8)
        try git("add", file)
        try exec(["commit", "-m", message], day: day, in: directory)
        return try git("rev-parse", "HEAD").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func merge(branch: String, day: Int) throws {
        try exec(["merge", "--no-ff", "-m", "merge \(branch)", branch], day: day, in: directory)
    }

    @discardableResult
    private func exec(_ arguments: [String], day: Int?, in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        var environment = ProcessInfo.processInfo.environment
        if let day {
            let date = String(format: "2026-01-%02dT12:00:00Z", day)
            environment["GIT_COMMITTER_DATE"] = date
            environment["GIT_AUTHOR_DATE"] = date
        }
        process.environment = environment
        let out = Pipe()
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw GitClientError.commandFailed(verb: arguments.first ?? "", exitStatus: process.terminationStatus,
                                               standardError: "")
        }
        return String(bytes: data, encoding: .utf8) ?? ""
    }
}
