
**Decision**: Fill the table with the `.windowBackground` theme role rather
than `.surface`.
**Rationale**: source comments state the log should read as the full
content of its own window or pane, rather than as a sidebar, matching how a
related timeline's table is themed — so it blends into the backdrop instead
of reading as its own plane.
**Approved**: pending.

**Decision**: Turn off alternating row background colors and rely on a
horizontal-only grid line for row separation instead of banding.
**Rationale**: source comments state banding comes from a system color pair
the theme has no say in, and that without any row separator the log read as
an unbroken block of text with no row boundaries at all — the horizontal
grid line is the theme-controlled substitute.
**Approved**: pending.

**Decision**: Capture `provider.columns` once, at `init(provider:)`, and
never rebuild the table's column set afterward.
**Rationale**: the provider's own documentation states columns are expected
to be stable for the lifetime of the provider and that this component
captures them at init time; later column changes are out of contract.
**Approved**: pending.

**Decision**: Compute the scroll-position check before calling reload on an
appended change, rather than after.
**Rationale**: the tail-follow decision needs the scroll position as it was
before new rows were inserted — checking after the reload would measure
geometry that already includes the newly appended rows, which would always
read as "not at bottom" whenever new content is what pushed the content
taller than the viewport.
**Approved**: pending.

**Decision**: Return a newly constructed row view on every delegate
callback instead of reusing a dequeued instance by identifier.
**Rationale**: source comments state each row needs to own its own theme
observer, since a selection fill baked in at creation would draw stale after
a theme change if the instance were pooled and reused across it; AppKit
still recycles the row views this method returns internally regardless of
whether the caller dequeues them itself. This is the mechanism behind
`selection-fill-reflects-current-theme`.
**Approved**: pending.

**Decision**: Request cell views through `makeView(withIdentifier:owner:)`
with a per-column reuse identifier (`cell.<columnID>`), rather than always
constructing a new `ThemedLabel` for every rendered row.
**Rationale**: source code routes every cell request through AppKit's own
view-reuse pool keyed by that identifier, so a cached view is served back
when one is available; this is the mechanism behind
`cell-request-uses-column-reuse-identifier`.
**Approved**: pending.

**Decision**: Route click hooks only through the table's own click/double-click
actions, and expose the click-dispatch method publicly.
**Rationale**: source comments state this lets tests (and callers doing
programmatic dispatch) drive the same entry point AppKit uses, without
needing to synthesize real mouse events. This is why
`public-dispatch-applies-same-guards` is stated as a MUST rather than left
as an API-visibility note.
**Approved**: pending.

