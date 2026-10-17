#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import CryptoKit
import Foundation

/// Computes extra metadata (size + SHA256) for the file an event's `file_path`
/// names, so a consumer can tell *whether the file changed* between two events
/// without us storing the file contents.
///
/// Two event types carry a `file_path` worth fingerprinting, and both feed the
/// same question — what changed in the model's system prompt between one turn
/// and the next:
///
/// - `ConfigChange` — the menubar's detail window shows what a settings or
///   skill file was like at change time.
/// - `InstructionsLoaded` — every CLAUDE.md (user, project, local) Claude Code
///   loaded into the system prompt. The size+hash pair is what lets a
///   `system_prompt_changed` cache miss be *attributed* to an instructions edit
///   rather than guessed at: the path alone repeats unchanged on every load, so
///   it cannot distinguish an edited CLAUDE.md from an untouched one.
public enum FileFingerprintEnricher {
    /// Upper bound on files we'll hash. Config and instruction files are
    /// typically a few hundred KB; skip anything larger to keep the ingest
    /// queue snappy.
    static let maxHashBytes: Int = 10 * 1024 * 1024

    /// Returns (file_size_bytes, file_sha256) for the file the event points at,
    /// or an empty dict when the path is missing, is not a plain file, or can't
    /// be measured. Additions to the returned dict are the new fields to merge
    /// into the per-type row.
    ///
    /// **Everything here is gated on `attributesOfItem` succeeding and reporting
    /// a regular file**, and that ordering is the whole safety story. `file_path`
    /// arrives from a hook payload, and this runs on the daemon's single ingest
    /// worker — the one that also owns the SQLite writer. `Data(contentsOf:)`
    /// against a FIFO blocks in `read(2)` until something opens the other end,
    /// which is *not* interruptible by `BoundedDatabase`'s ejection handler
    /// (a `sqlite3_progress_handler`, which only fires between VDBE steps), so a
    /// single named pipe under a watched path stalls capture indefinitely.
    /// A character device is the same wedge with no end: `/dev/zero` reads
    /// forever, and the size the filesystem reports for it is 0, which is why
    /// the size cap alone is not a defence.
    ///
    /// The cap is checked outside the attribute binding for the same reason:
    /// letting an unreadable-attributes path fall through to the read is exactly
    /// the case where the size is unknown, and hashing a file of unknown size is
    /// the thing the cap exists to prevent.
    ///
    /// The check goes through `URLResourceValues` rather than
    /// `FileManager.attributesOfItem(atPath:)` because the latter is `lstat`:
    /// it reports a symlink as `.typeSymbolicLink` regardless of what it points
    /// at, and a symlinked CLAUDE.md is ordinary. `.isRegularFileKey` follows
    /// the link, so the type and the size describe the same bytes the hash will.
    public static func enrich(hookData: [String: Any]) -> [String: Any] {
        guard let path = hookData["file_path"] as? String, !path.isEmpty else { return [:] }
        guard let values = try? URL(fileURLWithPath: path)
                .resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
              values.isRegularFile == true,
              let size = values.fileSize else { return [:] }

        var out: [String: Any] = ["file_size_bytes": size]
        guard size <= maxHashBytes else { return out }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            out["file_sha256"] = SHA256.hash(data: data).hexString
        }
        return out
    }
}
#endif
