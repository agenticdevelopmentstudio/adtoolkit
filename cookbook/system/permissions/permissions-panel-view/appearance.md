
- **Corner radius**: None set by this component itself; it draws no
  background or border of its own. (Each row's own 8pt card corner radius
  is that row component's concern.)
- **Padding**: 0pt on all sides — the stack is pinned to the panel's own
  edges with no constant (see **rows-in-full-bleed-vertical-stack**).
  Between rows, the vertical stack applies 8pt of spacing.
- **Font**: Not applicable. The component creates no text element of its
  own; all label fonts belong to the row component.
- **Background**: None set. The component draws no background of its own;
  it is a transparent layout container.
- **Foreground/Text**: Not applicable. The component renders no text of
  its own.
- **Border**: None set on the panel itself.
- **Shadow**: None specified in source.
- **Min/Max size**: None set. The panel's size is whatever its pinned
  stack resolves to from its arranged rows.

