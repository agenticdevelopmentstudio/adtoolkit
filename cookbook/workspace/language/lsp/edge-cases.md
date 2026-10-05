
- **Null/empty input**: The diagnostics store publishing an empty
  diagnostics array for a URI MUST clear it rather than be ignored
  (empty-diagnostics-clears-not-ignored). A diagnostics publish with a
  missing version MUST still be stored (stale-diagnostics-never-dropped).
- **Boundary/malformed values**: A workspace-root marker list containing a
  glob-suffix marker (`*.xcodeproj`) with no literal match on disk MUST
  fall through to the next marker in the walk rather than throw
  (root-marker-walk-innermost-first). A truncated protocol frame mid-body
  MUST fail the session start with the transport error rather than hang
  (truncated-frame-fails-session).
- **Concurrent access**: Two concurrent starts MUST join into one process
  spawn (start-is-idempotent-and-joined). Stopping the session while it is
  still spawning MUST NOT leave an orphaned child process
  (stop-during-start-does-not-orphan). A retired session's late state
  transition MUST NOT overwrite its replacement's entry in the published
  session-state table (retired-session-late-transition-cannot-overwrite).
  A second concurrent observation of the same session's state MUST be
  refused, not doubled (observe-state-refuses-second-observer).
- **Error states**: A clean, unrequested process exit MUST be reported as
  failed, never as an ordinary stopped shutdown (unasked-exit-is-a-failure).
  Reading the session's capabilities MUST answer nothing once a running
  server has died on its own, even though the last observed state was
  running (capabilities-go-nil-after-spontaneous-death). A pipeline whose
  session failed to start MUST forward none of its queued events and MUST
  NOT retry the start (failed-start-pipeline-forwards-nothing).
- **Workspace-scope boundary**: A document whose path is a string prefix
  collision with the workspace root (a sibling directory, not a true
  descendant) MUST be classified out of scope
  (string-prefix-sibling-excluded); a document reached only through a
  symlinked root MUST still be classified in scope after path resolution
  (scope-check-resolves-symlinks).
- **Shutdown races**: A configuration/settings write delivered while the
  registry's shutdown is in flight MUST start no new session
  (settings-write-during-shutdown-starts-nothing); shutting the registry
  down MUST still wait for a session reconciliation had already begun
  retiring before shutdown started (shutdown-waits-for-retired-teardowns).

