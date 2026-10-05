
- **arranges-row-layout**: Component MUST arrange the title label, a
  flexible spacer, and the popup button — in that order — in a single
  horizontal row, and MUST pin that row to the edges of the view.
- **populates-menu-items-from-choices**: Component MUST, during
  initialization, add one popup menu item per entry in the view model's
  choices, in the list's order, titled with that choice's label.
- **attaches-choice-value-to-item**: Component MUST associate each added
  item with that choice's value, so the value can be retrieved when the
  item becomes selected. (Mechanism: see Platform Notes.)
- **attaches-choice-image**: Component MUST attach that choice's symbol
  image to the added item when that choice's image name is supplied.
  (Mechanism: see Platform Notes.)
- **omits-choice-image-when-absent**: Component MUST NOT attach an image to
  an added item when that choice's image name is absent.
- **suppresses-popup-bezel**: Component MUST render the popup as a
  borderless control, with no bezel/box around it. (Mechanism: see
  Platform Notes.)
- **resists-popup-stretch**: Component MUST size the popup to its own
  content rather than stretching to absorb the row's leftover horizontal
  space. (Mechanism: see Platform Notes.)
- **links-popup-accessibility-title**: Component MUST associate the
  popup's accessible name with the visible label, so assistive technology
  announces the popup using the label's text instead of with no name.
  (Mechanism: see Platform Notes.)
- **wires-popup-action**: Component MUST route the popup's
  selection-changed event to the component's own internal handler.
  (Mechanism: see Platform Notes.)
- **initializes-from-view-model**: Component MUST, at the end of
  initialization, set the label's text to the view model's title and,
  when the view model's choices contain an entry whose value equals the
  view model's value, select that entry in the popup.
- **commits-selection-value**: Component MUST commit the newly selected
  item's value into the view model's value whenever the popup's selection
  changes, provided that value resolves to the component's declared value
  type and differs from the current value. (Mechanism: see Platform
  Notes.)
- **ignores-unresolvable-selection**: Component MUST NOT write to the view
  model's value when the selected item's value cannot be resolved to the
  component's declared value type (including when no item is selected).
- **skips-redundant-commits**: Component MUST NOT write to the view
  model's value when the newly selected item's resolved value equals the
  current value.
- **syncs-on-external-change**: Component MUST re-set the label's text to
  the view model's title and re-select the popup item matching the view
  model's value (per **initializes-from-view-model**'s matching rule)
  whenever the view model's change-notification callback fires.
- **exposes-constituent-views**: Component MUST expose the label and the
  popup as public, directly-accessible properties.
- **fixes-choice-set-at-construction**: Component MUST NOT add, remove, or
  reorder popup menu items after initialization; the view model's choices
  are consumed only during construction.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **tolerates-empty-choices**: Component MUST construct without error when
  the view model's choices are empty, adding zero popup menu items and
  leaving no item selected.
- **leaves-unmatched-selection**: Component MUST leave the popup's current
  selection uncorrected (neither cleared nor forced to a fallback) when
  the view model's value matches no choice's value.
- **replaces-onchange-handler**: Component MUST assign its own handler to
  the view model's change-notification callback during initialization;
  doing so replaces any handler already registered on that view model
  instance (see Design Decisions).

