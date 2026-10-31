import Foundation

/// A git command that exited non-zero.
public struct GitError: Error, Equatable, Sendable {
    public var status: Int32
    public var stderr: String

    public init(status: Int32, stderr: String) {
        self.status = status
        self.stderr = stderr
    }
}

/// A small git wrapper over Foundation `Process`; every call runs in a directory and returns stdout.
public struct ReviewGit: Sendable {

    /// The hash of git's empty tree: the "parent" of a root commit, so a diff against it still works.
    public static let emptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

    private let executable: String

    public init(executable: String = "/usr/bin/git") {
        self.executable = executable
    }

    public func run(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["LC_ALL"] = "C"
        process.environment = environment
        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err
        process.standardInput = FileHandle.nullDevice
        try process.run()
        // Drain stderr on another thread while this one drains stdout, so neither pipe can fill and block git.
        let errBox = DataBox()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            errBox.data = err.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        group.wait()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(bytes: errBox.data, encoding: .utf8) ?? ""
            throw GitError(status: process.terminationStatus,
                           stderr: message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return String(bytes: outData, encoding: .utf8) ?? ""
    }

    /// The target of `origin/HEAD`, else `main`, else `master`, else the current branch.
    public func defaultBranch(in repo: URL) throws -> String {
        if let origin = try? run(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines), origin.hasPrefix("origin/") {
            return String(origin.dropFirst("origin/".count))
        }
        let branches = try localBranches(in: repo)
        for candidate in ["main", "master"] where branches.contains(candidate) { return candidate }
        return try run(["rev-parse", "--abbrev-ref", "HEAD"], in: repo).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func localBranches(in repo: URL) throws -> [String] {
        lines(try run(["for-each-ref", "--format=%(refname:short)", "refs/heads"], in: repo))
    }

    public func isAncestor(_ sha: String, of branch: String, in repo: URL) throws -> Bool {
        do {
            _ = try run(["merge-base", "--is-ancestor", sha, branch], in: repo)
            return true
        } catch let error as GitError where error.status == 1 {
            return false
        }
    }

    /// The first parent of `sha`; the empty tree for a root commit.
    public func parent(of sha: String, in repo: URL) throws -> String {
        let parents = try run(["rev-list", "--parents", "-n", "1", sha], in: repo)
            .split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        return parents.count > 1 ? parents[1] : Self.emptyTree
    }

    public func changedFiles(parent: String, sha: String, in repo: URL) throws -> [String] {
        lines(try run(["diff", "--name-only", parent, sha], in: repo))
    }

    /// Commits after `sha` on `branch` that touch any of `files`, newest first.
    public func supersedingCommits(after sha: String, on branch: String, files: [String],
                                   in repo: URL) throws -> [String] {
        guard !files.isEmpty else { return [] }
        return lines(try run(["log", "--format=%H", "\(sha)..\(branch)", "--"] + files, in: repo))
    }

    /// The diff of `files` from `sha` to the tip of `branch`, cut at `maxBytes`.
    public func tipDiff(from sha: String, to branch: String, files: [String], in repo: URL,
                        maxBytes: Int = 200_000) throws -> String {
        let diff = try run(["diff", sha, branch, "--"] + files, in: repo)
        guard diff.utf8.count > maxBytes else { return diff }
        // Back off at most three bytes so the cut never lands inside a multi-byte character.
        for cut in stride(from: maxBytes, through: max(0, maxBytes - 3), by: -1) {
            if let text = String(diff.utf8.prefix(cut)) { return text }
        }
        return ""
    }

    public func isClean(worktree: URL) throws -> Bool {
        try run(["status", "--porcelain"], in: worktree).isEmpty
    }

    private func lines(_ output: String) -> [String] {
        output.split(separator: "\n").map(String.init)
    }
}

private final class DataBox: @unchecked Sendable { var data = Data() }
