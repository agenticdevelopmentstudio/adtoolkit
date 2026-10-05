import Foundation

public struct RepoLocation: Sendable, Equatable {
    public let root: String
    public let branch: String

    public init(root: String, branch: String) {
        self.root = root
        self.branch = branch
    }
}

/// Finds the innermost git repo at or above a path, and its branch, by reading
/// `.git` directly. Deliberately spawns no `git` process: it runs on every
/// focus change. It answers what `GitProjectRoot` in Core answers by shelling
/// out: a linked worktree resolves to its main repo, a submodule to its
/// superproject — with the branch of the checkout the window is in.
public struct RepoLocator: Sendable {
    public struct FileSystem: Sendable {
        public enum Kind: Sendable { case directory, file, missing }

        public var kind: @Sendable (String) -> Kind
        public var read: @Sendable (String) -> String?

        public init(kind: @escaping @Sendable (String) -> Kind, read: @escaping @Sendable (String) -> String?) {
            self.kind = kind
            self.read = read
        }

        public static let live = FileSystem(
            kind: { path in
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return .missing }
                return isDirectory.boolValue ? .directory : .file
            },
            read: { path in
                // `.git`, `HEAD` and `commondir` are tiny; never slurp a hostile big file.
                guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
                defer { try? handle.close() }
                // `read(upToCount:)` yields nil at EOF, which for an empty file is a successful empty read.
                do {
                    let data = try handle.read(upToCount: readLimit)
                    return String(decoding: data ?? Data(), as: UTF8.self)
                } catch {
                    return nil
                }
            })

        /// The most any one git metadata file is read.
        public static let readLimit = 4096
    }

    private let fileSystem: FileSystem

    public init(fileSystem: FileSystem = .live) {
        self.fileSystem = fileSystem
    }

    /// Innermost `.git` (dir or file) at or above `path`; branch from HEAD.
    public func locate(_ path: String) -> RepoLocation? {
        guard !path.isEmpty else { return nil }
        var current = (path as NSString).standardizingPath
        while true {
            let gitPath = (current == "/" ? "" : current) + "/.git"
            switch fileSystem.kind(gitPath) {
            case .directory:
                return location(gitDir: gitPath, fallbackRoot: current)
            case .file:
                guard let gitDir = gitDir(fromFile: gitPath, workTree: current) else {
                    return RepoLocation(root: current, branch: "")
                }
                if isSubmodule(gitDir: gitDir), let enclosing = superproject(of: current) {
                    return enclosing
                }
                return location(gitDir: gitDir, fallbackRoot: current)
            case .missing:
                break
            }
            if current == "/" || current.isEmpty { return nil }
            let parent = (current as NSString).deletingLastPathComponent
            if parent == current { return nil }
            current = parent.isEmpty ? "/" : parent
        }
    }

    /// `root` is the parent of the git COMMON dir, exactly what the daemon's
    /// `resolveRepoRoot` (`git rev-parse --git-common-dir`) yields, so a linked
    /// worktree bills to its main repo. A submodule never reaches here — see
    /// ``superproject(of:)``. `branch` comes from the worktree's own HEAD
    /// (`gitDir/HEAD`).
    private func location(gitDir: String, fallbackRoot: String) -> RepoLocation {
        // A gitdir with no readable HEAD (a dangling worktree) is not a git dir:
        // its parent would be bogus, so attribute to the directory holding `.git`.
        guard fileSystem.read(gitDir + "/HEAD") != nil else {
            return RepoLocation(root: fallbackRoot, branch: "")
        }
        var commonDir = gitDir
        if let text = fileSystem.read(gitDir + "/commondir")?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            commonDir = Self.resolve(text, relativeTo: gitDir)
        }
        var root = (commonDir as NSString).deletingLastPathComponent
        if root.isEmpty { root = fallbackRoot }
        return RepoLocation(root: (root as NSString).standardizingPath, branch: branch(headPath: gitDir + "/HEAD"))
    }

    /// A submodule's gitdir lives in its superproject's git dir, under
    /// `modules/` (`<super>/.git/modules/<name>`, or
    /// `<super>/.git/worktrees/<wt>/modules/<name>` for a linked worktree's),
    /// and — unlike a linked worktree's — has no `commondir`.
    private func isSubmodule(gitDir: String) -> Bool {
        gitDir.contains("/modules/") && fileSystem.read(gitDir + "/commondir") == nil
            && fileSystem.read(gitDir + "/HEAD") != nil
    }

    /// The repo enclosing a submodule's work tree, located the same way, so a
    /// submodule bills where `GitProjectRoot` (and so billing repos and the
    /// session `project_root`) put it: the topmost superproject's main work
    /// tree. A submodule's own gitdir has no `commondir`, so taking its parent
    /// as the root named a directory inside the superproject's `.git`, which
    /// no billing repo can ever equal. Nested submodules climb one level per
    /// call until a repo that is not one answers.
    private func superproject(of workTree: String) -> RepoLocation? {
        let parent = (workTree as NSString).deletingLastPathComponent
        guard !parent.isEmpty, parent != workTree else { return nil }
        return locate(parent)
    }

    private func gitDir(fromFile gitFile: String, workTree: String) -> String? {
        guard let text = fileSystem.read(gitFile) else { return nil }
        let prefix = "gitdir:"
        guard let line = text.split(whereSeparator: \.isNewline).first(where: { $0.hasPrefix(prefix) }) else { return nil }
        let dir = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
        guard !dir.isEmpty else { return nil }
        return Self.resolve(dir, relativeTo: workTree)
    }

    private static func resolve(_ path: String, relativeTo base: String) -> String {
        ((path.hasPrefix("/") ? path : base + "/" + path) as NSString).standardizingPath
    }

    private func branch(headPath: String) -> String {
        guard let head = fileSystem.read(headPath)?.trimmingCharacters(in: .whitespacesAndNewlines) else { return "" }
        let prefix = "ref: refs/heads/"
        return head.hasPrefix(prefix) ? String(head.dropFirst(prefix.count)) : ""
    }
}
