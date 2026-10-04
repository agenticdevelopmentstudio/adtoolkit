import Foundation

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

    /// Document and terminal apps fall back to the title: an absolute path in
    /// the title is used as is, otherwise it is matched against known roots.
    private func titlePath(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("/") { return trimmed }
        return rootMatching(title: title)
    }

    /// The first part of the title that equals a known root's last component;
    /// of several matching roots the longest path wins.
    private func rootMatching(title: String) -> String {
        var parts = [title]
        for separator in [" — ", " – ", " - "] {
            parts = parts.flatMap { $0.components(separatedBy: separator) }
        }
        let names = parts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let roots = knownRoots()
        for name in names {
            let matches = roots.filter { ($0 as NSString).lastPathComponent == name }
            if let best = matches.max(by: { $0.count < $1.count }) { return best }
        }
        return ""
    }
}
