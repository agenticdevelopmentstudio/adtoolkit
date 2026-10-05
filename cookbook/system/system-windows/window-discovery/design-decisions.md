
**Decision**: Match on the heuristic pattern OR the raw title.
**Rationale**: The source comment says the raw-title check is kept "so existing substring matches still hold". For the built-in Xcode heuristic the pattern is a prefix of the title, so the raw-title test already covers it; the pattern only adds matches when a custom heuristic returns text not present verbatim in the title.
**Approved**: pending

**Decision**: Treat `"Unknown"` and the empty string as "no project".
**Rationale**: A session's project name returns `"Unknown"` for an empty or root working directory; matching it would flag any window whose title contains the word.
**Approved**: pending

**Decision**: Include minimized and off-screen windows.
**Rationale**: The type's doc comment says the panel lists them "so the user can bring any of them back"; the engine's focus moves a parked window back on-screen.
**Approved**: pending

**Decision**: Keep the panel open when focus fails, reporting only via the log.
**Rationale**: The activation doc comment: "on failure it logs and leaves the panel open so the user can retry or pick another window, rather than silently closing as if it worked."
**Approved**: pending

**Decision**: (Apple platforms) Snapshot running apps on the calling thread, enumerate windows in the background.
**Rationale**: The source comment names `NSWorkspace`/`NSRunningApplication` as main-thread APIs; the window list and Accessibility backfill can be slow, so they run off the main thread.
**Approved**: pending

**Decision**: Overlapping discovery calls publish in completion order, not start order.
**Rationale**: It stands today because no generation token exists. Closing it needs an owner decision that the latest call must win, and a test with overlapping calls.
**Approved**: pending

