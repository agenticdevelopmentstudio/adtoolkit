
- **Corner radius**: Not applicable — a standard window; the window draws
  no custom-cornered chrome.
- **Padding**: The tabbed content's insets default to 0pt on all four sides
  (persisted keys `pane_spacing_top` / `_leading` / `_bottom` /
  `_trailing`) and are user-configurable. A side tab bar's own start inset
  on the left and right edges equals the content inset plus the height of
  a pane's own title bar (2pt border inset + 26pt title-bar height = 28pt
  total), so a side tab bar's first tab lines up with a pane's own title
  bar rather than floating above it.
- **Font**: Not applicable — the window renders no text directly; toolbar
  labels, tab titles, and footer text are drawn by the tabbed content view,
  the status footer, and the toolbar/drawer components, each a separate
  ingredient.
- **Background**: The window background is set once, at creation, to the
  active theme's window-background color. The plane behind the split tree
  tracks the live theme palette's pane-backdrop (fill) and pane-outline
  (outline) colors, updating live as the theme changes.
- **Foreground/Text**: Not applicable at this layer — see Font.
- **Border**: Not applicable — standard system window border; no HUD-style
  chrome is configured for this window.
- **Shadow**: Not applicable — standard system window shadow.
- **Min/Max size**: Minimum 400×300pt; no maximum size is set.

