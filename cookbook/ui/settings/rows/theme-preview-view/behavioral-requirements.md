
- **container-pinning**: Component MUST maintain a single vertical
  container (leading-aligned, 10pt spacing) as its only direct content
  holder, pinned to all four of its own edges with no additional constant.
- **empty-initial-state**: Component MUST NOT add any content to that
  container, and MUST NOT paint its own background, when constructed with
  no theme supplied; content and the background paint appear only once the
  show operation is called.
- **show-teardown-and-rebuild**: On every call to the show operation, the
  component MUST remove every existing sample from its container before
  adding the new set of sample cards, rather than diffing or reusing any
  existing card.
- **self-background-paint**: On every call to the show operation, the
  component MUST set its own background color to the resolved palette's
  window-background role color.
- **card-order**: The show operation MUST append exactly six items to the
  container, in this fixed order: the chrome sample, the list sample, the
  controls sample, the status sample, the terminal sample, then the ANSI
  swatch grid.
- **card-width-stretch**: The component MUST size each of the five sample
  cards (chrome, list, controls, status, terminal) to the container's own
  width, so that the leading-aligned, content-sized container does not let
  them collapse to their intrinsic content width.
- **card-minimum-width**: Each of the four cards whose content follows
  card-content-insets (chrome, list, controls, status) and the terminal
  sample's box MUST each enforce a minimum width of 280pt, independent of
  their content.
- **card-content-insets**: The content shared by the chrome, list,
  controls and status cards MUST be inset from the card by exactly 10pt
  from the top, 12pt from the leading edge, and 10pt from the bottom, and
  MUST constrain the trailing edge to at most 12pt from the card's trailing
  edge (the content may be narrower, never wider).
- **chrome-title**: The chrome sample MUST include a label reading
  "Window Title" in the primary-text color and the title text style.
- **chrome-body-and-caption**: The chrome sample MUST include a body
  label reading "Body text in the body font." in primary-text/body style,
  and a caption label reading "Secondary caption text" in
  secondary-text/caption style.
- **chrome-controls-row**: The chrome sample MUST include a horizontal
  row (8pt spacing) of two pill-shaped controls, both set in the button
  text style: a "Button" pill filled with the accent color and text
  colored with the on-accent-text role, and a "Selected" pill filled with
  the selection color and text colored with the selection-text role.
- **chrome-divider**: The chrome sample MUST include a 1pt-tall hairline
  filled with the divider role color, constrained to the card's width
  minus 24pt.
- **chrome-outlined-panel**: The chrome sample MUST include an inner
  rounded (8pt corner radius) panel filled with the elevated-surface color,
  with a 1pt border in the outline role color, containing a caption-styled
  label reading "Panel · outline" in the tertiary-text role, constrained to
  the card's width minus 24pt.
- **list-tab-strip**: The list sample MUST render a horizontal row (4pt
  spacing) of three pills in the button text style: "Notes" filled with
  the elevated-surface color and text in primary-text, and "Chat" and
  "Terminal" each filled with the surface color and text in secondary-text.
- **list-row-set**: The list sample MUST render exactly three rows, in
  this order: ("Release notes", "Yesterday", unselected), ("Design
  review", "2 days ago", selected), ("Scratch", "Last week", unselected).
- **selected-list-row-style**: A selected list row MUST fill its
  background with the selection role color (5pt corner radius) and render
  both its title and detail text in the selection-text role.
- **unselected-list-row-style**: An unselected list row MUST leave its
  background transparent and render its title in primary-text and its
  detail text in tertiary-text.
- **list-row-content-layout**: Each list row MUST place its title label
  leading-aligned with an 8pt inset and its detail label trailing-aligned
  with an 8pt inset, both vertically centered, with the detail label's
  leading edge held at least 8pt from the title label's trailing edge.
- **controls-text-field-pair**: The controls sample MUST render two
  side-by-side, equal-width (8pt spacing) simulated text fields, each a
  5pt-corner-radius box filled with the control-background color and
  outlined with a 1pt border-colored stroke: one showing "Typed text" in
  primary-text, the other showing "Placeholder" in placeholder-text.
- **controls-checkbox-line**: The controls sample MUST render a single
  line of text reading "☑︎ Enabled    ☐ Disabled" in secondary-text/body
  style, as a static representation of a checkbox's checked and unchecked
  appearance.
- **status-badge-set**: The status sample MUST render exactly four
  badges, in this order and color: "Success" (success), "Warning"
  (warning), "Error" (danger), "Info" (info), in a horizontal row with 6pt
  spacing.
- **status-badge-style**: Each status badge MUST be a 5pt-corner-radius
  capsule whose background is its status color at 22% alpha, whose border
  is the same status color at 55% alpha (1pt), and whose text is the same
  status color at full opacity in the caption text style.
- **terminal-box-background**: The terminal sample's box MUST be filled
  with the window-background role color (unlike the other four cards,
  which use the surface color) and outlined with a 1pt border-colored
  stroke.
- **terminal-appearance-resolution**: The terminal sample MUST resolve
  its font, padding and cursor shape from the theme's own terminal-
  appearance resolution — the same resolution a live terminal session
  uses — rather than hardcoding any of the three.
- **terminal-sample-content**: Using the resolved terminal font, the
  terminal sample MUST render a prompt line reading "user@mac ~ % ls" in
  primary-text followed immediately by the caret, and a second line (2pt
  below the first) of "Documents" in the accent color and "README.md" in
  secondary-text, 10pt apart.
- **terminal-content-insets**: The terminal sample MUST inset its
  content from the box's top, leading and bottom edges by exactly the
  theme's resolved terminal padding on that side, and MUST constrain the
  trailing edge to at most the box's trailing edge minus the resolved
  trailing padding.
- **cursor-shape**: The terminal sample MUST render a one-cell caret,
  sized off the resolved font (width = the greater of the font's point
  size times 0.6 or 5, height = the font's point size plus 3, except
  height 2 for the underline shape and width 2 for the bar shape), filled
  or outlined with the cursor role color, in the shape given by the
  resolved cursor shape (block filled, hollow block 1pt-bordered,
  underline a 2pt-tall bar, bar a 2pt-wide bar).
- **ansi-swatch-grid**: The show operation MUST construct and append a
  swatch grid populated with the resolved palette's 16 ANSI colors, at 8
  columns, as the final item in the container.
- **semantic-palette-derivation**: Every color value, and every font
  value except the terminal sample's (which instead resolves via
  terminal-appearance-resolution), MUST come from a single semantic
  palette constructed once at the top of the show operation, read through
  its role-based lookup, never a raw, theme-independent color or font
  literal.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

