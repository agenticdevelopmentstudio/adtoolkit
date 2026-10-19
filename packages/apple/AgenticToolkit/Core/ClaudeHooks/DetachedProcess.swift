import Foundation

/// Starts a process that outlives this one and hangs off launchd, not off us.
///
/// A `/bin/sh` trampoline starts the command in the background and exits at
/// once, so by the time `spawn` returns the command has been reparented. The
/// status-line dispatcher kills a timed-out renderer by walking its
/// descendants (`pgrep -P`); a process reparented this way is out of that
/// walk's reach, and it leaves this process's session too (`setsid`), so a
/// signal to the terminal's process group misses it as well.
public enum DetachedProcess {

    /// Runs `executable arguments…` detached with `stdin` as its standard
    /// input and its output discarded. False when nothing could be started.
    public static func spawn(executable: String, arguments: [String], environment: [String: String],
                             stdin: Data) -> Bool {
        var pipeEnds: [Int32] = [0, 0]
        guard pipe(&pipeEnds) == 0 else { return false }
        let (readEnd, writeEnd) = (pipeEnds[0], pipeEnds[1])
        defer { close(readEnd) }

        var actions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&actions)
        defer { posix_spawn_file_actions_destroy(&actions) }
        for descriptor: Int32 in [0, 1, 2] {
            let flags = descriptor == 0 ? O_RDONLY : O_WRONLY
            posix_spawn_file_actions_addopen(&actions, descriptor, "/dev/null", flags, 0)
        }
        // The payload reaches the command on fd 3: an asynchronous list in a
        // non-interactive shell gets /dev/null on fd 0 unless told otherwise.
        posix_spawn_file_actions_adddup2(&actions, readEnd, 3)

        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        // Only 0-3 cross over: no pipe of the caller's, the dispatcher's stdout
        // among them, is held open by a process that outlives it.
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT))

        let script = #"exe=$1; shift; "$exe" "$@" <&3 3<&- &"#
        let argv = ["/bin/sh", "-c", script, "sh", executable] + arguments
        let envp = environment.map { "\($0.key)=\($0.value)" }
        var trampoline: pid_t = 0
        let spawned = withCStrings(argv) { argvPointers in
            withCStrings(envp) { envPointers in
                posix_spawn(&trampoline, "/bin/sh", &actions, &attributes, argvPointers, envPointers)
            }
        }
        guard spawned == 0 else {
            close(writeEnd)
            return false
        }
        let handle = FileHandle(fileDescriptor: writeEnd, closeOnDealloc: true)
        try? handle.write(contentsOf: stdin)
        try? handle.close()
        var status: Int32 = 0
        while waitpid(trampoline, &status, 0) == -1 && errno == EINTR {}
        return true
    }

    private static func withCStrings<R>(_ strings: [String],
                                        _ body: ([UnsafeMutablePointer<CChar>?]) -> R) -> R {
        let pointers = strings.map { strdup($0) } + [nil]
        defer { pointers.forEach { free($0) } }
        return body(pointers)
    }
}

/// One status-line feed per session at a time. Claude Code re-renders often,
/// and a feed can take seconds (three `git` calls and a POST); a render that
/// finds its session's previous feed still running skips its own, and the
/// next render carries the newer snapshot instead of piling up behind it.
public struct FeedLock {

    private let descriptor: Int32

    /// Where the lock for `sessionID` of the daemon called `name` lives
    /// (`<name>-statusline-feed-<session>.lock`, with the session id reduced to
    /// ASCII letters, digits and `-`). Tests remove it to start clean.
    public static func fileURL(sessionID: String, name: String,
                               directory: URL = URL(fileURLWithPath: NSTemporaryDirectory())) -> URL {
        let safe = String(String.UnicodeScalarView(sessionID.unicodeScalars.prefix(128).map {
            $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "-") ? $0 : "_"
        }))
        return directory.appendingPathComponent("\(name)-statusline-feed-\(safe).lock")
    }

    /// The lock for `sessionID` of the daemon called `name`
    /// (`<name>-statusline-feed-<session>.lock`, with the session id reduced to
    /// ASCII letters, digits and `-`), or nil when another feed holds it. When no
    /// lock file can be made the lock is a no-op: the feed runs unguarded rather
    /// than not at all.
    public static func acquire(sessionID: String, name: String,
                               directory: URL = URL(fileURLWithPath: NSTemporaryDirectory()))
        -> FeedLock? {
        let path = fileURL(sessionID: sessionID, name: name, directory: directory).path
        let descriptor = open(path, O_RDWR | O_CREAT | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else { return FeedLock(descriptor: -1) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return nil
        }
        return FeedLock(descriptor: descriptor)
    }

    /// Closing the file releases the `flock`; the lock also dies with the
    /// process, so a killed feed never leaves its session locked.
    public func release() {
        if descriptor >= 0 { close(descriptor) }
    }
}
