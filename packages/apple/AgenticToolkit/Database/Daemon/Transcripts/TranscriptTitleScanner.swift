#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// A transcript's latest `custom-title`, found by resuming each file where the
/// previous scan of it stopped.
///
/// Every Stop and SessionEnd hook asks for the title, and a transcript is
/// append-only and can reach 130 MB. Re-reading the whole file on every turn of a
/// long session was ~1.4 of 20 sampled daemon seconds, re-matching megabytes that
/// had already been searched and could not hold a new title. Only what was
/// appended since the last scan can.
///
/// A file that was replaced (a different inode), shrank, or no longer holds the
/// bytes the cursor was taken over is not the file the cursor describes, so it
/// is scanned again from the start. The last check is the importer's own
/// ``JSONLScanner/resumeFingerprint(at:upTo:byteCount:)``: a transcript rewritten
/// in place at the same or a greater length keeps its inode and its size, and
/// resuming it would keep a title the rewrite moved or changed.
///
/// The resume rule — inode, size and fingerprint, bounded map, scan outside the
/// lock — is the toolkit's `AppendOnlyFileCursor`. What stays here is the title
/// state, the chunk predicate, the importer's line reader and fingerprint, and
/// the 256-path capacity.
public final class TranscriptTitleScanner: Sendable {
    /// Paths remembered at once. One per live session is the working set; past
    /// this the whole map is dropped, which costs one full scan per path.
    public static let capacity = 256

    public init() {}

    private let cursor = AppendOnlyFileCursor<String?>(
        capacity: TranscriptTitleScanner.capacity,
        initial: nil,
        fingerprint: { url, offset in try JSONLScanner.resumeFingerprint(at: url, upTo: offset) },
        read: { url, start, latest in
            try JSONLScanner.streamCompleteLines(at: url, startingAtByte: start) { chunk in
                if let title = SessionEnricher.lastCustomTitle(in: chunk) { latest = title }
            }.bytesConsumed
        }
    )

    /// The last non-empty `custom-title` in the transcript at `path`, or nil when
    /// it has none or cannot be read.
    public func title(path: String) -> String? {
        cursor.scan(path: path) ?? nil
    }

    /// Where the next scan of `path` starts; nil when it has no cursor.
    public func resumeOffset(path: String) -> Int64? {
        cursor.resumeOffset(path: path)
    }
}
#endif
