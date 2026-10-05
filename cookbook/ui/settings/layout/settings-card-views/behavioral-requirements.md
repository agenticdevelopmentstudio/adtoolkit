
- **group-caption**: The group container MUST render its title, styled
  with the caption text role and the secondary-text foreground color,
  above the card, when a title is given.
- **group-omits-caption-when-title-absent**: The group container MUST NOT
  render any caption when no title is given.
- **group-caption-spacing**: The group container MUST separate its
  caption, when rendered, from the card beneath it by the standard
  caption-spacing value (6pt).
- **group-stretches-full-width**: The group container MUST stretch to the
  full width offered by its container, leading-aligned.
- **group-title-not-auto-localized**: The group container MUST NOT
  localize its title automatically; it MUST render the title exactly as
  the caller supplied it, with no lookup against a string catalog.
- **card-fills-rounded-elevated-surface**: The card MUST paint its
  content's background with the elevated-surface theme color, clipped to
  a continuous corner radius of the standard card-corner-radius value
  (10pt).
- **card-stretches-full-width**: The card MUST stretch its content to the
  full width offered by its container, leading-aligned.
- **card-row-insets-content**: A card row MUST inset its content by the
  standard card-horizontal-inset value (14pt) horizontally and the
  standard card-vertical-inset value (9pt) vertically.
- **card-row-stretches-full-width**: A card row MUST stretch its content
  to the full width offered by its container, leading-aligned.
- **divider-renders-hairline**: The divider MUST render a horizontal
  hairline exactly the standard divider-thickness value (1pt) tall, filled
  with the divider theme color, filling the width offered by its
  container.
- **divider-insets-from-leading-edge**: The divider MUST inset its
  hairline from the leading edge by the standard card-horizontal-inset
  value (14pt), with no trailing inset.
- **panel-inset-pads-uniformly**: The panel-inset operation MUST apply the
  standard panel-inset value (20pt) of padding uniformly on all four edges
  of the view it is applied to.
- **search-field-wraps-native-control**: The search field MUST render its
  text-entry surface using a genuine native search-field control, not a
  custom-drawn substitute.
- **search-field-filters-live**: The search field MUST be configured so a
  keystroke triggers the search action immediately, rather than waiting
  for a submit action.
- **search-field-writes-through-binding**: The search field MUST write
  its current text to the caller-supplied text value whenever its search
  action fires.
- **search-field-avoids-cursor-jump**: The search field MUST reassign its
  underlying text only when it differs from the caller-supplied text
  value, so reassigning an unchanged value does not move the insertion
  point.
- **search-field-sizes-to-fitting-height**: The search field MUST report
  the wrapped native control's own natural height as its height, and the
  proposed width when one is offered, falling back to the control's own
  natural width otherwise.
- **search-field-placeholder-not-auto-localized**: The search field MUST
  render its placeholder text exactly as the caller supplied it, with no
  automatic localization applied.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

