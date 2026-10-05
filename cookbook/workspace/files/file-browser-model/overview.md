
Three model/coordinator types that together form the non-visual contract
behind the file browser: `FileBrowserDirectories` (the primary root plus any
additional roots the user has added), `FileBrowserRestorationState` (which
directories were disclosed and which file was selected, for a host to persist
and restore), and `FileTreeManager` (the per-root coordinator that delegates
directory scanning and filesystem watching to a `DirectoryWatchCoordinator`,
overlays git status from a `GitStatusProvider`, and runs IDE-marker detection
through an `IDEDetector`). None of the three draws anything; they are the
state and orchestration a UI layer such as a file browser view or a file tree
outline view observes and drives.

