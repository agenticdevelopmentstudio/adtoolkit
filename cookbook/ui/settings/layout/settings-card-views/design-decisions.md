
**Decision**: (Swift) The card is declared with no access modifier
(internal), while the group container, card row, and divider are given
public access.
**Rationale**: The source's own doc comment states it directly:
"Internal: `SettingsGroup` is the way to draw one. A card without the
caption above it is half a group, and the two were published together
only because they were written together." The card is an implementation
detail of the group, not a sanctioned standalone entry point.
**Approved**: pending

**Decision**: (SwiftUI / AppKit) The card clips its content with a
continuous ("squircle") corner curve, while the AppKit sibling's
equivalent card sets a layer corner radius using that framework's default
(circular) corner curve.
**Rationale**: Not explained in source comments. Both land on the same
10pt radius from the shared layout metrics, but the two curve styles are
not pixel-identical — a real, minor divergence between the two render
paths the file's own comment says exist "so a panel written either way
lands on the same grid."
**Approved**: pending

**Decision**: The group container's caption reuses the sibling header
component's exact role assignment (secondary-text color, caption text
role) rather than defining its own style.
**Rationale**: The source doc comment frames this vocabulary as the
declarative-framework half of the same panel vocabulary the sibling
native component draws, reading the same layout metrics so a panel lands
on the same grid regardless of which framework composed it. The
heading-trait accessibility question this raises is already tracked in
the sibling header component's recipe and is deliberately not re-raised
here (see Accessibility).
**Approved**: pending

**Decision**: Title and placeholder are passed straight through to their
respective rendered text with no automatic localization.
**Rationale**: Not explained in source comments. Producing an
already-localized string is the caller's responsibility before either
parameter is reached (see the SwiftUI Platform Note for how the source
avoids automatic-localization resolution).
**Approved**: pending

**Decision**: The card divider's contrast against the elevated surface is whatever the theme's divider role resolves to; the vocabulary performs no contrast check, and the divider role has no minimum-contrast floor.
**Rationale**: Checked `SettingsCardViews.swift`: `SettingsCardDivider` draws `theme.divider` at the divider thickness with a leading inset and nothing measures the result. Closing the gap would take a floor on the divider role's derivation or a per-theme measurement of divider-to-surface ratio, or a decision that the divider is decorative and exempt from the 3:1 guidance.
**Approved**: pending

