
**Decision**: A pane's four host-facing controls — close, minimize, zoom, restore — send requests rather than performing actions directly.
**Rationale**: The source's own doc comment states the host is free to refuse, substitute, or do something else entirely with the same click, and the pane changes its own state only when the host calls `setMinimized(to:)` / `setZoomed(_:)` back — this is what lets the same class be dropped into a container with different rules and still be correct. (AppKit/UIKit.)
**Approved**: pending

**Decision**: `clampsToContainer` only ever yields the title bar's width demand; it never restores it once set.
**Rationale**: The setter's `didSet` guards on `false` and does nothing there; the doc comment explains a pane does not stop being clamped once it starts, and that restoring would mean tracking a priority per view for a case that never happens. (AppKit/UIKit.)
**Approved**: pending

**Decision**: Resetting the spacing override deletes the stored row rather than writing the current inherited value into it.
**Rationale**: `PaneSpacingOverride.reset()`'s own comment states that overwriting with today's global would freeze it, so a later app-wide change would no longer reach the pane; deletion is what keeps "use default" meaning "inherit" rather than "freeze." (AppKit/UIKit.)
**Approved**: pending

**Decision**: Spacing-override writes are coalesced behind a 300ms timer instead of writing on every tick of a drag.
**Rationale**: The spacing steppers are continuous and produce roughly seventeen values a second; the source's comment traces the uncoalesced cost to a JSON encode plus a synchronous SQLite write on the main thread per tick, and accepts a lag no longer than the pause between two deliberate presses. (AppKit/UIKit.)
**Approved**: pending

**Decision**: `setMinimized(to:)` called before the view loads only records the edge; it does not force the view to load.
**Rationale**: The source's comment on `applyMinimizedAppearance()` explains that forcing a load would re-enter through `viewDidLoad`'s call to `restorePersistedState()`, building a second, untracked rail. Recording the edge now and applying it once at load time is lossless, because the edge and the store are already written by the time this method is called. (AppKit/UIKit.)
**Approved**: pending

**Decision**: A `JSONEncoder`/`JSONDecoder` failure while persisting or reading the spacing override (`spacing-decode-failure-is-absent`) is silently ignored rather than surfaced to any caller.
**Rationale**: The state store's two methods, `setPaneStateValue(_:forKey:)` and `paneStateValue(forKey:)`, return no error value at all, so this class has no channel to report through even if it wanted to; failing open — treating unreadable or unwritable state as absent — keeps the pane opening whole rather than blocking on state it cannot use. (AppKit/UIKit.)
**Approved**: pending

