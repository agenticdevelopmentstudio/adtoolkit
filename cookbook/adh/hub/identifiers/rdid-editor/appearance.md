
The editor sets its own styling only for the caption, the prefix text,
and the row/stack spacing; the field's corner radius, padding, colors,
border, and size all come from the shared field-control shell and the
shared hint/error footnote component — see the Overview.

- **Corner radius**: none set by the editor itself; the input's rounded
  corners come from the shared field shell.
- **Padding**: root stack has 0.375rem gap between label, field row, and
  footnote; the prefix row has 0.25rem gap between the prefix text and
  the input. The input's own horizontal/vertical padding comes from the
  shared field shell.
- **Font**: the label uses a small, uppercase, wide-tracked monospace
  caption style (the shared caption typography role); the prefix text
  uses a small size in the muted-text color role, set directly by the
  editor. The input's text size and the footnote's font come from the
  shared field shell and footnote component respectively.
- **Background**: none set by the editor itself; the input's background
  comes from the shared field shell.
- **Foreground/Text**: label and prefix both use the muted-text color
  role, the prefix set directly by the editor. Input text color and
  hint/error footnote colors come from the shared field shell and
  footnote component.
- **Border**: none set by the editor itself; the input's border, focus
  ring, and invalid-state border/ring come from the shared field shell.
- **Shadow**: none — no shadow appears anywhere in the source.
- **Min/Max size**: the prefix text does not shrink, so the input
  absorbs remaining row width. The input's fixed height, full width, and
  minimum width come from the shared field shell. No maximum width is
  set by the editor.

