
- **Corner radius**: 8pt, on the toolbar container only; the scrim itself
  has no corner radius.
- **Padding**: Toolbar: 8pt on all four sides between the button row and the
  toolbar's edges. Column: 10pt vertical spacing between the pane-name label
  and the toolbar. Button row: 8pt horizontal spacing between Add, Remove,
  Move, and Done.
- **Font**: The pane-name label's font is resolved via the active theme's
  typography for the heading text role — not a fixed literal size or weight
  in this file.
- **Background**: Scrim: the theme's window-background role at 72%
  opacity. Toolbar: the theme's elevated-surface role, fully opaque.
- **Foreground/Text**: Pane-name label: the theme's primary-text role.
- **Border**: Toolbar: 1pt, the theme's border role. The scrim itself has no
  border.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: Not set within this file beyond the pane-name label's
  width cap (at most the overlay's own width minus 16pt); the overlay's own
  frame is sized entirely by the caller's own layout constraints against the
  pane view, which is outside this file.

