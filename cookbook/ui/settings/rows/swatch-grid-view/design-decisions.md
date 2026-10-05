
- **Decision**: Implement the color-replacement operation by fully
  tearing down and rebuilding the row/swatch view hierarchy — removing
  every existing arranged element before creating new rows — rather than
  reusing or diffing existing swatch views.
  **Rationale**: Source unconditionally clears the container's arranged
  elements at the start of the shared rebuild routine used by both
  construction and color replacement. The only caller-observable
  contract is that replacing the colors displays exactly the new colors
  afterward (**replaces-colors-and-rebuilds**); the full-rebuild
  strategy is how source achieves that, not itself a caller-visible
  requirement.
  **Approved**: pending
- **Decision**: Treat the swatch's border-repaints-on-theme-change /
  fill-fixed-at-creation asymmetry (see Edge Cases) as a documented quirk
  rather than a defect to silently correct in this recipe.
  **Rationale**: Source re-applies only the border color on a theme
  change; the fill assignment at swatch-creation time is a one-time
  write with no observer. The recipe describes this asymmetry as-is
  rather than assuming the fill should also be theme-reactive, since a
  data color (unlike a border) is not expected to shift with the theme.
  **Approved**: pending
- **Decision**: Leave the Role/trait accessibility bullet as an open
  question rather than assuming a specific role, and resolve the Label
  requirements bullet with a default SHOULD recommendation that review
  may override.
  **Rationale**: Source sets no accessibility API of any kind on the
  container, its rows, or its swatches, and there is no comparable
  sibling row in the same source directory that labels a color swatch
  for a screen reader to pattern-match against. Recommending a default
  label (a caller-supplied name, falling back to a hex string) keeps the
  recipe implementable without inventing a role that source doesn't
  suggest.
  **Approved**: pending
- **Decision**: The component performs no contrast check of its own: each swatch's 0.5pt border color (the theme's border role), against the 3:1 non-text threshold, resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
  **Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
  **Approved**: pending

