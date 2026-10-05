
- **Corner radius**: None specified for the tree, its rows, or any
  row content view.
- **Padding**: Every row's content is inset 2pt from the row's leading edge
  and at most 6pt from its trailing edge; a file/directory row's horizontal
  content stack additionally pins its trailing edge 6pt in from the row's own
  trailing edge.
- **Font**: Root header label — `.caption` text role. Placeholder label —
  `.caption` text role. File/directory name label — `.body` text role.
  Git-status badge — `.code` text role. (Text *role* here means the theme
  palette's text-role system, which resolves to a concrete font/size; no
  literal point size is set for these elements.)
- **Background**: The outline itself fills with the `.windowBackground` theme
  role; no row or content view sets its own background fill.
- **Foreground/Text**: Name label — `.primaryText` role, overridden per-node
  to a fixed git-status color when `gitStatus` is set. Root header label —
  `.primaryText` when its root is the current selection target,
  `.secondaryText` otherwise. Placeholder label — `.tertiaryText`. Git-status
  badge — `.primaryText` role, overridden to the same fixed status color as
  the name. Icon tint — semantic palette roles per node type (see
  `icon-tint-by-role`). Unsaved-changes marker — `.warning` theme role,
  regardless of node type.
- **Border**: None specified.
- **Shadow**: None specified.
- **Min/Max size**: Row height is fixed at 22pt; indentation per tree level is
  fixed at 14pt; the icon is constrained to 16pt wide; the unsaved-changes
  marker glyph is rendered at 6pt point size, regular weight. No min/max width
  or height constraint is placed on the outline or its scroll view.
- **Outline configuration**: An inset visual style; no header row; a single
  non-resizing outline column; single selection only; empty selection
  permitted (see Platform Notes for the exact configuration properties used
  on Apple platforms).
- **Scrolling**: Vertical scroller only, auto-hiding.
- **Row content layout**: Icon, name, unsaved-changes marker, and (when
  present) a flexible spacer plus the git-status badge, laid out in a
  horizontal stack with 5pt spacing, center-aligned vertically.

