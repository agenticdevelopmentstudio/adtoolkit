
**Decision**: One module owns the full platform taxonomy (glyph, color, label, short label).
**Rationale**: The header comment says "adding a platform is a single edit here", so every component renders platforms consistently and no component keeps its own table.
**Approved**: pending

**Decision**: Platform colors use categorical theme hues kept clear of the three environment hues.
**Rationale**: A row can show both an env badge and a platform badge. Sharing a hue would make one read as the other. The categorical palette is fully allocated, so `crunchy` reuses `http`'s teal and `glitchtip` reuses Cloudflare's orange.
**Approved**: pending

**Decision**: `glitchtip` takes orange rather than another reused hue.
**Rationale**: The source comment says orange is the hue that reads as a warning. Glitchtip rows (error incidents) and Cloudflare rows (deploys) never appear in the same list, so the glyph and label disambiguate them.
**Approved**: pending

**Decision**: The glitchtip glyph carries VARIATION SELECTOR-15. (Apple platforms — macOS and iOS.)
**Rationale**: Without it, macOS and iOS render U+26A0 as a full-colour, double-width emoji beside six monochrome glyphs.
**Approved**: pending

**Decision**: `unknown` status is labelled `outcome unknown` and colored muted.
**Rationale**: It marks an in-flight phase the backend expired without confirmation, which is the absence of a verdict. Echoing the raw enum or using the amber of live progress would imply a claim the data cannot back.
**Approved**: pending

**Decision**: Unrecognised statuses fall back to the `canceled` color (amber), and unrecognised platforms fall back to the muted color, `◆` and the upper-cased name.
**Rationale**: The source chooses to render something for any input rather than throw. The status fallback reuses an existing entry instead of a separate token. As a result an unknown status reads amber, while the known `unknown` status reads muted.
**Approved**: pending

**Decision**: `failed` is the only upper-case status label.
**Rationale**: The source returns `FAILED` while every other label is lower case, which makes a failure stand out in a list.
**Approved**: pending

