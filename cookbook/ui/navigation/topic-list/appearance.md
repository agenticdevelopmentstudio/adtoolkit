
- **Corner radius**: 4pt on the selection-highlight rounded rect drawn
  behind a selected row. No other corner radius appears in this
  component.
- **Padding**: Title header: 10pt top / 6pt bottom inset from the header
  area's edges to its content; 14pt leading and 14pt trailing inset from
  the header area's edges to its content; 8pt vertical gap between the
  title label and the accessory container. Item cell: 4pt leading inset
  from the cell to the icon; 6pt gap between icon and label; 4pt trailing
  inset from the label to the cell's trailing edge. Header (group) cell:
  2pt leading inset, vertically centered.
- **Font**: Item labels use the theme's body font; group header labels use
  the theme's caption font; the title label uses the theme's button font.
  All three read the live theme palette rather than a fixed point size,
  and are reapplied on every cell reuse rather than baked in once at cell
  creation.
- **Background**: The root view, content stack, header view, and footer
  container are all painted with the theme's window-background color; the
  scroll and list backgrounds are set to the same value.
- **Foreground/Text**: Item label: the primary text color when enabled,
  the tertiary text color when disabled. Item icon tint: the accent color
  when enabled, the tertiary text color when disabled. Group header
  label: the secondary text color. Title label: the secondary text color.
- **Border**: Not set explicitly anywhere in this component; the scroll
  view's border keeps its platform default, no border - no border is
  drawn around the scroll view.
- **Shadow**: Not applicable - no shadow is drawn, and no shadow property
  is configured, anywhere in this component.
- **Min/Max size**: No explicit min/max width or height constraint is
  applied to the component's own view; the preferred-width computation
  instead computes a content-driven width for a caller (e.g. an enclosing
  split view) to size the sidebar to, rather than the sidebar enforcing
  its own bounds. The item icon has a fixed 16x16pt size.

