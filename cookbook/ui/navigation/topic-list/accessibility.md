
- **Role/trait**: Not explicitly set via a custom accessibility role
  anywhere in this component; the list, its rows, and its cells use the
  platform's default roles, with group header rows marked as group rows.
- **Label requirements**: Each item row's label carries an explicit
  accessibility identifier (a slugified form of the item's title,
  prefixed for this component - see **item-accessibility-id-from-title**),
  and its accessible name is its own displayed text (the item's title) -
  no separate accessibility-label override is set. Group header, title,
  and footer/accessory views carry no accessibility identifier in this
  component.
- **Announce state changes**: Not implemented. When the grouped setter
  reloads the list with a different row count, no accessibility change
  notification informs assistive technology that the visible row set
  changed; a screen-reader user hears nothing until navigating back into
  the list.
- **Minimum tap target**: The list uses its platform's default row-sizing
  style rather than a custom row height, so the row's actual height is
  derived from that default style rather than a literal value this
  component sets. Whatever value that resolves to for the fonts this
  component uses is well under the 44x44pt iOS minimum. This is expected
  for a pointer/keyboard-driven desktop list (not a touch surface); the
  44x44pt (iOS) / 48x48dp (Android) minimum applies to the touch-platform
  translations described in Platform Notes, not to this desktop control.
  Additionally, an item row label's accessibility press handler gives
  assistive technology a press path into a row regardless of its rendered
  size, since activation does not depend on a pointer hitting a physical
  target.

