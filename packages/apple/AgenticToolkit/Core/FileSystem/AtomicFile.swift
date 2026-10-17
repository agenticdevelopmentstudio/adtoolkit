import Foundation

/// Replaces a file the way claudehelpers' settings contract asks
/// (`external/claudehelpers/scripts/statuslinedispatcher/docs/settings.md`): a
/// sibling temporary file created at the final mode, then `rename(2)` over the
/// target. A reader sees the old file or the new one, never half of one, and
/// the new file is never visible with looser permissions than `mode`.
///
/// A symlinked target is followed, so a dotfiles-managed link survives and the
/// file it names is the one replaced.
public enum AtomicFile {

    public static func write(_ data: Data, to url: URL, mode: mode_t) throws {
        let target = url.resolvingSymlinksInPath()
        let directory = target.deletingLastPathComponent()
        var template = Array(directory.appendingPathComponent(".\(target.lastPathComponent).XXXXXX").path.utf8CString)
        let descriptor = mkstemp(&template)
        guard descriptor >= 0 else { throw posixError() }
        let temporary = template.withUnsafeBufferPointer { buffer in
            let path = buffer.baseAddress!
            return FileManager.default.string(withFileSystemRepresentation: path, length: strlen(path))
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        let written: Result<Void, Error> = Result {
            guard fchmod(descriptor, mode) == 0 else { throw posixError() }
            try handle.write(contentsOf: data)
        }
        let closeError = close(descriptor) == 0 ? nil : posixError()
        do {
            try written.get()
            if let closeError { throw closeError }
            guard rename(temporary, target.path) == 0 else { throw posixError() }
        } catch {
            unlink(temporary)
            throw error
        }
    }

    /// The permission bits of the file `url` names, following a symlink; nil
    /// when there is no such file.
    public static func mode(of url: URL) -> mode_t? {
        var info = stat()
        guard stat(url.path, &info) == 0 else { return nil }
        return info.st_mode & 0o7777
    }

    private static func posixError() -> POSIXError {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}
