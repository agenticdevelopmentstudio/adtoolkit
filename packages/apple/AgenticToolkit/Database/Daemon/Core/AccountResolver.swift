#if canImport(AgenticToolkitCore)
import Foundation

/// Resolves the current Claude account email from `~/.claude.json`'s
/// `oauthAccount.emailAddress` — the fallback a fingerprint miss falls to.
///
/// Shared by the daemon and the CLI: `steno hook` must read the login at the
/// moment the hook fires, with the same reader the daemon uses when it drains
/// an envelope that carries none.
///
/// Returns `""` whenever no account can be determined — file missing,
/// unreadable, malformed JSON, or an API-key user with no `oauthAccount`.
/// Account resolution must never throw into the ingestion path: a missing
/// account is recorded as the empty sentinel, not a crash.
///
/// The resolved value is cached keyed on the file's modification date, so
/// the high-volume `transcript_turns` insert path does not re-read and
/// re-parse JSON per row. `~/.claude.json` is rewritten when the user
/// switches accounts, changing its mtime and invalidating the cache.
public final class AccountResolver: @unchecked Sendable {

    private let path: String
    private let lock = NSLock()
    private var cachedEmail = ""
    private var cachedMtime: Date?
    private var hasCached = false

    public init(claudeJSONPath: String? = nil) {
        self.path = claudeJSONPath
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude.json").path
    }

    /// Current account email, or `""` if none can be resolved.
    public func currentEmail() -> String {
        lock.lock()
        defer { lock.unlock() }

        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        let mtime = attrs?[.modificationDate] as? Date

        if hasCached && mtime == cachedMtime {
            return cachedEmail
        }
        cachedEmail = readEmail()
        cachedMtime = mtime
        hasCached = true
        return cachedEmail
    }

    private func readEmail() -> String {
        guard
            let data = FileManager.default.contents(atPath: path),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let oauth = json["oauthAccount"] as? [String: Any],
            let email = oauth["emailAddress"] as? String
        else {
            return ""
        }
        return email
    }
}
#endif
