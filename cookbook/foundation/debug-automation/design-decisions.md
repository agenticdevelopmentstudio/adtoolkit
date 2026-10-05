
**Decision**: The debug launch switch is a distinct reusable primitive
rather than an inline settings-store lookup at each use site.
**Rationale**: (AppKit implementation) Per the type's own doc comment, a
switch read this way lives only in the launch-argument domain, not a
written preference — so a stale `defaults write` cannot leave a developer
wondering later why the app behaves oddly — and the debug/release check is
evaluated exactly once, in this type, so no call site can forget it
(`DebugLaunchSwitch.swift`).
**Approved**: pending

**Decision**: The sink-behind-desktop operation changes only the window's
`level`, leaving ordering, key status, and visibility to the caller, rather
than hiding the window (`orderOut`, `isVisible = false`) or moving it
off-screen.
**Rationale**: (AppKit implementation) A test still has to assert
`isVisible`, the restored frame, `window.screen`, and first-responder
changes — all of which a genuinely hidden or off-screen window would fail —
while a person at the keyboard must not see it "in front of them"; dropping
the level below the desktop gives AppKit a real, laid-out, visible window
and gives the person at the keyboard nothing (`NSWindow+TestHostVisibility.swift`).
**Approved**: pending

**Decision**: The quiet order-front and quiet make-key-and-order-front
operations set the window's level *before* calling
`orderFront`/`makeKeyAndOrderFront`, rather than ordering first and sinking
afterward.
**Rationale**: (AppKit implementation) Per the doc comment, this ordering
keeps the window from ever being briefly visible at the normal level on its
way to the sunk level — a flash a person at the keyboard could otherwise
catch.
**Approved**: pending

**Decision**: The quiet presentation gate's enabled state is the OR of two
independent signals — test-host detection and the debug-only switch's
enabled state — rather than a single flag, and the resolve step exists as a
separate function taking both as parameters.
**Rationale**: The doc comment states both are "the same situation twice":
a test host must always stay quiet, with no launch argument required, while
an automated debug session needs the argument because it is not itself a
test-framework process. Exposing the resolve step with both inputs as
parameters makes both branches independently testable — under the test
framework itself, the gate's enabled state would otherwise always
short-circuit to `true` and the debug-only branch could never be exercised
(`QuietWindowPresentation.swift`).
**Approved**: pending

**Decision**: The conditional activation operation generalizes to
application activation the same suppression that window-ordering already
established, as one shared gate rather than a bare unconditional activation
call repeated at each call site.
**Rationale**: (AppKit implementation) The doc comment records that eleven
call sites previously called `activate(ignoringOtherApps:)` directly, so
the quiet flag was honored by whichever of them happened to remember it and
ignored by the rest; centralizing the check in one extension method removes
that per-call-site inconsistency (`NSApplication+QuietActivation.swift`).
**Approved**: pending

