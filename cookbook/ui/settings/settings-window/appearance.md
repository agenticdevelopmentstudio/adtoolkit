
- **Corner radius**: Not applicable — a standard system window; this file
  draws no custom-cornered chrome.
- **Padding**: Not decided in this file — header-bar item spacing follows
  the platform's standard header-bar layout, and a panel's own content
  padding is decided by that panel's own ingredient, a separate concept.
- **Font**: The panel-title item's font is the active theme palette's
  heading text-role font, not a literal point size chosen in this file. The
  help control's icon is rendered at 15pt, regular weight.
- **Background**: The window's background color is set once, at window
  creation, by an inherited window-lifecycle component, to the resolved
  theme palette's window background color — not by this file. With the
  title bar transparent and no title-bar separator, the sidebar's and detail
  pane's own fills read as one continuous color under the header-bar band
  rather than a strip of system chrome laid across both.
- **Foreground/Text**: The panel-title item's text color is the theme
  palette's primary-text color role, re-applied live on theme change; the
  help control's tint switches between the palette's secondary-text and
  accent color roles as described above.
- **Border**: The title-bar separator is explicitly turned off, so no
  separator line is drawn between the header bar and the sidebar/detail
  panes.
- **Shadow**: Not applicable — standard system window shadow; this file
  configures no custom shadow.
- **Min/Max size**: Not decided in this file — no minimum/maximum size
  override is set here. Window sizing comes entirely from inherited
  window-lifecycle and window-management machinery (a default of 600×480pt
  absent a registered window spec for the `"settings"` id), not from any
  value in this file itself.

