
- **exposes-descriptor**: The component MUST expose a descriptor property,
  satisfying the requirement that every hostable panel carry the metadata
  (title, icon, disabled state, section) its own sidebar row is built
  from.
- **defaults-descriptor-when-omitted**: When constructed with no
  descriptor argument (or an explicit absence of one), the component MUST
  use a default descriptor whose title is an empty string, rather than
  leaving its descriptor unset.
- **titles-sidebar-from-descriptor**: During initialization, the component
  MUST set its own inherited sidebar title to the descriptor's title, so
  its nested topic list's header defaults to this panel's own title.
- **acts-as-hostable-panel**: The component MUST satisfy the interface a
  hosting split requires of a panel, so an instance MAY be added as a
  panel inside an *enclosing* split's sidebar, nesting one topic/detail
  split inside another.
- **returns-nil-help-content-by-default**: The component's help content
  MUST return none unless a subclass overrides it.
- **falls-back-help-content-through-inner-selection**: The component's
  effective help content MUST return the currently selected inner panel's
  own effective help content when that value is non-empty, and MUST fall
  back to this panel's own help content when there is no inner selection
  or the inner selection's effective help content is empty.
- **surfaces-empty-help-when-chain-exhausted**: Composing
  **falls-back-help-content-through-inner-selection** with
  **returns-nil-help-content-by-default**, when there is no inner
  selection (or the inner selection's effective help content is empty)
  and no subclass overrides this panel's own help content, the
  component's effective help content MUST evaluate to none rather than to
  a placeholder value: a panel with nothing to add gets the drawer's own
  empty state rather than losing its help affordance.
- **reports-no-additional-search-keywords**: The component's search
  keywords MUST return an empty list; it contributes no keywords of its
  own beyond whatever its hosted inner panels supply to their own sidebar
  search.
- **narrows-detail-minimum-thickness**: The component MUST override its
  detail-pane minimum-thickness floor to return `200` points.
- **fixes-content-sized-sidebar**: The component MUST override its
  content-sized-sidebar flag to return true.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

