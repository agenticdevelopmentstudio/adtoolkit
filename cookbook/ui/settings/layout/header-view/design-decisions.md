
**Decision**: (AppKit) `init(frame frameRect: NSRect)` is overridden to
unconditionally `fatalError("init(frame frameRect: NSRect")` instead of
accepting the supplied frame.
**Rationale**: Not explained in source comments. Recorded verbatim as a source quirk: the `fatalError` message string is itself malformed — it reads `init(frame frameRect: NSRect` with no closing parenthesis, unlike the coder initializer's correctly formatted message on the next line. This does not change behavior (the call still traps unconditionally); only the printed diagnostic text is affected.
**Approved**: pending

**Decision**: (AppKit/UIKit) `titleLabel` is created with
`role: .secondaryText, textRole: .caption` rather than a heading-weight
role.
**Rationale**: Not explained in source comments. Consistent with the Group View recipe's own description of this component as "a caption *outside* and above a rounded card" — a de-emphasized label naming a settings group, not a prominent section title.
**Approved**: pending

**Decision**: (AppKit/UIKit) `titleLabel` is pinned to all four edges of
the component with a zero constant on every constraint, so the component's
bounds are exactly `titleLabel`'s bounds.
**Rationale**: Not explained in source comments. The component contributes no visual chrome of its own — no background, border, or padding — so every pixel a caller sees is the label's, and any spacing around the caption is left entirely to the caller's own layout (e.g. the Group View's header-to-card spacing).
**Approved**: pending

**Decision**: The header title's contrast is whatever the theme's secondary-text role resolves to; the view performs no contrast check, and the theme guarantees only a 3.0 floor against WCAG AA's 4.5:1 for 11pt text.
**Rationale**: Checked `HeaderView.swift`: its title is a `ThemedLabel` created with the `.secondaryText` role and `.caption` text role, and nothing in the view measures or raises contrast. Closing the gap would take a 4.5:1 floor in the secondary-text derivation or a per-theme audit of the running UI.
**Approved**: pending

