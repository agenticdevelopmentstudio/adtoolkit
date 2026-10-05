
- **required-model-construction**: The component MUST be constructed with
  a required, non-optional `ExtensionQuickPickModel`; it MUST NOT support
  construction from a decoded/serialized form, and any attempt to
  construct it that way MUST trigger a fatal error.
- **fixed-content-size**: The component MUST set its preferred content
  size to 560×400 points immediately upon construction, before its view
  hierarchy is built.
- **title-label**: The component MUST create and
  display a title label only when `model.request.title` is non-nil and
  non-empty; when `title` is nil or empty, the component MUST render no
  title label at all (not a hidden one).
- **title-label-position**: When a title label exists, the component MUST
  pin it 12pt from the root view's top, leading, and trailing edges.
- **search-field-position**: The component MUST pin the search field 12pt
  from the root view's leading and trailing edges, and MUST position its
  top edge 12pt below the title label's bottom when a title label exists,
  or 12pt below the root view's top when it does not.
- **table-scroll-position**: The component MUST position the table's
  scroll container 8pt below the search field's bottom edge, MUST pin its
  leading and trailing edges 12pt from the root view's edges, and MUST pin
  its bottom edge 12pt from the root view's bottom edge.
- **search-placeholder**: The component MUST set the search
  field's placeholder text to `model.request.placeHolder`, or to an
  empty string when `placeHolder` is nil.
- **live-filtering**: On every change to the search
  field's text, the component MUST set `model.query`
  to the field's current text, reload the table, and re-synchronize the
  highlighted row — filtering runs on every keystroke, not only on a
  committed search string.
- **arrow-and-return-routing**: The component MUST route the search
  field's down-arrow, up-arrow, and return/enter key commands, via the
  shared keyboard-routing component, to moving the highlight down,
  moving it up, and choosing the highlighted/checked result, respectively.
- **escape-routing**: The component MUST route the search field's
  cancel key command, and a window-level Escape key
  event captured while the view is visible, to `onCancel()`.
- **escape-idempotency**: A single physical Escape keypress MUST invoke
  `onCancel()` exactly once, never twice. The window-level Escape handling
  installed for `escape-routing` runs before the key event is dispatched
  further and discards a matched keypress — so the same keypress never
  also reaches the search field to raise its own cancel key command a
  second time.
- **search-field-focus**: The table MUST refuse
  keyboard focus; after keyboard focus is requested for the search field,
  the search field MUST hold keyboard focus, and no other view in this
  component takes focus for itself.
- **single-native-selection**: The table MUST disable its own native
  multiple-row selection at all times, including when
  `model.request.canPickMany` is true; multi-selection state MUST be
  tracked separately through `model.checkedIndices` and a per-row
  checkbox, never through native table row multi-selection.
- **table-header**: The table MUST render with no header row.
- **single-item-column**: The table MUST contain exactly one
  column, sized so that it fills the table's full width.
- **single-select-click**: When
  `model.request.canPickMany` is false, clicking a non-separator,
  in-range row MUST highlight that row, synchronize the table selection,
  and immediately invoke `onAccept` with that row's index.
- **multi-select-click**: When
  `model.request.canPickMany` is true, clicking a non-separator, in-range
  row, or its own checkbox, MUST toggle that row's checked state and
  reload only that row's cell, and MUST NOT invoke `onAccept`.
- **separator-and-out-of-range-clicks**: A click on a separator
  row, or on a row index outside `model.visibleIndices`'s bounds, MUST be
  a no-op: it MUST NOT change the highlight, MUST NOT change the checked
  set, and MUST NOT invoke `onAccept`.
- **multi-select-checkbox**: Each non-separator row's
  checkbox MUST be hidden and its title label MUST anchor to the row's own
  leading edge when `model.request.canPickMany` is false; the checkbox
  MUST be shown and the title label MUST anchor to the checkbox's trailing
  edge when `canPickMany` is true.
- **checked-state**: Each non-separator row's checkbox state
  MUST reflect whether `model.checkedIndices` contains that row's item
  index, both when the row is first configured and after every toggle of
  that row.
- **description-and-detail**: Each non-separator row MUST
  display `item.description` trailing the title label when it is non-nil
  and non-empty, and MUST hide that label otherwise; it MUST display
  `item.detail` on a second line when non-nil and non-empty, and MUST hide
  that label otherwise.
- **separator-label**: A separator row MUST display
  `item.label` in a tertiary-text caption label when the label is
  non-empty, and MUST hide that label — leaving a blank row — when
  `item.label` is empty.
- **highlight-selection-sync**: Whenever the highlighted index
  changes, the component MUST select the corresponding row in the table
  and scroll it into view, or deselect all rows when no index is
  highlighted or the highlighted index has no corresponding visible row,
  and MUST invoke `onHighlight` with the highlighted item index whenever a
  row is selected this way.
- **empty-choose**: Invoking the accept action (via Return) MUST
  NOT invoke `onAccept` when `model.acceptedIndices()` returns nil (a
  single-select list with nothing highlighted); it MUST invoke `onAccept`
  with an empty array when multi-select has zero checked items, since an
  empty selection is a valid answer distinct from dismissal.
- **separator-selection-guard**: The table's row-selection gate MUST
  refuse a separator row, in addition to
  the model's own refusal to highlight one.
- **test-identifiers**: The component MUST set an accessibility
  identifier of `extension-quick-pick.search-field` on the search field
  and `extension-quick-pick.table` on the table.
- **shared-keyboard-controller**: The component MUST route all
  keyboard dispatch through the shared keyboard-routing component
  rather than implementing its own key-event handling.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

