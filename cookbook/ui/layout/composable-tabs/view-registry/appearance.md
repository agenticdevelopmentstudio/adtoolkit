
- **Corner radius**: None. The placeholder's container has no corner
  radius set.
- **Padding**: Not applicable. The title label is positioned by centering
  against the container, not by an edge inset.
- **Font**: Determined by the theme, not this file: the title uses a
  heading text role, so its resolved font (family, size, weight) is
  whatever the active theme returns for that role. The label component
  that resolves theme fonts has its own recipe; this component only
  selects the heading role.
- **Background**: The container's background is tinted using the active
  theme's chart-series color list, indexed by (pane number − 1) modulo the
  list's count, at 15% opacity, when the list is non-empty (per
  **placeholder-series-tint**); otherwise the background is left at its
  default (unset/transparent).
- **Foreground/Text**: The title's text color resolves to the active
  theme's primary-text role.
- **Border**: None. No border width or color is set on the container or
  the title.
- **Shadow**: None. No shadow is set on the container.
- **Min/Max size**: The container is created with an initial frame of
  300×200 points; this is only the view's starting size — it is actually
  sized by the pane layout that hosts it (outside this file). Separately,
  the placeholder descriptor's minimum thickness is the default 120
  points, since the placeholder descriptor supplies only a display name.

