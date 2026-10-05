
- **Role/trait**: Not applicable beyond the platform's own default — the
  component sets no explicit accessibility role anywhere in source; it is
  a transparent container whose view is its own content view, with no
  label, icon, or control of its own to expose. Each group view a
  subclass adds manages its own accessibility per its own recipe
  (`adtoolkit://cookbook/ui/settings/layout/group-view`).
- **Label requirements**: Not applicable — this component sets no
  accessibility label on its own view. The descriptor's title becomes the
  sidebar row's accessible name only through the sidebar list component,
  outside this component; any accessible label for the detail pane's
  *content* comes from whatever a subclass adds via its group method or
  its hosting helper.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  this component has no loading or disabled transition of its own for an
  announcement to accompany (see States: Disabled, Loading above).
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-
  driven composition (no touch input path anywhere in this component),
  and this component itself defines no button, checkbox, or other control
  with a hit target for the 44×44pt touch guidance to apply to.

