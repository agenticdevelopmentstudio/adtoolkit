
- **Corner radius**: None on the pane's own backdrop or title bar. The
  arrange-mode toolbar uses an 8pt corner radius.
- **Padding**: Content and title bar are held off the container's edges by
  the border inset (2pt — see **content-inset-matches-border**). The
  arrange overlay is inset from the pane by that same border inset on
  every side. Inside the overlay's toolbar, the button stack is inset 8pt
  on every side and the buttons are spaced 8pt apart; the pane-name label
  and the toolbar are stacked with 10pt spacing between them.
- **Font**: Not set directly in this file. The overlay's pane-name label
  uses a semantic heading text style resolved by the theme system, not a
  literal point size.
- **Background**: The pane's own fill uses the theme's window-background
  role, drawn inside the pane's container view. While arranging, the
  scrim's background is the window-background role at 72% alpha (dims
  content toward the window background rather than toward black, so a
  light theme stays light); the toolbar's background is the theme's
  elevated-surface role.
- **Foreground/Text**: The overlay's pane-name label uses the `primaryText`
  semantic role. Border colors are theme-resolved semantic tokens, not
  literal values: `projectActivePaneOutline` for the active pane,
  `projectPaneOutline` otherwise.
- **Border**: The pane backdrop draws a constant 2pt border on every pane,
  colored per the active-pane rule above. The arrange toolbar draws a 1pt
  border in the `border` semantic color.
- **Shadow**: None. No shadow is drawn on the container, the arrange
  overlay, or its toolbar anywhere in these sources.
- **Min/Max size**: The overlay's pane-name label is constrained to at most
  (overlay width − 16pt), so a long name is clipped rather than widening
  the pane. No other min/max size is set by this file; the pane's own
  bounds are governed by the enclosing split, which is out of scope here.

