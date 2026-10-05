
- **Role**: Button, inherited from the platform's native button; the
  component sets no custom accessibility role.
- **Label**: The accessible name is the button's title, set from the view
  model's `title` at construction (see **creates-button-with-view-model-title**);
  the component sets no separate accessibility label.
- **Announce state changes**: Not applicable: the component defines no
  disabled or loading state of its own (see States); if a caller disables
  the button directly, the enabled/disabled announcement is the button's
  native behavior, not something the component implements.
- **Keyboard navigation**: Inherited from the platform's native button —
  Tab/Shift-Tab move focus onto and off the button, and Space or Return
  activate it (see **wires-button-action**). The component adds no custom
  key handling.
- **Minimum tap target**: The component keeps the platform's system
  metrics for the button — no size override of any kind — so the click
  target is the button's regular size, sized to its title (see Platform
  Notes for platform-specific minimum-target guidance).

