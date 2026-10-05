
- Role/trait: Not applicable — the component sets no accessibility role,
  trait, or identifier of its own. The window's accessibility identifier is
  already the single-instance window base's concern (see
  `adtoolkit://cookbook/ui/windows/single-window-controller`); any
  content-level role belongs to whatever content-controller or view type the
  caller supplies — a child component with its own recipe, not this one.
- Label requirements: Not applicable — the component sets no label, for the
  same reason.
- Announce state changes: Not applicable — the component makes no
  accessibility-announcement call of its own.
- Minimum tap target: Not applicable — the component defines no interactive
  control of its own; the content view's target sizing is the
  caller-supplied view's concern.

