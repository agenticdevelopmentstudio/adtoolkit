
**Decision**: The chooser is presented as an app-modal `NSWindow`
(`NSApp.runModal(for:)`) rather than as a sheet.
**Rationale**: Per the source's own doc comment, "this app has no window
guaranteed to be on screen when the question is asked (it can be asked from
the menu bar with nothing open at all), and a sheet with no parent cannot
be dismissed" (`ProjectChooserWindow.swift`).
**Approved**: pending

**Decision**: `windowWillClose(_:)` only calls `finish(with: nil)` when
`NSApp.modalWindow === window`, rather than unconditionally on every close
notification.
**Rationale**: The inline comment states the reason directly — the check
exists to "only end a session we are in," so a close notification for a
window that is not the currently active modal session does not tear down a
different, still-running modal session by calling `NSApp.stopModal()` on
its behalf (`ProjectChooserWindow.swift`).
**Approved**: pending

**Decision**: The title bar close control and ⌘W are routed through
`windowWillClose(_:)` to the same `finish(with:)` path as Cancel, rather
than being left to AppKit's default close behavior.
**Rationale**: The inline comment explains what breaks otherwise: "the
title bar's close button and ⌘W bypass Cancel and Open, so the session has
to be ended from the close notification too," because without it "the
modal session outlives its window" and AppKit keeps disabling Quit, About,
Settings, and every status-item command for the rest of the run
(`ProjectChooserWindow.swift`).
**Approved**: pending

**Decision**: Cancel and Open are built as stock `NSButton`s with
`bezelStyle: .push`, rather than a custom-drawn control pair.
**Rationale**: The inline comment states this is deliberate: "this is the
Open dialog of a Mac app: the pair at the bottom right is a shape people
have known for thirty years, and a hand-drawn substitute is a worse version
of it" (`ProjectChooserWindow.swift`), consistent with the
`native-controls-preference` compliance check below.
**Approved**: pending

**Decision**: The browser and the Cancel/Open pair are split into a
separate `ProjectChooserContentViewController` rather than being assembled
directly inside `ProjectChooserWindow`.
**Rationale**: The inline comment gives the reason: splitting it out gives
"the browser a real parent view controller" so it "gets its appearance
callbacks," which is where the browser's own `viewDidAppear` takes first
responder for its filter field (`ProjectChooserWindow.swift`).
**Approved**: pending

