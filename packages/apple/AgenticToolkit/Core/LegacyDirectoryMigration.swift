import Foundation

/// Moves a directory to its new name exactly once, losslessly.
///
/// Only ever an atomic `rename(2)` on the same volume (plus `rmdir` of an empty
/// placeholder): no copy, no merge, no delete of data. A cross-volume move
/// fails with `EXDEV` rather than copying, and an existing destination fails
/// with `EEXIST` rather than being replaced. When both directories exist
/// nothing is touched — the caller uses the current one and reports the
/// leftover, because merging two live databases is not something a launch-time
/// migration may guess at.
///
/// `markers` names files that prove `current` holds real data. When given and
/// `current` holds none of them at its top level, `current` is a placeholder (a
/// fresh launch created it before migration ran): an empty one is removed, a
/// non-empty one is renamed aside (reported as `.migratedReplacingPlaceholder`),
/// and the legacy directory takes its place.
///
/// A filesystem without `RENAME_EXCL` support throws `ENOTSUP` and nothing is moved.
///
/// Callers must run `migrate` before anything opens files in `current`: the
/// placeholder check lists the directory and then moves it, so a writer that
/// creates a marker in between would be moved aside with the placeholder.
public enum LegacyDirectoryMigration {
    public enum Outcome: Equatable, Sendable {
        case nothingToMigrate, migrated, alreadyMigrated, bothExist
        /// A non-empty placeholder was renamed to `asideAt`; nothing was deleted.
        case migratedReplacingPlaceholder(asideAt: URL)
    }

    public enum MigrationError: Error, Sendable {
        /// The move failed and the placeholder could not be put back: its contents
        /// are at `asideAt`.
        case rollbackFailed(original: any Error, asideAt: URL)
    }

    private static let maxAsideAttempts = 100

    public static func migrate(
        from legacy: URL, to current: URL, markers: [String] = [],
        fileManager: FileManager = .default
    ) throws -> Outcome {
        if legacy.standardizedFileURL.resolvingSymlinksInPath()
            == current.standardizedFileURL.resolvingSymlinksInPath() {
            return .alreadyMigrated
        }
        let legacyExists = fileManager.fileExists(atPath: legacy.path)
        var currentExists = fileManager.fileExists(atPath: current.path)
        var asideAt: URL?
        if legacyExists, currentExists, !markers.isEmpty {
            let entries = try fileManager.contentsOfDirectory(atPath: current.path)
            if markers.allSatisfy({ !entries.contains($0) }) {
                if entries.isEmpty {
                    // rmdir semantics: fails if anything appeared in between.
                    if rmdir(current.path) != 0 {
                        let err = errno
                        throw POSIXError(POSIXErrorCode(rawValue: err) ?? .EIO)
                    }
                } else {
                    asideAt = try renameAside(current)
                }
                currentExists = false
            }
        }
        switch (legacyExists, currentExists) {
        case (false, false): return .nothingToMigrate
        case (false, true): return .alreadyMigrated
        case (true, true): return .bothExist
        case (true, false):
            do {
                try fileManager.createDirectory(
                    at: current.deletingLastPathComponent(), withIntermediateDirectories: true)
                try renameExclusive(legacy, to: current)
            } catch let originalError {
                // Put the placeholder back where it was (best effort), then rethrow.
                if let asideAt {
                    do { try renameExclusive(asideAt, to: current) } catch {
                        throw MigrationError.rollbackFailed(original: originalError, asideAt: asideAt)
                    }
                }
                throw originalError
            }
            return asideAt.map { .migratedReplacingPlaceholder(asideAt: $0) } ?? .migrated
        }
    }

    /// `rename(2)` that refuses to replace an existing destination (`EEXIST`)
    /// and never crosses a volume (`EXDEV`); never copies.
    private static func renameExclusive(_ source: URL, to destination: URL) throws {
        if renamex_np(source.path, destination.path, UInt32(RENAME_EXCL)) != 0 {
            let err = errno
            throw POSIXError(POSIXErrorCode(rawValue: err) ?? .EIO)
        }
    }

    /// Renames `directory` to a free sibling `<name>.preempted-<timestamp>[-n]`.
    private static func renameAside(_ directory: URL) throws -> URL {
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.dateFormat = "yyyyMMdd-HHmmss"
        let base = "\(directory.lastPathComponent).preempted-\(stamp.string(from: Date()))"
        let parent = directory.deletingLastPathComponent()
        var lastError: Error = POSIXError(.EEXIST)
        for attempt in 0..<maxAsideAttempts {
            let name = attempt == 0 ? base : "\(base)-\(attempt)"
            let aside = parent.appendingPathComponent(name, isDirectory: true)
            do {
                try renameExclusive(directory, to: aside)
                return aside
            } catch let error as POSIXError where error.code == .EEXIST {
                lastError = error
            }
        }
        throw lastError
    }
}
