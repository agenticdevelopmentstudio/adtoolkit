
**Decision**: Redeclare `helpContent`, `effectiveHelpContent`,
`hostsOwnScroll`, and `searchKeywords` directly on this class instead of
relying on `ComposableSettingsPanel`'s protocol-extension defaults.
(AppKit source.)
**Rationale**: Per the source's own comment, "a protocol extension's default
is bound at the point of conformance — this class — and a subclass property
that merely shadows it is invisible through the `any ComposableSettingsPanel`
the split holds." Redeclaring these as `open` members means an overriding
subclass's value is reached through class-based dynamic dispatch instead of
being silently skipped behind the existential.
**Approved**: pending

**Decision**: Give `hostingView(for:)`'s `NSHostingView` `sizingOptions =
[.intrinsicContentSize]` instead of AppKit's `.standardBounds` default.
(AppKit source.)
**Rationale**: Per the source's own comment, `.standardBounds` "installs
required min- and max-size constraints derived from the SwiftUI content's
own sizing," and because the detail pane pins a panel to its edges, those
constraints become the settings window's own — "a panel whose content is a
stack of cards has a finite ideal height, and selecting it collapsed the
window to that height and held it there." Restricting to
`.intrinsicContentSize` keeps that sizing a hugging-priority preference
(still read by `PanelScrollView`'s document, so oversized content scrolls)
rather than a hard limit, so "panel content never sizes this window; the
window sizes the panel." (See **hosting-view-sizing-options** and the
Appearance › Min/Max size and Edge Cases › Oversized hosted content
entries, which point back here rather than repeating this rationale.)
**Approved**: pending

