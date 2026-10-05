
- **Role/trait**: Not applicable — the component sets no accessibility
  role of its own; it is a plain container. The interactive control's own
  role is owned by the choice control, which has its own recipe
  (`adtoolkit://cookbook/ui/settings/rows/popup-menu-choice-view`).
- **Label requirements**: Not applicable to this component — linking the
  control's accessible name to its own label happens inside the choice
  control's own concept, out of this component's scope; see
  `adtoolkit://cookbook/ui/settings/rows/popup-menu-choice-view`.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  no loading state exists here. For disabling, see the open question under
  States.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-
  driven composition (no touch input path); the 44×44pt minimum is
  touch-interface guidance, not a pointer-interface requirement.

