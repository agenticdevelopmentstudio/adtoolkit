
**Decision**: (AppKit) `init(frame:)` is a fully working initializer (it calls
`show(nil, title: "System")` and configures the button), rather than the
`fatalError` trap that sibling row views in this directory carry on their
frame-only initializer.
**Rationale**: Per the source's own doc comment, `FontChooserButton()` is a
spelling Swift resolves to `NSObject.init()`, which AppKit funnels through
`initWithFrame:` — trapping there would crash a call site that looks like
it is using the initializer above (`init(width:)`), rather than a
deliberately-avoided one.
**Approved**: pending

**Decision**: The component records the last font it was shown
(`selectedFont`) but never writes it anywhere persistent; the caller is
solely responsible for storage.
**Rationale**: Per the source's own doc comment: the caller "records the
picked font wherever that font belongs and calls `show(_:title:)` back
with what it actually recorded" — `explicit-over-implicit`: the button
always displays exactly what its owner tells it to, including a clamped
size or an edit a locked theme refused outright.
**Approved**: pending

**Decision**: (AppKit) `validModesForFontPanel(_:)` restricts the font panel to
`.collection`, `.face`, and `.size`, excluding color and text-effect modes.
**Rationale**: Per the source's own comment: "Only the parts of the panel
that pick a font — the color and underline effects would write nothing
anyone reads back."
**Approved**: pending

**Decision**: (AppKit) `viewDidMoveToWindow()` clears `NSFontManager.shared.target`
when the button leaves its window and still owns that target.
**Rationale**: `NSFontManager.target` is `unowned(unsafe)` (confirmed by
the component's own test suite comment); leaving it pointing at a
since-freed button would have the shared font manager write into freed
memory rather than fail safely. This is a workaround for that unsafe
AppKit API, not a feature of the component's own design.
**Approved**: pending

**Decision**: (AppKit) The component accepts the residual risk that
`NSFontManager.shared.target` can be left pointing at freed memory if a
`FontChooserButton` is deallocated together with its entire window (rather
than first removed from it): `viewDidMoveToWindow()` (see
**releases-picker-registration-on-removal**) is the only target-release
guard in source, and it runs only when the view is individually removed
from its window, not on `deinit`.
**Rationale**: `NSFontManager.target` is declared `unowned(unsafe)`, so
nothing in AppKit enforces a cleanup call at deallocation time, and source
adds no `deinit` override of its own. Recording the gap here keeps the
recipe honest about the edge `viewDidMoveToWindow()` does not cover,
rather than implying it is a complete guarantee.
**Approved**: pending

**Decision**: The built-in `"System"` initial title stays a hardcoded
literal rather than moving to a `String(localized:)` key.
**Rationale**: Every title the button shows after construction is
caller-supplied and therefore the caller's own localization
responsibility; only the one built-in `"System"` literal set by
`init(frame:)` is this component's own, and it is the only string in this
file left unlocalized (see Localization).
**Approved**: pending

