
- **Corner radius**: Not applicable — the card's outline traces straight
  line segments only; no rounded-rect or arc is used anywhere, so every
  corner is square.
- **Padding**: The content column's edge insets: `top: 12, left: 14, bottom:
  12, right: 14`. The content column's spacing: `6pt` between arranged
  elements. The status row's spacing: `2pt` between status symbols. The
  header's own spacing: `6pt` between the agent label, status row, gap, and
  close control.
- **Font**: The agent label and session label use the `body` text role (base
  `13pt`, regular weight — scales with the active theme's size scale). The
  directory label, branch label, and summary label use the `caption` text
  role (base `11pt`, regular weight, same scaling).
- **Background**: Front card: the resolved palette's `projectPaneBackdrop`
  color. Behind card: the `windowBackground` role.
- **Foreground/Text**: Front card: the agent label in `.accent`; the session
  label in `.primaryText`; the directory/branch/summary labels in
  `.secondaryText`; the close control's tint in `.secondaryText`. Behind
  card: the agent label in `.primaryText`; the session label in
  `.secondaryText`; the remaining three labels and the close control's tint
  in `.tertiaryText`.
- **Border**: `1pt` stroke in `projectPaneOutline` (front) or `border`
  (behind), traced along three sides only — the side facing the workspace is
  left open.
- **Shadow**: Not applicable — the card only fills and strokes its outline;
  no shadow is drawn anywhere.
- **Min/Max size**: Card width: `240pt`–`340pt`. Card height: `≥ 136pt`,
  unbounded above. The close control and each status icon: fixed `14×14pt`
  frame. Status symbol glyphs render at `11pt`, regular weight; the close
  control's glyph renders at the platform's default control-image size
  within its `14×14pt` frame.

