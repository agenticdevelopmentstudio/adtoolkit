
**Decision**: The layout-change notification handler refreshes this pane's arrange-overlay availability for every tab's layout change, not only its own window's.
**Rationale**: One pane moving changes what every other pane in every open tab may legally do next (a column's last pane loses Up, a tab's last leaf loses Remove), and the source posts one unscoped notification for exactly this reason rather than one per window.
**Approved**: pending

**Decision**: Removing a pane behind a confirmation sheet re-resolves the enclosing split inside the sheet's completion handler instead of capturing the split reference before presenting the sheet.
**Rationale**: The tree can change while the sheet is up — another pane could be moved or removed — so acting on a reference captured before the sheet opened risks removing the wrong leaf or acting on one that already left the tree.
**Approved**: pending

**Decision**: Arrow-key handling for arrange mode is implemented as a local `NSEvent` monitor per pane rather than an override of `keyDown(_:)`.
**Rationale**: (AppKit) The pane's own content (a terminal, an editor) owns first responder and would consume the arrow key before a `keyDown` override on this controller ever saw it; a local monitor sees the event before AppKit's responder chain delivers it.
**Approved**: pending

**Decision**: The active/inactive pane cue is color-only; border width stays a constant 2pt in both states.
**Rationale**: The source's own comment states the intent — outlining only the active pane would read as one pane with a seam down the middle — but implements no additional cue (width, icon, or pattern) for a person who cannot rely on color alone; see Differentiate Without Color in Accessibility Options.
**Approved**: pending

