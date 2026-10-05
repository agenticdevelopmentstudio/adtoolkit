
- **Role/trait**: Not applicable — this component assigns no
  accessibility role of its own; the sidebar rows (the panel list), the
  detail chrome's help button (the detail-pane host), and each hosted
  panel each own their own accessibility semantics in their own recipes.
- **Keyboard/assistive technology navigation**: The component MUST
  redirect Down/Up inside the sidebar search field to sidebar-row
  selection (**redirects-arrow-keys-to-selection**), leaving every other
  command (Return, Escape, Left/Right, text editing) to the field's
  default behavior. Beyond that redirect, this component adds no keyboard
  handling of its own; the standard outline/split-view tab order is
  unmodified.
- **Label requirements**: Supported for the search field: it exposes its
  placeholder text as the field's accessible description by default, and
  this component sets no additional label of its own. That placeholder
  text is not itself localized (see Localization).
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  this component has no loading or disabled state to announce (see
  States).
- **Minimum tap target**: Not applicable — this is a pointer-driven
  container; no touch-target constant is set anywhere in this component.
  Hit sizing for the search field and split divider is standard platform
  sizing, not a value this component chooses.

