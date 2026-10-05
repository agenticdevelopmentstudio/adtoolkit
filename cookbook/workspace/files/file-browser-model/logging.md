
Not applicable: none of `FileBrowserDirectories`,
`FileBrowserRestorationState`, or `FileTreeManager` calls a logging API
directly. Logging for this subsystem is performed entirely by the delegated
`DirectoryWatchCoordinator`, `GitStatusProvider`, and `IDEDetector` helpers,
each of which implements its own logging — not by the three types this
recipe specifies.

