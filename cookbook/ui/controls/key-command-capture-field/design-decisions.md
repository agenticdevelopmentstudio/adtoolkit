
**Decision**: Draw a bespoke view and read raw key events directly, instead
of using a standard text field.
**Rationale**: A field editor would eat the very chords being recorded, and
a standard text field's own key handling turns a primary-modifier chord
into an edit command. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Override the pre-dispatch key-handling hook
(`performKeyEquivalent(with:)`) in addition to the regular key-handling
hook (`keyDown(with:)`).
**Rationale**: A primary-modifier chord never reaches the regular
key-handling hook because the platform offers it down the key-equivalent
chain first (a menu item, the window), which would otherwise claim it;
this override is what makes the recorder work for primary-modifier
combinations at all. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: Let bare Tab and Shift-Tab pass through uncaptured while
Option-Tab/Control-Tab remain capturable.
**Rationale**: A recorder that swallowed either bare form would trap
anyone who arrived at the field by tabbing through the panel, while a
modifier-carrying Tab combination is still a legitimate chord to record.
(Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: The manual recording-stop operation forces `isRecording` to
`false` unconditionally, not only through the focus-loss path losing focus
takes.
**Rationale**: This is what the hosting row calls once an edit is
committed or abandoned, to stop recording without depending on the
focus-change notification path — necessary because the row, not the
field, owns commit, and may need to end recording from code that does not
itself trigger a focus change. (Applies to the AppKit implementation.)
**Approved**: pending

**Decision**: While recording, do not switch the label to "Press keys…" if
a shortcut is already being displayed or pending; only fall back to
"Press keys…" when neither is set.
**Rationale**: The text-refresh routine resolves text from a single
precedence chain (`pendingShortcut ?? displayedShortcut`, else "Press
keys…" or `placeholder`) with no separate "just started recording" branch.
This is called out because a reader could otherwise assume "Press keys…"
always appears the instant recording starts. (Applies to the AppKit
implementation.)
**Approved**: pending

**Decision**: The field performs no contrast check: background, border, accent and text colors are the active theme's palette roles as resolved.
**Rationale**: No source path measures contrast, and the actual values live in each shipped theme outside this component. Closing the gap means auditing each shipped theme's resolved values for these role pairings against a chosen accessibility bar, or adding a contrast floor to the palette resolution the field consumes.
**Approved**: pending

