
- **Role/trait**: The control exposes itself to the screen reader as one
  group rather than as four or two loose fields, depending on `style`,
  belonging to nothing. Every field, stepper, arrow button, reset button,
  and drag handle also carries a test identifier (e.g. `spacing.top`,
  `spacing.edge.top.more`, `spacing.gutter.betweenColumns.narrower.handle`)
  — these are UI-test identifiers, not screen-reader labels.
- **Label requirements**: The four or two number fields and their steppers
  carry no accessibility label anywhere in source — only a numeric value
  and a test identifier — so a screen-reader user landing on one hears its
  number with no indication of which edge or gutter it belongs to. The
  arrow buttons are not part of this gap: each carries an accessibility
  description that is the same string as its tooltip (e.g. "More top
  space"), which the screen reader reads as the button's label. This
  mirrors the same control-to-title linkage gap already noted on the
  sibling ingredient
  (`adtoolkit://cookbook/ui/settings/rows/captioned-slider-view#accessibility`).
- **Announce state changes (e.g., loading, disabled)**: Not applicable — the
  component has no loading or disabled state (see States) for a change to
  announce.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition with no touch input path in source; the 44×44pt minimum is
  touch-interface guidance, not a pointer-interface requirement.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. Every color it draws for text or a tint comes from a theme role: field text (primary text), arrow glyphs (accent), the outer frame's stroke (border) against the project-pane backdrop, and each pane's stroke (project-pane outline) against the window-background role. None of these roles carries a guaranteed contrast floor in the theme model (primary text is the theme's raw foreground, accent is a raw palette slot or the raw foreground, and border blends foreground into background at a fixed 0.18 fraction, unlike the secondary text role's minimum contrast of 3.0), so whether any pair meets 4.5:1 (text) or 3:1 (non-text) depends on each theme's values.

