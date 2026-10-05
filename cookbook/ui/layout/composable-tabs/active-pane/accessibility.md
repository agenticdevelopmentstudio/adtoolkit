
- **Role/traits**: Not applicable. The pane backdrop sets no accessibility
  role, label, or element flag of its own anywhere in the source — it is a
  backdrop, not a control. Any role or label a pane's actual content needs
  belongs to that content's own view controller, which is out of scope for
  this file (see Overview).
- **Keyboard/assistive-technology navigation**: This is the file's central
  accessibility-relevant behavior. Every pointer-driven pane switch (gated by
  the pointer-follows setting) is paired with an ordinary input-focus change,
  using the same focus-assignment mechanism a click already uses (see
  **mouse-moved-takes-focus-before-activating**,
  **focus-walk-proceeds-innermost-to-outermost**, and
  **focus-refusal-blocks-mouse-moved-activation**). Because focus moves
  through the standard focus-chain mechanism rather than a private one, the
  platform's own focus-follows-input-focus behavior for assistive technology
  applies without anything further from this file; the component defines no
  separate accessibility-notification call of its own, and none is required,
  because the underlying focus change is already the standard, observable
  one.
- **Minimum tap target**: Not applicable. The pane backdrop is a full-bleed
  backdrop sized by its enclosing pane's own layout; it is not a discrete
  tappable control with an independently sized hit target, and the source
  treats it as neither a button nor a control.
- **contrast**: The component performs no contrast check of its own. The pane-backdrop, pane-outline and active-pane-outline colors are theme-overridable roles whose values are chosen per theme, so the contrast between the active border and its adjacent backdrop (for example the 3:1 non-text contrast of WCAG 1.4.11) depends on each shipped theme's token values.

