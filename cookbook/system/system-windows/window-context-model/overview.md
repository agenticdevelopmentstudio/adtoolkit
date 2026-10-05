
The core data model of the system window contexts feature: five value types that carry no behavior beyond in-memory collection edits; matching, persistence and window movement live in their consumers.

- **Match strategy** is a string-backed set of named strategies (an exact app-and-title match, an app-and-title substring match, an app-and-title regular-expression match, and an app-only match) that says how strictly a fingerprint must match a live window, plus a display name for each strategy.
- **Window fingerprint** is an immutable record (app, title pattern, match strategy, display) that identifies a window across restarts, even though its live window identifier has changed.
- **Window info** is an immutable description of one live window obtained from the system's window list (id, app, process id, title, frame, display, on-screen flag, layer), with an operation to backfill a title read through the accessibility layer.
- **Window snapshot** is a window's stable identity and saved position inside a context: a stable id (not the live window identifier), an optional live window identifier, the fingerprint, saved frame, display, app, title and last-seen timestamp, with a live flag derived from the window identifier.
- **Window context** is a named, colored group of snapshots (a logical workspace — for example, "iOS App", "Backend API", or "Docs") with add, remove, look-up and in-place update operations and a live-window count.

Consumers named for orientation: the window matcher builds fingerprints and scores live windows against them; the context manager owns the list of contexts and enforces cross-context rules; the context store persists contexts as JSON files. Use this ingredient when an app needs a serializable model for grouping another app's windows into named workspaces that survive a restart of either app or the OS.

