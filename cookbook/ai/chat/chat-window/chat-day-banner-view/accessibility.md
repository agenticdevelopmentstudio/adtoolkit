
- **Role**: A role equivalent to static text, set on the container view itself (see **static-text-role**; see Platform Notes for the concrete API).
- **Label**: The date label's accessibility label is explicitly set to its own rendered text (see **label-accessibility-label**); the underlying label control would already expose that text by default, so this call is redundant but present in source. The label is never removed from the accessibility tree, so alongside the container's own static-text role and label, assistive technology may expose the label as a second element rather than treating the banner as one merged announcement; the source does not resolve which happens (see Compliance).
- **Identifier**: The label carries the accessibility identifier `chat-day-banner` (see **label-accessibility-identifier**), for UI-test targeting rather than for assistive technology.
- **Announce state changes**: Not applicable — the banner has no state that changes after construction other than its colors on theme change (see **theme-responsive-styling**), and a color-only change is not announced through any accessibility notification in the source.
- **Minimum tap target**: Not applicable — this is a non-interactive display element with no tap or click target.

