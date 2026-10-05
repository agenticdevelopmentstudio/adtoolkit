
**Decision**: Draw the popup fully borderless instead of the platform's
default bezeled popup control (AppKit/UIKit source: `isBordered = false`).
**Rationale**: Per the source's own comment, "System Settings draws a
popup inside a card without a bezel: the current value in secondary text
with the chevron pair after it. The card is the surface, so a second one
around the control just boxes a box."
**Approved**: pending

**Decision**: Pin the popup's horizontal content-hugging priority high
(AppKit/UIKit source: `.defaultHigh`).
**Rationale**: Keeps the popup sized to its content so the row's flexible
spacer, not the popup, absorbs the row's leftover width — the same
spacer-absorbs-slack layout the checkbox row relies on, made explicit here
because a borderless popup control's default hugging behavior is not
guaranteed to match a bordered one's.
**Approved**: pending

**Decision**: Link the popup's accessibility title to the label rather
than setting a separate accessibility label string (AppKit/UIKit source:
`setAccessibilityTitleUIElement`).
**Rationale**: Per the source's own comment, "the visible title label
sits beside the popup but AppKit doesn't associate them, so a screen
reader would announce the popup with no name."
**Approved**: pending

**Decision**: Silently ignore a selected item whose associated value
fails to resolve to the declared value type (**ignores-unresolvable-selection**).
**Rationale**: `guard let value = sender.selectedItem?.representedObject
as? Value else { return }` in `popupChanged(_:)` (AppKit/UIKit source) is
the only handling in source; this documents the actual, traceable behavior
rather than assuming an error-reporting path exists.
**Approved**: pending

**Decision**: Leave a view model value that matches no choice's value
uncorrected (**leaves-unmatched-selection**).
**Rationale**: `firstIndex(where:)` returning `nil` (AppKit/UIKit source,
in `syncSelection`) skips the `selectItem(at:)` call entirely; the source
neither clears the selection nor forces a default item, so the popup
keeps whatever item it selected by default — this documents the observed
behavior, not an idealized fallback.
**Approved**: pending

**Decision**: Unconditionally overwrite the view model's change-notification
callback with the component's own sync handler at construction, rather
than composing with any handler already registered on that view model
(**replaces-onchange-handler**).
**Rationale**: `viewModel.onChange = { [weak self] _ in
self?.syncSelection() }` (AppKit/UIKit source) is plain closure-property
assignment; the source has no list- or token-based observer mechanism to
compose with instead, so a second observer of the same view model silently
loses its handler. Recorded here as an explicit, approved trade-off rather
than left as an undocumented trap in edge-case prose.
**Approved**: pending

**Decision**: Force a construction failure from both out-of-band
initialization paths, leaving the view-model-taking initializer as the
only usable one (AppKit/UIKit source: `init(coder:)` and the frame-only
`init(frame:)` both trigger a fatal error).
**Rationale**: The view has no meaningful default state — it cannot
render a title, a choice list, or a value without a view model — so both
inherited initializers that could construct it without one are
intentionally disabled rather than left to produce a half-configured row.
**Approved**: pending

**Decision**: The component performs no contrast check of its own: the label's primary-text color (dimmed to a fixed 40% opacity when the row is disabled) resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
**Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
**Approved**: pending

