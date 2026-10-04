import Foundation

/// Moves a directory to its new name exactly once, losslessly.
///
/// Only ever an atomic `rename(2)` on the same volume (plus `rmdir` of an empty
/// placeholder): no copy, no merge, no delete of data. When both directories
/// exist nothing is touched — the caller uses the current one and reports the
/// leftover, because merging two live databases is not something a launch-time
/// migration may guess at.
///
/// `markers` names files that prove `current` holds real data. When given and
/// `current` holds none of them, `current` is a placeholder (a fresh launch
/// created it before migration ran): an empty one is removed, a non-empty one is
/// renamed aside, and the legacy directory takes its place.
public enum LegacyDirectoryMigration {
    public enum Outcome: Equatable, Sendable {
        case nothingToMigrate, migrated, alreadyMigrated, bothExist
    }

    public static func migrate(
        from legacy: URL, to current: URL, markers: [String] = [],
        fileManager: FileManager = .default
    ) throws -> Outcome {
        let legacyExists = fileManager.fileExists(atPath: legacy.path)
        var currentExists = fileManager.fileExists(atPath: current.path)
        if legacyExists, currentExists, !markers.isEmpty {
            let entries = try fileManager.contentsOfDirectory(atPath: current.path)
            if markers.allSatisfy({ !entries.contains($0) }) {
                if entries.isEmpty {
                    // rmdir semantics: fails if anything appeared in between.
                    guard rmdir(current.path) == 0 else {
                        throw CocoaError(.fileWriteUnknown, userInfo: [
                            NSFilePathErrorKey: current.path,
                            NSUnderlyingErrorKey: NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
                        ])
                    }
                } else {
                    let stamp = DateFormatter()
                    stamp.locale = Locale(identifier: "en_US_POSIX")
                    stamp.dateFormat = "yyyyMMdd-HHmmss"
                    let aside = current.deletingLastPathComponent().appendingPathComponent(
                        "\(current.lastPathComponent).preempted-\(stamp.string(from: Date()))",
                        isDirectory: true)
                    try fileManager.moveItem(at: current, to: aside)
                }
                currentExists = false
            }
        }
        switch (legacyExists, currentExists) {
        case (false, false): return .nothingToMigrate
        case (false, true): return .alreadyMigrated
        case (true, true): return .bothExist
        case (true, false):
            try fileManager.createDirectory(
                at: current.deletingLastPathComponent(), withIntermediateDirectories: true)
            // moveItem on one volume is rename(2): atomic, and it fails rather
            // than overwrite if `current` appeared in between.
            try fileManager.moveItem(at: legacy, to: current)
            return .migrated
        }
    }
}
