import Foundation

/// Walks the user's project directories looking for git working trees.
///
/// What it walks and what it leaves out is the user's, from the Projects
/// settings, injected here as plain values so the walk runs off the main actor
/// and is testable without a settings store (`dependency-injection`):
///
/// - **`roots`** are the directories the user named as holding projects. There
///   is no default: with none, nothing is scanned and nothing is listed.
/// - **`skippedDirectories`** are directories the walk never enters, wherever
///   in the tree they are. Matched by path, not by name.
/// - **`skipsHiddenDirectories`** keeps the walk out of every dot-directory —
///   `.venv`, `.build`, `.claude/worktrees` — that holds checkouts nobody means
///   by "my projects". `.git` itself is never walked either way.
/// - **`skipsSubmodules`** leaves out the submodules of the repositories found.
///   Off, each repository's `.gitmodules` is read and every submodule checked
///   out on disk is reported as a project of its own.
///
/// And always:
///
/// - **A directory holding a working `.git` directory is a repository, and is
///   not descended into.** "Working" is checked, not assumed: a `.git` holding
///   nothing but a `hooks/` folder is what a tool that installs hooks into a
///   plain folder leaves behind, and calling that a repository both invents a
///   project and hides the real repositories underneath it.
/// - **A directory whose `.git` is a *file* is skipped by the walk** — that is
///   a submodule or a linked worktree. A submodule is reported, when asked
///   for, through the repository that owns it; a linked worktree never.
///
/// Nothing here touches the main actor and nothing here is `git`: the remote is
/// read out of `.git/config` directly, because 200-odd `git config` subprocesses
/// cost more than the whole walk.
public struct GitRepoScanner: Sendable {

    /// Directories that never contain a project but often contain checkouts.
    /// Same set as `proj`'s, so the two agree about what a project is.
    public static let prunedDirectoryNames: Set<String> = [
        "node_modules", "venv", "__pycache__",
        "build", "dist", "target",
        "Pods", "Carthage"
    ]

    public let roots: [URL]
    public let skippedDirectories: [URL]
    public let skipsHiddenDirectories: Bool
    public let skipsSubmodules: Bool

    public init(
        roots: [URL],
        skippedDirectories: [URL] = [],
        skipsHiddenDirectories: Bool = true,
        skipsSubmodules: Bool = true
    ) {
        self.roots = roots.map(\.standardizedFileURL)
        self.skippedDirectories = skippedDirectories.map(\.standardizedFileURL)
        self.skipsHiddenDirectories = skipsHiddenDirectories
        self.skipsSubmodules = skipsSubmodules
    }

    /// Whether the walk would not report `path`: it lies outside every root,
    /// under a skipped directory, under a hidden or pruned directory, or is a
    /// submodule or linked worktree — each only as far as the settings ask.
    ///
    /// The question the project list asks of a row the registry already
    /// holds. A row the settings now leave out is kept by the reconciler — it
    /// is still a repository, and deleting it would take its layout with it —
    /// so the list has to be able to leave it out on the same rules the walk
    /// applies, rather than a second copy of them (`dry`).
    public func skips(path: String) -> Bool {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        let components = url.pathComponents
        guard let root = roots.first(where: { Self.components(components, areWithin: $0) }) else {
            return true
        }
        if skippedDirectories.contains(where: { Self.components(components, areWithin: $0) }) {
            return true
        }
        let below = components.dropFirst(root.pathComponents.count)
        if skipsHiddenDirectories, below.contains(where: { $0.hasPrefix(".") }) { return true }
        if below.dropLast().contains(where: { Self.prunedDirectoryNames.contains($0) }) { return true }
        // A `.git` file is a submodule or a linked worktree: the walk reports
        // a submodule only when asked to, and a linked worktree never.
        let dotGit = url.appendingPathComponent(".git")
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dotGit.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else { return false }
        return skipsSubmodules || !Self.isSubmoduleGitFile(dotGit)
    }

    /// Reported as the walk goes, so the progress window has something truthful
    /// to say. Called from whatever thread `scan` runs on.
    public struct Progress: Sendable {
        public let directoriesVisited: Int
        public let reposFound: Int
        public let currentPath: String
    }

    /// Walks every root and returns what it found, sorted by path so two scans
    /// of an unchanged tree produce identical output (`idempotency`).
    ///
    /// `isCancelled` is consulted per directory. The scan is not cancellable
    /// from the UI today; the hook exists because the alternative is a walk that
    /// keeps running after the app is told to quit.
    public func scan(
        isCancelled: @Sendable () -> Bool = { false },
        onProgress: (@Sendable (Progress) -> Void)? = nil
    ) -> [ScannedGitRepo] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .nameKey]

        var found: [ScannedGitRepo] = []
        var visited = 0

        for root in roots {
            var stack: [URL] = [root]

            while let directory = stack.popLast() {
                if isCancelled() { return Self.unique(found) }
                visited += 1
                onProgress?(Progress(
                    directoriesVisited: visited,
                    reposFound: found.count,
                    currentPath: directory.path
                ))

                let children: [URL]
                do {
                    children = try fileManager.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: keys,
                        options: []
                    )
                } catch {
                    // An unreadable directory is not a reason to abandon the
                    // walk — `~` has plenty of them.
                    continue
                }

                if let dotGit = children.first(where: { $0.lastPathComponent == ".git" }) {
                    if !isDirectory(dotGit) {
                        // A `.git` file is a submodule or a linked worktree.
                        continue
                    }
                    if Self.isGitDirectory(dotGit) {
                        found.append(ScannedGitRepo(
                            path: directory.path,
                            remote: Self.originRemote(inGitDirectory: dotGit)
                        ))
                        if !skipsSubmodules {
                            found.append(contentsOf: submodules(of: directory))
                        }
                        // A repository owns everything below it.
                        continue
                    }
                    // A `.git` that is not a repository says nothing about this
                    // directory, so the walk carries on into it — the real
                    // repositories are usually the folders directly underneath.
                }

                for child in children where shouldDescend(into: child) {
                    stack.append(child)
                }
            }
        }

        return Self.unique(found)
    }

    /// Sorted by path, each path once: two roots that overlap — `~/Development`
    /// and `~/Development/ios` — would otherwise report the inner one twice.
    private static func unique(_ found: [ScannedGitRepo]) -> [ScannedGitRepo] {
        var seen = Set<String>()
        return found.sorted { $0.path < $1.path }.filter { seen.insert($0.path).inserted }
    }

    private func shouldDescend(into url: URL) -> Bool {
        let name = url.lastPathComponent
        guard name != ".git", !Self.prunedDirectoryNames.contains(name) else { return false }
        if skipsHiddenDirectories, name.hasPrefix(".") { return false }
        let path = url.standardizedFileURL.path
        if skippedDirectories.contains(where: { $0.path == path }) { return false }
        guard !isSymbolicLink(url) else { return false }
        return isDirectory(url)
    }

    /// The checked-out submodules of the repository at `repository`, and
    /// theirs in turn, read from `.gitmodules` — the walk never enters a
    /// repository, so this is the only way it learns of them. One that is not
    /// checked out has no `.git` and is not a project yet; one the settings
    /// would otherwise leave out (under a skipped directory, say) stays out.
    private func submodules(of repository: URL) -> [ScannedGitRepo] {
        let modules = repository.appendingPathComponent(".gitmodules")
        guard let text = try? String(contentsOf: modules, encoding: .utf8) else { return [] }
        var found: [ScannedGitRepo] = []
        for rawLine in text.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let equals = line.firstIndex(of: "="),
                  line[line.startIndex..<equals].trimmingCharacters(in: .whitespaces) == "path"
            else { continue }
            let relative = line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces)
            guard !relative.isEmpty else { continue }
            let submodule = repository.appendingPathComponent(relative).standardizedFileURL
            guard !skips(path: submodule.path),
                  let gitDirectory = Self.gitDirectory(forCheckout: submodule) else { continue }
            found.append(ScannedGitRepo(
                path: submodule.path,
                remote: Self.originRemote(inGitDirectory: gitDirectory)
            ))
            found.append(contentsOf: submodules(of: submodule))
        }
        return found
    }

    /// The git directory of the checkout at `checkout`: its `.git` directory,
    /// or the one its `.git` file points at.
    private static func gitDirectory(forCheckout checkout: URL) -> URL? {
        let dotGit = checkout.appendingPathComponent(".git")
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dotGit.path, isDirectory: &isDirectory) else { return nil }
        if isDirectory.boolValue { return isGitDirectory(dotGit) ? dotGit : nil }
        guard let target = gitFileTarget(dotGit) else { return nil }
        let resolved = URL(fileURLWithPath: target, relativeTo: checkout).standardizedFileURL
        return isGitDirectory(resolved) ? resolved : nil
    }

    /// What a `.git` file's `gitdir:` line says, as written.
    private static func gitFileTarget(_ dotGit: URL) -> String? {
        guard let text = try? String(contentsOf: dotGit, encoding: .utf8),
              let line = text.split(separator: "\n").first(where: { $0.hasPrefix("gitdir:") })
        else { return nil }
        return line.dropFirst("gitdir:".count).trimmingCharacters(in: .whitespaces)
    }

    /// A submodule's `.git` file points into its superproject's
    /// `.git/modules/`; a linked worktree's points into `.git/worktrees/`.
    private static func isSubmoduleGitFile(_ dotGit: URL) -> Bool {
        gitFileTarget(dotGit)?.contains("/modules/") ?? false
    }

    /// Whether `components` name `directory` itself or something inside it.
    private static func components(_ components: [String], areWithin directory: URL) -> Bool {
        let prefix = directory.pathComponents
        return components.count >= prefix.count && Array(components.prefix(prefix.count)) == prefix
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true
    }

    /// Whether a `.git` directory is one git would actually open.
    ///
    /// `HEAD` is the cheapest thing every repository has and no impostor does:
    /// git itself refuses a `.git` without it, and the folder a hook installer
    /// leaves behind — a lone `hooks/` — has nothing else to tell it apart.
    public static func isGitDirectory(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.appendingPathComponent("HEAD").path)
    }

    /// `origin`'s URL out of `.git/config`, without shelling out to git.
    ///
    /// The config is INI-shaped and the only section that matters is
    /// `[remote "origin"]`, so this reads exactly that rather than pulling in a
    /// parser for a format git itself treats loosely.
    public static func originRemote(inGitDirectory gitDirectory: URL) -> String? {
        let configURL = gitDirectory.appendingPathComponent("config")
        guard let text = try? String(contentsOf: configURL, encoding: .utf8) else { return nil }
        var inOriginSection = false
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                inOriginSection = line.replacingOccurrences(of: " ", with: "") == "[remote\"origin\"]"
                continue
            }
            guard inOriginSection, let equals = line.firstIndex(of: "=") else { continue }
            let key = line[line.startIndex..<equals].trimmingCharacters(in: .whitespaces)
            guard key == "url" else { continue }
            let value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
