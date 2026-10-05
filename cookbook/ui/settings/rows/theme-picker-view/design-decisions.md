
**Decision**: Refresh the preview only through the palette-observing
subscription's notification callbacks, never by calling into the preview
directly from the choice control's selection handler. (AppKit source.)
**Rationale**: source contains no direct call from the control to the
preview at all; the two are wired to the same app-wide active-theme
setting and theme-manager notification independently, which is what lets
the preview also react to a theme change made from somewhere else
entirely (a different settings panel, a synced change) without this
component needing to know about it.
**Approved**: pending

**Decision**: Keep the choice control, the preview, and the observer all
`private` (AppKit: Swift access control), unlike sibling rows
(`PopupMenuChoiceView`, `FontPickerView`) that expose their constituent
views publicly. (AppKit source.)
**Rationale**: source declares all three with `private` access and
provides no public accessor for any of them; this recipe documents that
as the actual, current visibility rather than assuming parity with its
siblings.
**Approved**: pending

**Decision**: Default the theme store to the app's persisted store — the
convenience initializer that persists through the shared settings store —
rather than requiring a caller to supply one. (AppKit source.)
**Rationale**: per the persisted store's own comment, "every existing
default-store call site keeps working, and keeps reading the themes
already on disk" — the default is the same persisted store every other
default call site in the app already uses.
**Approved**: pending

