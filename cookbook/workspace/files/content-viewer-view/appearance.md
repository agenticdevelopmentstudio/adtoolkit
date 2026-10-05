
- **Corner radius**: None. No corner radius is set on the view or any of its subviews.
- **Padding**: Placeholder `VStack` spacing 12pt between icon and message. Header `VStack` spacing 8pt between icon, name, and type description, with 20pt padding below the header. Divider inset 40pt from each side. Metadata `Grid` horizontal spacing 16pt between columns, vertical spacing 12pt between rows, with 20pt padding above the grid and 40pt padding on each side. The whole detail view is padded 40pt from the top.
- **Font**:
  - Placeholder message — theme `heading` role (default style: 15pt, semibold).
  - Header name — theme `title` role (default style: 22pt, semibold).
  - Header type description — theme `caption` role (default style: 11pt, regular).
  - Every grid label and value — theme `body` role (default style: 13pt, regular).
  - The placeholder icon (48pt) and the header icon (40pt) are set at a fixed icon size rather than through the theme's scalable font sizing, so, unlike every text element in this view, neither icon's size scales with the theme's `sizeScale` text-size preference (see Platform Notes and Design Decisions).
- **Background**: None. No background color is set on the view or any subview; it renders on whatever background its container already painted.
- **Foreground/Text**: Placeholder icon — theme `tertiaryText`. Placeholder message — theme `secondaryText`. Header icon — see `header-icon-color-*` requirements (theme `warning`, `accent`, or `secondaryText` depending on the node). Header type description and every grid label — theme `secondaryText`. Header name and every grid value (path, size, modified date, type, extension, item count) — no explicit foreground is set; each inherits the ambient foreground color, which is the theme's `primaryText` when this component is nested within an ancestor that establishes the active theme.
- **Border**: None specified in source.
- **Shadow**: None specified in source.
- **Min/Max size**: The pane always expands to fill its container's full width and height, in both the placeholder and detail states; no minimum width or height is set anywhere.

