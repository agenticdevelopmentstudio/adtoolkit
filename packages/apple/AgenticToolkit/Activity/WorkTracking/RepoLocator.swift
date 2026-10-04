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
/// focus change. (`GitProjectRoot` in Core shells out and resolves to the
/// *main* working tree; billing here wants the checkout the window is in.)
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
            read: { try? String(contentsOfFile: $0, encoding: .utf8) })
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
                return RepoLocation(root: current, branch: branch(headPath: gitPath + "/HEAD"))
            case .file:
                return RepoLocation(root: current, branch: branch(gitFile: gitPath, root: current))
            case .missing:
                break
            }
            if current == "/" || current.isEmpty { return nil }
            let parent = (current as NSString).deletingLastPathComponent
            if parent == current { return nil }
            current = parent.isEmpty ? "/" : parent
        }
    }

    private func branch(gitFile: String, root: String) -> String {
        guard let text = fileSystem.read(gitFile) else { return "" }
        let prefix = "gitdir:"
        guard let line = text.split(whereSeparator: \.isNewline).first(where: { $0.hasPrefix(prefix) }) else { return "" }
        let dir = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
        guard !dir.isEmpty else { return "" }
        let absolute = dir.hasPrefix("/") ? dir : root + "/" + dir
        return branch(headPath: (absolute as NSString).standardizingPath + "/HEAD")
    }

    private func branch(headPath: String) -> String {
        guard let head = fileSystem.read(headPath)?.trimmingCharacters(in: .whitespacesAndNewlines) else { return "" }
        let prefix = "ref: refs/heads/"
        return head.hasPrefix(prefix) ? String(head.dropFirst(prefix.count)) : ""
    }
}
