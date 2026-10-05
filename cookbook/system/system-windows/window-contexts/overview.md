
The contexts slice of the system-window feature groups other applications' windows into named **contexts** (workspaces such as "iOS App" or "Docs") and switches between them by moving every window that does not belong to the target context off-screen ("parking") and moving the target context's windows back to their saved frames. It consists of:

- **The contexts state** is the persisted top-level record (active context ID and ordered context IDs).
- **The context store** reads and writes that state and one JSON file per context under a caller-supplied root directory, serializing writes with a file lock. It also declares its own error type.
- **The contexts settings** are user-facing settings persisted by the host, together with the reconcile-behavior set of values.
- **The reconcile models** are value types — a reconcile item and a reconcile candidate — that a reconcile view lists after relaunch.
- **The context error** is the manager's error type.
- **The context manager** is the engine, confined to a single coordination context, that owns the contexts, parks and restores windows through an injected window-control contract, re-matches dormant window snapshots by fingerprint through the window matcher, manages custom heuristic rules through a custom-heuristic store, and persists after every mutation.
- **The contexts model** is an observable wrapper around the manager for a reactive UI layer: it turns thrown errors into a `lastError` string, drives launch reconciliation, receives window-lifecycle events as the window observer's delegate, and persists settings. It also declares the contexts configuration, the host's injected branding and defaults.

The data types these operate on — a window context and a window snapshot — the window matcher (whose auto-assign threshold is `80`), and the window-control contract live outside this slice and are referenced by role. A window is **live** when its snapshot's `windowID` is present and **dormant** when it is absent; a dormant snapshot keeps its fingerprint so it can be re-attached. Use this ingredient when an app needs persistent, switchable groups of third-party windows that survive the app quitting, the owning apps quitting, and a reboot that recycles window IDs.

