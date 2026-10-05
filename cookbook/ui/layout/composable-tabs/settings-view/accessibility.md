
- **Role/trait**: Not customized beyond the identifiers below — no explicit
  accessibility role assignment appears anywhere in this component. The
  four toggles use the platform's built-in checkbox role; the Done button
  uses a standard push-button role.
- **Label requirements**: Each toggle's visible title (the edge's display
  name — "Top", "Right", "Bottom", "Left") supplies its accessible name; the
  Done button's visible title ("Done") supplies its accessible name. The
  accessibility identifiers this component sets
  (`project-window.project-settings`,
  `project-window.project-settings.done`,
  `project-settings.tabs.<edge>`) are automation hooks, not accessible
  names, and are invisible to assistive technology's spoken output. This
  component sets no accessibility identifier or label on either spacing
  control or on the topic list's sidebar; whatever name each exposes is the
  spacing control's and the topic list's own responsibility, outside this
  component.
- **Announce state changes (e.g., loading, disabled)**: Not implemented in
  the component. When a toggle click is refused because it would disable
  the window's last enabled edge, this component changes the toggle's
  state a second time within the same action handler
  (**reverts-checkbox-to-authoritative-state**), but no explicit
  accessibility notification accompanies that correction anywhere in the
  component. A sighted user sees the toggle spring back to checked; this
  component itself emits no notification of the reversal to assistive
  technology, relying entirely on whatever announcement the platform's own
  automatic accessibility observation of the state change produces, if
  any.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition (no touch input path anywhere in this component); the
  44×44pt minimum is touch-platform guidance, not a pointer-interface
  requirement. This component sets no explicit control size on any button,
  so each keeps the platform's regular system click-target metrics.

