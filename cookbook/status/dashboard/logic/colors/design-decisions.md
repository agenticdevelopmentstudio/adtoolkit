
**Decision**: Every color is a theme-token reference, never a hard-coded hex value.
**Rationale**: The authoring comment states the board "tracks the same theme as the rest of the suite" and that shade changes against the old bespoke values are intentional; ownership of values stays with `@agenticdevelopertoolkit/themes`.
**Approved**: pending

**Decision**: Alpha is applied with `color-mix(in srgb, <token> N%, transparent)` rather than `rgba()`.
**Rationale**: A `var()` token cannot take an alpha channel directly, and the comment names `color-mix` as "the form the UI checker accepts"; the percentages mirror the old `rgba` opacities.
**Approved**: pending

**Decision**: `DEPLOY_COLORS.unknown` is muted text, while `unknown` in the health and overall tables is amber.
**Rationale**: For deploys, `unknown` is an expired, unconfirmable in-flight phase, "an ABSENCE of a verdict, muted (never the amber of live progress)", matching `row-model`'s `stale` tone. The health and overall tables keep `unknown` at caution.
**Approved**: pending

**Decision**: Environment colors use the categorical `apt-cat-*` hues.
**Rationale**: They must read as "which env", never as a health signal, and must not collide with the platform badges, which use other `apt-cat-*` hues.
**Approved**: pending

**Decision**: Surface steps finer than the theme's three levels collapse onto the nearest token (`surfacePane` and `surfaceHover` share `surface-2`).
**Rationale**: The monitor had finer steps than the theme exposes; collapsing keeps every value theme-owned at the cost of a visible hover step.
**Approved**: pending

**Decision**: Only amber has a bright headline variant (`amberLight`).
**Rationale**: The theme exposes `gold-bright` but no bright green or red, so green and red headlines use `PALETTE.green` / `PALETTE.red` directly with "no redundant same-value alias".
**Approved**: pending

**Decision**: Env badge labels are four upper-case characters for known envs; unknown envs are upper-cased but not truncated.
**Rationale**: Four characters keep the env column narrow; unknowns stay recognizable rather than ambiguous.
**Approved**: pending

**Decision**: Shadows and the white ghost use literal `black` / `white`.
**Rationale**: The comment calls them theme-independent.
**Approved**: pending

