
- **descriptor**: Component MUST expose a public, immutable descriptor,
  set once at construction, supplying the sidebar's title/icon/isDisabled/
  section metadata for this panel.
- **default-descriptor**: Component MUST construct a default descriptor
  when constructed with no descriptor supplied (or an explicit absence of
  one).
- **descriptor-retention**: Component MUST retain the exact descriptor
  instance supplied at construction — rather than constructing a new one —
  whenever one is supplied.
- **root-view**: Component MUST expose its own composed content view — a
  panel view instance this type owns — as its view.
- **add-group**: Component MUST expose a public method that forwards its
  group argument, unchanged, to its own content view.
- **help-content-default**: Component's help content MUST default to none
  when not overridden by a subclass — a plain panel offers no reference
  prose, and the detail pane's help drawer shows its own empty state rather
  than losing its help button.
- **effective-help-content**: Component's effective help content MUST
  return its own help content unless overridden — a plain panel holds no
  selection of its own, so the help it effectively shows is its own.
- **hosts-own-scroll-default**: Component's hosts-own-scroll flag MUST
  default to false unless overridden. (Consumed by the hosting split
  view's detail-pane host, outside this component, to decide whether this
  panel's view is wrapped in a scrolling container or hosted directly.)
- **search-keywords-default**: Component's search keywords MUST default to
  an empty list unless overridden.
- **subclass-default-override-visibility**: Component MUST ensure that a
  subclass's override of any of its help-content, effective-help-content,
  hosts-own-scroll, or search-keywords defaults is observable when the
  panel is referenced through the generic interface the hosting split
  uses to hold panels, not only through its own concrete type.
- **hosting-view-helper**: Component MUST expose a helper that wraps
  arbitrary content for use as a panel's own view.
- **hosting-view-sizing-options**: The wrapper returned by that helper
  MUST advertise the hosted content's size to its container as a sizing
  preference, not a required min/max size constraint. See Design
  Decisions for why.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

