
**Decision**: Treat the `SwatchGridView` being excluded from the
`cards.map { widthAnchor... }` width stretch as a documented source quirk,
not a defect this recipe silently corrects. (AppKit source.)
**Rationale**: `show(_:)` builds the width-stretch constraints only from the
`cards` array of five sample boxes; the `SwatchGridView` appended afterward
is never included in that array or its `.map`. The recipe describes this
exactly as source does, in Edge Cases, rather than assuming the intended
behavior was to stretch every appended view.
**Approved**: pending

**Decision**: Document that the status sample's badge capsule is a private,
structurally similar re-implementation of the shared `Badge` ingredient — a
known DRY gap, recorded as built rather than corrected. (AppKit source.)
**Rationale**: `ThemePreviewView.swift` defines its own `private static func
badge(_:_:_:)` building a tinted capsule inline; it never references
`AgenticToolkit`'s `Badge` type. The two happen to look alike, which is
exactly the duplication a shared-components policy exists to prevent; this
recipe records that duplication as source built it rather than assuming an
unmade refactor, since composing `Badge` here is a source change this recipe
cannot make.
**Approved**: pending

**Decision**: State the missing accessibility grouping/labeling and the
missing localization as plain facts about source, not open questions,
without assuming a specific grouping, labeling, or localization strategy for
the eventual fix. (AppKit source.)
**Rationale**: `ThemePreviewView.swift` contains zero accessibility API
calls and zero localization calls of any kind, and there is no comparable
`ThemePreviewView`-family sibling recipe to pattern-match a grouping,
labeling, or localization decision against — only `SwatchGridView`, whose
own gaps (per-swatch color labels) are a different question already
documented in its own recipe, and are cross-referenced rather than repeated
here.
**Approved**: pending

