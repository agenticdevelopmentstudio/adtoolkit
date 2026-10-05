
- **Role/trait**: The component is a scroll-container view that defines
  no custom accessibility role, subrole, or override in source; it
  inherits the platform's default scroll-area accessibility
  representation around whatever content the set-content operation
  installs.
- **Label requirements**: Not applicable — the component sets no
  accessibility label anywhere in source; a label describing the panel's
  contents is the responsibility of the content installed via the
  set-content operation, which has its own recipe.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component has no loading, disabled, or other transitional state of
  its own (see States); nothing in the source would need to announce a
  change.
- **Minimum tap target**: Not applicable — the component is not an
  interactive control and defines no clickable or tappable target of its
  own; scrolling is performed through the system-provided scroll
  indicator/trackpad gesture path, which source does not resize or
  override.
- **Keyboard / assistive technology navigation**: Source does not
  override the platform's default keyboard-handling behavior; keyboard
  scrolling (e.g. Page Down/Up) and screen-reader navigation are both
  provided by the inherited scroll-container behavior, unmodified by this
  component.
- **Contrast**: Not applicable — the component draws no background and
  sets no foreground or text color of its own; it renders no content that
  could fail a contrast check.

