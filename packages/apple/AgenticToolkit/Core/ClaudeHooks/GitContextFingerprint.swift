import CryptoKit
import Foundation

/// A fingerprint of the working tree's git state, sampled once per status-line
/// render (branch, `git status --porcelain`, the recent-commits list).
///
/// **What it is, and what it is not.** Claude Code renders a `gitStatus` context
/// block into its system prompt, and that block carries this same information,
/// but the block is a *snapshot taken when the conversation starts*, and its own
/// text says so. So a change in these fields between two renders is **tree
/// drift, not a system-prompt change**: a commit or a `git add` mid-session
/// moves `status_sha256` while the prompt's git block is untouched and cannot
/// have caused any cache miss.
///
/// The prompt's block is still recoverable from what this records, without
/// storing a second copy of it: it is the *first* sample of the session. Later
/// samples answer a different question: how far the tree has moved from what the
/// model believes it to be.
///
/// **Why a fingerprint and not the text.** A system-prompt change re-caches the
/// entire conversation prefix, so one costs the same whether the change was 53
/// characters or 50 kilobytes, which makes *which component changed* the only
/// interesting question, and the cheapest way to answer it is a length plus a
/// hash per candidate component. Storing the status text itself would mean a
/// copy of the user's file names on every render, forever, to answer a yes/no
/// question. The hash answers it.
///
/// **Where it runs.** In the status-line command, on the payload's way to the
/// daemon, so the sample is taken in the session's own working directory at
/// render time, not at ingest time, which on the drop-file fallback path can be
/// minutes later against a moved tree. `sampled_at` is recorded so a consumer
/// can tell the two apart.
///
/// A database layer that flattens the whole payload tree lands these as
/// `stenographer_git_*` columns beside the other status-line columns, with no
/// schema migration.
public enum GitContextFingerprint {

    /// How many commits Claude Code's context block lists.
    public static let recentCommitCount = 5

    /// The payload key the fingerprint is nested under. Namespaced so it can
    /// never collide with a field Anthropic adds to the status-line payload: a
    /// flattening reader would otherwise merge the two into one column space.
    ///
    /// The `stenographer_` prefix is load-bearing, not decoration: the shared
    /// schema's column names, and a daemon's audit of Anthropic's payload schema
    /// per Claude Code version, are keyed on exactly that namespace. Every
    /// daemon that installs these hooks writes this same key, so one set of
    /// columns serves them all. Any future injected key must carry the same
    /// prefix.
    public static let payloadKey = "stenographer_git"

    /// Sample the working tree at `directory` (the session's cwd), or `nil`
    /// when it isn't a git repository — in which case there is no git block in
    /// the system prompt to fingerprint either.
    ///
    /// **Every call is pinned against user config.** A fingerprint whose whole
    /// job is to move when the tree moves is worthless if it also moves when a
    /// `git config` does, or — worse — stays put when the tree moves:
    /// `status.showUntrackedFiles=no` makes `git status --porcelain` report `''`
    /// for a dirty tree, freezing `status_sha256` at the empty digest forever.
    /// `-unormal` matches what Claude Code's own block shows, `--no-renames`
    /// pins `status.renames`, `core.quotePath=true` pins non-ASCII path
    /// escaping, `--no-decorate` pins `log.decorate`, and
    /// `log.showSignature=false` keeps a signed repo from dumping PGP blocks
    /// into `--oneline`.
    ///
    /// The status output is read **untrimmed** (``ReadOnlyGit/rawGit(_:)``):
    /// porcelain's `XY` prefix is two significant columns, and an unstaged-only
    /// change on the alphabetically-first path starts with a literal space.
    public static func sample(directory: String?) -> [String: Any]? {
        let scope: [String] = directory.map { ["-C", $0] } ?? []
        let branch = ReadOnlyGit.git(scope + ["rev-parse", "--abbrev-ref", "HEAD"])
        guard !branch.isEmpty else { return nil }

        let status = ReadOnlyGit.rawGit(
            ["-c", "core.quotePath=true"] + scope
            + ["status", "--porcelain", "-unormal", "--no-renames"]
        )
        let commits = ReadOnlyGit.git(
            ["-c", "log.showSignature=false"] + scope
            + ["log", "--oneline", "--no-decorate", "-\(recentCommitCount)"]
        )

        return [
            "branch": branch,
            "status_char_count": status.count,
            "status_entry_count": statusEntryCount(status),
            "status_sha256": sha256Hex(status),
            "recent_commits_char_count": commits.count,
            "recent_commits_sha256": sha256Hex(commits),
            "sampled_at": ISO8601DateFormatter().string(from: Date())
        ]
    }

    /// Porcelain emits one newline-terminated line per entry, so the entry count
    /// is the number of non-empty lines — not `components(separatedBy:).count`,
    /// which counts the empty string after the final newline as an entry.
    private static func statusEntryCount(_ status: String) -> Int {
        status.split(separator: "\n", omittingEmptySubsequences: true).count
    }

    /// Returns `payload` with the fingerprint nested under `payloadKey`, or the
    /// payload unchanged when it isn't a JSON object, isn't a git repository,
    /// or can't be encoded. Enrichment is best-effort by design: a fumbled
    /// sample must never cost the daemon the row it was decorating.
    ///
    /// **The original bytes are spliced, never re-encoded.** Decoding the
    /// payload and re-serialising it looks equivalent and is not: the round trip
    /// collapses a JSON `1.0` to `1` (the `NSNumber` arrives as `objCType 'd'`
    /// and leaves as `'q'`), and `DynamicSchema.affinity` types a column from
    /// the first value it sees. A fresh install whose first `prompt_cache`
    /// sample happens to be a perfectly warm `hit_ratio: 1.0` would declare that
    /// column INTEGER permanently — `migration033` retypes only TEXT — and every
    /// later `0.973…` would truncate to 0. Splicing also keeps key order stable,
    /// which matters because `opaquePayloadSubtrees` stores
    /// `prompt_cache_miss_causes` as literal JSON text.
    ///
    /// `isValidJSONObject` is checked rather than relying on `try?`, for the
    /// reason `jsonText` documents in a database layer: `data(withJSONObject:)`
    /// signals an unrepresentable value by *raising an Objective-C exception*,
    /// which is not a Swift error and which `try?` does not catch. On this path
    /// that would kill the status-line command outright and Claude Code would
    /// draw no status line at all.
    public static func enriched(payload: Data) -> Data {
        guard let object = try? JSONSerialization.jsonObject(with: payload),
              let claudeData = object as? [String: Any] else { return payload }
        // The session's directory as Claude Code reports it, so the sample can't
        // drift onto whatever cwd this process happened to inherit.
        let directory = (claudeData["cwd"] as? String)
            ?? ((claudeData["workspace"] as? [String: Any])?["current_dir"] as? String)
        guard let fingerprint = sample(directory: directory),
              JSONSerialization.isValidJSONObject(fingerprint),
              let encoded = try? JSONSerialization.data(
                  withJSONObject: fingerprint, options: [.sortedKeys]
              ) else { return payload }

        // The payload parsed as an object, so its last `}` closes it and
        // everything after it is whitespace.
        guard let closing = payload.lastIndex(of: UInt8(ascii: "}")) else { return payload }
        var out = Data()
        out.append(payload[..<closing])
        if !claudeData.isEmpty { out.append(UInt8(ascii: ",")) }
        out.append(Data("\"\(payloadKey)\":".utf8))
        out.append(encoded)
        out.append(payload[closing...])
        return out
    }

    private static func sha256Hex(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).hexString
    }
}
