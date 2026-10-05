
- **Role/trait**: Not customized — no explicit accessibility role is set;
  the text field carries the platform's own built-in text-field
  accessibility role.
- **Label requirements**: The component never links the text field's
  accessible name to the label — unlike the sibling checkbox row, which
  links its switch to its label for exactly this reason ("a bare switch has
  no name"). Without that link, a screen reader announces the text field as
  an unnamed text field rather than by the row's title. Because the secure
  variant inherits this initializer unmodified, the same gap applies there.
- **Announce state changes**: Not applicable — the component has no loading
  state and never disables itself in source (see States); typed characters
  being entered or deleted are announced through the text field's own
  native accessibility value reporting, unmodified by this component.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition (no touch input path); the 44×44pt minimum is touch-interface
  guidance, not a pointer-interface requirement. No explicit control size is
  set on the text field, so it keeps the platform's regular system
  click-target metrics.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The label and the field's typed text both take the theme's primary-text role, and a placeholder takes the theme's placeholder-text role, which the theme layer derives with only a 1.6 minimum contrast (see Design Decisions); contrast is whatever the active theme resolves for those roles.

