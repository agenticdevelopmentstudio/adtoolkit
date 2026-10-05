
- **Corner radius**: A large corner radius, inherited unmodified from the shared dialog
  ingredient, on both the outer dialog and the note editor.
- **Padding**: Inherited unmodified from the shared dialog ingredient, on both dialogs.
- **Font**: Titles use the shared dialog ingredient's default title font (base size, semibold
  weight); the note content in the detail pane renders as small text with preserved
  whitespace and line wrapping.
- **Background**: Inherited unmodified from the shared dialog ingredient (the `surface`
  theme role).
- **Foreground/Text**: Both dialog titles override the shared dialog ingredient's default
  text color with the `gold` accent theme role; the note content in the detail pane uses the
  default `text` theme role.
- **Border**: Inherited unmodified from the shared dialog ingredient (the `border` theme
  role).
- **Shadow**: Inherited unmodified from the shared dialog ingredient (a pronounced elevated
  shadow).
- **Min/Max size**: The outer dialog overrides the shared dialog ingredient's default max
  width with a wider max width; the note-list host is a fixed-height container (420px); the
  note editor dialog uses a medium-large max width; the editor's text field imposes a
  minimum height.

