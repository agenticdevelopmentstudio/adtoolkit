#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Transcript file cursors (per-file resume point)

    /// Where a transcript file was last read to, plus the identity evidence needed
    /// to decide whether resuming there is still valid. See `migration029`.
    public struct TranscriptFileCursor: Sendable, Equatable {
        public let byteOffset: Int64
        public let lineNo: Int
        public let fileSize: Int64
        public let inode: UInt64
        public let headHash: String

        public init(byteOffset: Int64, lineNo: Int, fileSize: Int64, inode: UInt64, headHash: String) {
            self.byteOffset = byteOffset
            self.lineNo = lineNo
            self.fileSize = fileSize
            self.inode = inode
            self.headHash = headHash
        }
    }

    public func transcriptFileCursor(for filePath: String) throws -> TranscriptFileCursor? {
        var result: TranscriptFileCursor?
        try query("""
            SELECT byte_offset, line_no, file_size, inode, head_hash
            FROM transcript_file_cursors WHERE file_path = ?
        """, params: [filePath]) { row in
            result = TranscriptFileCursor(
                byteOffset: Int64(int(row, 0)),
                lineNo: Int(int(row, 1)),
                fileSize: Int64(int(row, 2)),
                inode: UInt64(bitPattern: Int64(int(row, 3))),
                headHash: string(row, 4)
            )
        }
        return result
    }

    public func setTranscriptFileCursor(_ cursor: TranscriptFileCursor, filePath: String) throws {
        // `execute` is reentrant on the current connection, so this joins the
        // caller's batch transaction rather than opening a nested write.
        try execute("""
            INSERT INTO transcript_file_cursors
                (file_path, byte_offset, line_no, file_size, inode, head_hash, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
            ON CONFLICT(file_path) DO UPDATE SET
                byte_offset = excluded.byte_offset,
                line_no     = excluded.line_no,
                file_size   = excluded.file_size,
                inode       = excluded.inode,
                head_hash   = excluded.head_hash,
                updated_at  = excluded.updated_at
        """, params: [
            filePath, cursor.byteOffset, cursor.lineNo, cursor.fileSize,
            Int64(bitPattern: cursor.inode), cursor.headHash
        ])
    }

    /// Drops cursor rows for transcripts under `root` that no longer exist on disk.
    ///
    /// Nothing else ever deletes from `transcript_file_cursors`, so without this the
    /// table is the one structure in the database with no retention at all: every
    /// transcript the daemon has ever seen keeps a row, including deleted projects
    /// and `~/.claude/projects` directories the user has cleaned out. Those rows
    /// are not only dead weight: `transcriptCursorStats` sums `file_size` across all
    /// of them, so the cursor stats describe a corpus that still counts files deleted
    /// months ago and can only ever grow.
    ///
    /// Scoped to `root` (a prefix test, not a `LIKE` — a path may legitimately
    /// contain `%` or `_`) so a caller that walked one directory can never delete
    /// cursors belonging to a tree it did not look at. `existingPaths` must be the
    /// COMPLETE set of transcripts found under `root`, before any `since`/`maxFiles`
    /// narrowing — a partial set here would delete live cursors and force a full
    /// re-read of every file it omitted.
    @discardableResult
    public func pruneTranscriptFileCursors(existingPaths: Set<String>, under root: String) throws -> Int {
        let prefix = root.hasSuffix("/") ? root : root + "/"
        var doomed: [String] = []
        try read { _ in
            try query(
                "SELECT file_path FROM transcript_file_cursors WHERE instr(file_path, ?) = 1",
                params: [prefix]
            ) { row in
                let path = string(row, 0)
                if !existingPaths.contains(path) { doomed.append(path) }
            }
        }
        guard !doomed.isEmpty else { return 0 }
        // Chunked: SQLITE_MAX_VARIABLE_NUMBER is 999 on the conservative builds and
        // a long-lived install can easily strand more dead cursors than that.
        for batch in stride(from: 0, to: doomed.count, by: 500) {
            let slice = Array(doomed[batch..<Swift.min(batch + 500, doomed.count)])
            let placeholders = Array(repeating: "?", count: slice.count).joined(separator: ",")
            try execute(
                "DELETE FROM transcript_file_cursors WHERE file_path IN (\(placeholders))",
                params: slice
            )
        }
        return doomed.count
    }

    /// Aggregate view of the JSONL byte cursors.
    ///
    /// The one question this answers: is the importer reading tails or whole
    /// files? `bytesCovered` close to `bytesOnDisk` means the cursors are doing
    /// their job. A large gap means files are being re-read from zero — either a
    /// fresh install still backfilling, or cursors being rejected (inode/hash
    /// mismatch), which is the failure mode worth catching early.
    public func transcriptCursorStats() throws -> TranscriptCursorStatsDTO {
        var files = 0
        var bytesCovered: Int64 = 0
        var bytesOnDisk: Int64 = 0
        var oldest: String?
        var newest: String?
        try query("""
            SELECT count(*), coalesce(sum(byte_offset), 0), coalesce(sum(file_size), 0),
                   min(updated_at), max(updated_at)
            FROM transcript_file_cursors
        """) { row in
            files = int(row, 0)
            bytesCovered = int64(row, 1)
            bytesOnDisk = int64(row, 2)
            oldest = optionalString(row, 3)
            newest = optionalString(row, 4)
        }
        return TranscriptCursorStatsDTO(
            files: files,
            bytesCovered: bytesCovered,
            bytesOnDisk: bytesOnDisk,
            oldestUpdatedAt: oldest,
            newestUpdatedAt: newest
        )
    }

}
#endif
