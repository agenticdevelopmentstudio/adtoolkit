
- **Corner radius**: Not applicable — no rounding is configured on this
  component itself; any rounded panel chrome belongs to the hosting
  window, not this component.
- **Padding**: See **title-label-position**, **search-field-position**, and
  **table-scroll-position** for exact values — 12pt root-edge insets
  throughout, and 8pt between the search field's bottom and the table
  scroll container's top.
- **Font**: The title label uses the primary-text color role with a
  heading text role; each item row's title label uses the primary-text
  color role with a body text role; each item row's description label
  uses the secondary-text color role with a caption text role; each item
  row's detail label and the separator row's label both use the
  tertiary-text color role with a caption text role. The active theme
  resolves the actual point size and weight for each role at draw time, so
  no literal point size or font weight is hardcoded anywhere in this
  component.
- **Background**: The table's scroll container draws a background, and the
  table paints the active theme's surface color as its own background,
  repainting live on a theme change; no explicit background color is set
  on the root view or on either the search field or the table beyond that.
- **Foreground/Text**: Every label's text color follows its color role
  (primary, secondary, or tertiary text), resolved by the active theme; no
  literal color value appears anywhere in this component.
- **Border**: The table's scroll container suppresses its default border
  explicitly; no other border is configured on any view in this component.
- **Shadow**: Not applicable — no shadow is configured anywhere in this
  component.
- **Min/Max size**: The preferred content size is fixed at 560×400 points
  with no separate min/max constraint; each row's height is fixed at
  24pt.

