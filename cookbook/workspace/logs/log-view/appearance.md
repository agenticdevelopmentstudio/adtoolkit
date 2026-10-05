
- **Corner radius**: 4pt, on the selected-row highlight fill only (see
  `selected-row-uses-theme-selection-color`). No other element carries a
  corner radius.
- **Padding**: 2pt horizontal / 1pt vertical inset applied only to the
  selection highlight's fill rectangle. No other cell, row, or container
  inset is set; the table's own system-default cell spacing applies
  unmodified.
- **Font**: Cell text uses the themed label's default text role (body
  text), since the cell factory constructs it with no explicit text-role
  override. A styled (attributed) cell value can override this with its
  own font attributes, which take precedence for that cell.
- **Background**: The table fills with the theme's `.windowBackground`
  role — not `.surface` — so the log reads as the full content of its own
  window or pane rather than as a sidebar plane (see Design Decisions). The
  scroll view's own background likewise resolves to `.windowBackground`.
- **Foreground/Text**: Cell text color comes from the themed label's
  default role, `.primaryText`, unless a styled value supplies its own
  color.
- **Border**: None. Row-to-row separation is drawn as a horizontal grid
  line colored with the theme's `.divider` role (see
  `horizontal-grid-lines-only`); there is no vertical border between
  columns and no border around the component itself.
- **Shadow**: None.
- **Min/Max size**: None set by this component. The table's row height
  comes from the platform's own system default row style; no explicit row,
  column, or component height/width constraint is set beyond each column's
  own `defaultWidth`/`minWidth`/`maxWidth`.

