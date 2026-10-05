
**Decision**: Reuse the shared title-split logic for the lead/accent split rather than re-deriving it.
**Rationale**: dry — the brand split has one authoritative representation (shared with the
landing hero and the concept graph), so the wordmark can never drift from the rest of the
brand system. Applies to the web implementation, where the split logic is `splitSiteTitle`.
**Approved**: pending

**Decision**: Place the component in the site family's own vocabulary package rather than a
generic toolkit package.
**Rationale**: separation-of-concerns — it resolves the ADH site registry to produce the
brand string, and the boundary is mechanism → the generic packages, vocabulary →
the site family's own package; a registry-bound component in a generic UI or theme
package would make a generic package depend on one consumer's site list. On the web
this means `@agentic-toolkit/adh` rather than `@agenticdevelopertoolkit/ui` or
`@agenticdevelopertoolkit/themes`.
**Approved**: pending

*History*: two namespaces ago this component sat in `@adh-shared/adh` for a Tailwind
reason — marketing apps `@source`d the `adh` package but not `ui`, so a ui-package
wordmark rendered unstyled. That reason has since expired: those apps `@source`
`@agentic-toolkit/adh` too, and `@agenticdevelopertoolkit/ui` self-registers its own
sources. The vocabulary rule above is what governs now.

**Decision**: Ship on its own importable entry point, importing only the pure registry.
**Rationale**: separation-of-concerns — keeps the marketing landing page's heavy
concepts/content-prose graph out of a consumer's bundle when only the wordmark is
needed. On the web this is a dedicated subpath export.
**Approved**: pending

**Decision**: The tagline distinguishes "not provided" from "explicitly cleared".
**Rationale**: explicit-over-implicit — "use the default" and "omit entirely"
are different intents and get different values. On the web this is a `ReactNode`
prop with `undefined` vs. `null` distinguished.
**Approved**: pending

**Decision**: Colors come from the active theme only; the component performs no contrast check of its own.
**Rationale**: The wordmark and tagline resolve gold, primary-text and dimmed-text roles against whatever background hosts them, so whether a given theme's resolved pair meets 4.5:1 cannot be known here; closing the gap takes a theme-level contrast audit of those roles against the backgrounds they sit on.
**Approved**: pending

