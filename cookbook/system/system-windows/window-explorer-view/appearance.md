
- **Corner radius**: Not applicable to the view's own chrome — no rounded
  rectangle is drawn directly; the window-count badge and the context badge
  are drawn as fully rounded capsule shapes, not with a corner-radius value.
- **Padding**: Header row: 16pt horizontal, 8pt vertical.
  Accessibility banner: the same 16pt horizontal / 8pt vertical. Section
  header content: 8pt spacing between icon, name, and count badge; the
  count badge additionally has 4pt horizontal padding. Window row content:
  8pt spacing between the title/subtitle column and the trailing spacer;
  the title/subtitle column itself has 0pt spacing; the dimensions/badge
  row has 4pt spacing; the context badge has 4pt horizontal padding.
- **Font**: All fonts resolve through the theme's font-role mapping,
  wrapping the theme's typography per text role. Header icon and "Windows"
  label: `heading`. "Scanning windows..." and the "Open Settings" banner
  button: `caption`. Empty-state icon: `title`. Window title: `body`.
  Window dimensions: `code`. App name and both badges (count, context):
  `caption`, bolded (`bold`).
- **Background**: View background is not set explicitly (inherits the
  container's). Accessibility banner background: the `warning` theme color
  at 10% opacity. Count badge background: the `primaryText` theme color at
  6% opacity, inside a capsule shape. Context badge background: the
  context's stored color (or a fallback blue when it fails to parse) at 12%
  opacity, inside a capsule shape. The window list itself uses an inset
  style with alternating row backgrounds, which lets the platform draw
  those alternating backgrounds rather than any color this view supplies.
- **Foreground/Text**: The `secondaryText` theme color is used for the
  header icon, a disabled/unselectable row's title, "Scanning windows...",
  "No windows found", and the fallback generic section icon. The
  `tertiaryText` theme color is used for the empty-state icon, "Make sure
  Accessibility permission is granted.", window dimensions, and the
  count-badge number. The `primaryText` theme color is used for a
  selectable row's title. The `warning` theme color is used for the
  banner's exclamation-triangle icon. Context badge text/icon color is the
  context's stored color, or a hard-coded blue — not a theme color — when
  the stored hex fails to parse.
- **Border**: Not applicable — no border is drawn anywhere in the source.
- **Shadow**: Not applicable — no shadow is drawn anywhere in the source.
- **Min/Max size**: The loading and empty states each fill the available
  width with a minimum height of 200 points; no maximum size is set
  anywhere, and the populated list has no minimum-height constraint of its
  own.

