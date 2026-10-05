
- **Empty window ID**: Registering a controller MUST ignore one with an
  empty window id; storage calls with an empty id compose a key that is
  just the prefix and MUST behave like any other key.
- **Duplicate registration**: Re-registering an id MUST replace the
  previous weak entry; the earlier controller is no longer reachable
  through the registry even if still alive.
- **Duplicate restorable ID**: A second registration for the same id MUST
  replace the first factory.
- **Factory that does not register**: A factory that builds nothing, or
  builds a controller that is not registered, MUST NOT stop the pass; if
  its window was persisted visible, the missing-factory check does not fire
  because a factory exists for the id (the check only looks for a missing
  factory and a missing controller together).
- **Repeated restore**: Running the launch-restore pass twice MUST rerun
  every factory; idempotence of the factories is the host's responsibility.
- **Ordering**: Factory execution and the registry visibility pass MUST run
  in dictionary order, which is unspecified; a host that needs one window
  shown before another cannot rely on registration order.
- **Headless run**: The reopen-recents step MUST return without effect
  when there is no running app instance (unit tests).
- **Recent URL already open**: A recent URL that matches an open document's
  file URL MUST NOT be opened again.
- **Recent document missing on disk**: The open request is issued; the
  failure is discarded (see the open question on reopen-open-failure).
- **Recents limit out of range**: A zero or negative recent-windows-count
  value MUST be written to the platform's recent-documents limit setting
  unchanged; how the platform interprets it is the platform's behavior.
- **Termination during close**: Windows closed by the platform after the
  app-termination notification MUST keep their persisted visibility; once
  latched, the termination flag never clears within the process.
- **Deallocated controller**: A registry entry whose controller was
  released MUST read as absent from lookup, the registered-ids list, the
  visible-ids list, and the has-visible-window flag.
- **Sunk window**: A window sunk behind the desktop by quiet presentation
  MUST still count as visible
  (`WindowRegistryVisibilityTests.testASunkWindowStillCountsAsVisible`).
- **Undecodable stored state**: Corrupt or non-JSON data under a
  `WindowState_` key MUST read as nothing; the next save overwrites it.
- **Missing or non-boolean visibility value**: A missing key MUST read as
  nothing in both implementations; a non-boolean value reads as nothing in
  the platform-preferences implementation and false in the
  settings-store-backed implementation.
- **Two app copies**: Without isolating to the running bundle, two builds
  sharing an app identity MUST share window-state keys; the last writer
  wins.
- **Namespace changed mid-run**: Keys written before a namespace change
  MUST stay under the old prefix and are not migrated.
- **Namespace collision**: Two paths whose SHA-256 digests share their
  first 4 bytes MUST share a namespace (a 1-in-2^32 chance per pair); the
  source accepts this.
- **Concurrent access**: All manager, registry, and storage operations run
  on the window manager's single designated thread and are serialized; the
  window-state namespace's reads and writes are serialized by its own
  lock.
- **Missing capture symbol**: If the platform stops exporting its
  window-list image capture facility, the own-window-capture operation MUST
  return nothing and the write-PNG operation MUST return false.
- **Unwritable screenshot URL**: The write error MUST be converted to a
  false return; the error itself is not surfaced.
- **Offline or disconnected state**: Not applicable; the component
  performs no network I/O.

