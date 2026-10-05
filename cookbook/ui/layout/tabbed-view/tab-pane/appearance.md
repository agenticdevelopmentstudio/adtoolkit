
- **Corner radius**: None - the card is drawn with square corners on every
  edge; its outline traces straight lines between four right-angle points.
- **Padding**: `12` pt top/bottom × `14` pt left/right, inside the card's
  painted border.
- **Font**: Not set directly by this file; each label carries a semantic
  text role - `.body` for the agent and session labels, `.caption` for the
  directory, branch, and summary labels - whose concrete font is resolved by
  the shared theme system.
- **Background**: Front card (depth `0`): the theme's `projectPaneBackdrop`
  color. Behind card: the theme's `.windowBackground` color.
- **Foreground/Text**: Agent label: `.accent` role when front, `.primaryText`
  role when behind. Session, directory, branch, and summary labels: their
  front-card roles (`.primaryText`/`.secondaryText`/`.tertiaryText` per
  label) when front, and one role step dimmer when behind - directory,
  branch, and summary all render `.tertiaryText` behind the front card.
- **Border**: `1` pt line, in the theme's `projectPaneOutline` color when
  front and the theme's `.border` color when behind; drawn open on the side
  facing the workspace (no line across that side) rather than as a closed
  rectangle.
- **Shadow**: None - no shadow, elevation, or blur is drawn anywhere in this
  component.
- **Min/Max size**: Width clamped between `240` pt (minimum) and `340` pt
  (maximum) on every edge. Height floored at `136` pt with no maximum,
  growing to fit content.
- **Status glyph size**: Each status glyph and the close button are both
  fixed at `14 × 14` pt, with the icon rendered at `11` pt, regular weight.
- **Recession per step**: `4` pt, accumulating up to `3` steps on a vertical
  edge; a flat `4` pt on a horizontal edge.
- **Workspace overhang**: `1` pt - the width of the workspace's own outline,
  so the front card's paint exactly covers it.

