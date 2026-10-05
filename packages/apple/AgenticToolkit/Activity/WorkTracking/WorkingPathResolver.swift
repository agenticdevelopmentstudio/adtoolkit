// Uses Core's PathResolverKind and HeuristicTitleParser; Core is macOS-only (review F29).
#if os(macOS)
import Foundation
import AgenticToolkitCore

/// Maps a frontmost window to the path it is working in, and that path's repo.
public struct WorkingPathResolver: Sendable {
    private let locator: RepoLocator
    private let knownRoots: @Sendable () -> [String]

    public init(locator: RepoLocator = RepoLocator(), knownRoots: @escaping @Sendable () -> [String]) {
        self.locator = locator
        self.knownRoots = knownRoots
    }

    /// The path the window is working in, or "" when unresolved.
    public func workingPath(kind: PathResolverKind, documentPath: String?, title: String) -> String {
        switch kind {
        case .document, .terminal, .editor:
            if let document = Self.normalizedDocumentPath(documentPath) { return document }
            return kind == .editor ? rootMatching(title: title) : titlePath(title)
        case .none:
            return rootMatching(title: title)
        }
    }

    /// Working path plus its repo (nil when there is none).
    public func attribution(kind: PathResolverKind, documentPath: String?,
                            title: String) -> (path: String, repo: RepoLocation?) {
        let path = workingPath(kind: kind, documentPath: documentPath, title: title)
        guard !path.isEmpty else { return ("", nil) }
        return (path, locator.locate(path))
    }

    private static func normalizedDocumentPath(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        if raw.hasPrefix("file://") {
            if let path = URL(string: raw)?.path, !path.isEmpty { return path }
            // Unescaped spaces make `URL(string:)` fail; take the text after `file://` as the path.
            let undecoded = String(raw.dropFirst("file://".count))
            let plain = undecoded.removingPercentEncoding ?? undecoded
            return plain.hasPrefix("/") ? plain : nil
        }
        return raw
    }

    /// Document and terminal apps fall back to the title. A terminal titles
    /// its window with the shell's directory, often decorated: `~/src/app`,
    /// `me@host:~/src/app`, `/Volumes/Work/app — -zsh — 80x24`. The first
    /// title part that is a path once its `user@host:` prefix is dropped and
    /// `~` expanded is used; otherwise the title is matched against known roots
    /// (review F20).
    private func titlePath(_ title: String) -> String {
        // The dash parts alone when there are any: a decorated title is never
        // a path whole (`/Volumes/Work/app — -zsh` is not a directory).
        let parts = Self.parts(of: title)
        for part in parts.count > 1 ? Array(parts.dropFirst()) : parts {
            let path = Self.expandedPath(Self.droppingUserAtHost(part))
            if path.hasPrefix("/") { return path }
        }
        return rootMatching(title: title)
    }

    /// The whole title, then its em/en-dash parts (Core's
    /// ``HeuristicTitleParser`` separators, which every title heuristic shares).
    private static func parts(of title: String) -> [String] {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        var parts = [trimmed]
        for separator in HeuristicTitleParser.separators {
            parts = parts.flatMap { $0.components(separatedBy: separator) }
        }
        let split = parts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return split == [trimmed] ? split : [trimmed] + split
    }

    /// `me@host:~/src` → `~/src`. Only a prefix with no space or slash before
    /// the colon counts, so a path that merely contains `@` is left alone.
    private static func droppingUserAtHost(_ part: String) -> String {
        guard let colon = part.firstIndex(of: ":") else { return part }
        let prefix = part[..<colon]
        guard let at = prefix.firstIndex(of: "@"), at != prefix.startIndex, prefix.index(after: at) != colon,
              !prefix.contains(" "), !prefix.contains("/") else { return part }
        return String(part[part.index(after: colon)...])
    }

    private static func expandedPath(_ part: String) -> String {
        guard part == "~" || part.hasPrefix("~/") else { return part }
        return (part as NSString).expandingTildeInPath
    }

    /// The title part that equals a known root's last component; of several
    /// matching roots the longest path wins. Candidates are tried widest
    /// first — the whole title, then its em/en-dash parts, then runs of their
    /// ` - ` pieces, longest run first — so a folder named `Client - Website`
    /// is matched whole before an ASCII hyphen can split it, while
    /// `f.swift - app` still finds `app` (review F19).
    private func rootMatching(title: String) -> String {
        let roots = knownRoots()
        guard !roots.isEmpty else { return "" }
        for name in Self.candidateNames(title) {
            let matches = roots.filter { ($0 as NSString).lastPathComponent == name }
            if let best = matches.max(by: { $0.count < $1.count }) { return best }
        }
        return ""
    }

    static func candidateNames(_ title: String) -> [String] {
        let parts = Self.parts(of: title)
        var names = parts
        for part in parts {
            let pieces = part.components(separatedBy: " - ").map { $0.trimmingCharacters(in: .whitespaces) }
            guard pieces.count > 1 else { continue }
            for length in stride(from: pieces.count - 1, through: 1, by: -1) {
                for start in 0...(pieces.count - length) {
                    names.append(pieces[start..<(start + length)].joined(separator: " - "))
                }
            }
        }
        var seen = Set<String>()
        return names.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
#endif
