
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| extension-quick-pick-view-controller-001 | required-model-construction | Construct the component with a valid model | Component initializes; attempting to construct it from a decoded/serialized form traps with a fatal error |
| extension-quick-pick-view-controller-002 | fixed-content-size | Read the preferred content size immediately after construction, before the view hierarchy is built | Preferred content size is 560×400 points |
| extension-quick-pick-view-controller-003 | title-label | `model.request.title = nil`, then load the view | No title label exists in the view hierarchy |
| extension-quick-pick-view-controller-004 | title-label | `model.request.title = "Pick a file"`, then load the view | A title label showing "Pick a file" exists |
| extension-quick-pick-view-controller-005 | title-label-position | `model.request.title` non-empty, view loaded | Title label's top/leading/trailing constraints resolve to 12pt from the root view's respective edges |
| extension-quick-pick-view-controller-006 | search-field-position | `model.request.title = nil`, view loaded | Search field's top edge is 12pt below the root view's top |
| extension-quick-pick-view-controller-007 | table-scroll-position | View loaded with any request | Table's top is 8pt below the search field's bottom; leading/trailing are 12pt from root edges; bottom is 12pt from the root's bottom |
| extension-quick-pick-view-controller-008 | search-placeholder | `model.request.placeHolder = nil`, view loaded | Search field's placeholder text is empty |
| extension-quick-pick-view-controller-009 | live-filtering | Type a character into the search field | `model.query` updates to the field's text, the table reloads, and the highlighted row is re-synced |
| extension-quick-pick-view-controller-010 | arrow-and-return-routing | With the search field focused, press the Down arrow key | The down-arrow command routes through the shared keyboard-routing component, which calls the component's move-selection handler |
| extension-quick-pick-view-controller-011 | escape-routing | With the panel's window active, press Escape | The window-level Escape handling fires and `onCancel()` is invoked |
| extension-quick-pick-view-controller-012 | search-field-focus | Request keyboard focus for the search field | The search field becomes keyboard focus; the table cannot accept keyboard focus |
| extension-quick-pick-view-controller-013 | single-native-selection | `model.request.canPickMany = true`, view loaded | The table's native multiple-row selection is disabled |
| extension-quick-pick-view-controller-014 | table-header | View loaded with any request | The table renders with no header row |
| extension-quick-pick-view-controller-015 | single-item-column | View loaded with any request | The table contains exactly one column, sized to fill the table's width |
| extension-quick-pick-view-controller-016 | single-select-click | `canPickMany = false`; click a valid non-separator row | `model.highlightedIndex` becomes that row's item index, selection syncs, and `onAccept` is invoked with `[itemIndex]` |
| extension-quick-pick-view-controller-017 | multi-select-click | `canPickMany = true`; click a valid non-separator row | `model.checkedIndices` toggles that item index, only that row reloads, and `onAccept` is not invoked |
| extension-quick-pick-view-controller-018 | separator-and-out-of-range-clicks | Click a separator row's index | No change to `model.highlightedIndex` or `model.checkedIndices`; `onAccept` is not invoked |
| extension-quick-pick-view-controller-019 | multi-select-checkbox | `canPickMany = false`, a non-separator row is rendered | The row's checkbox is hidden; the title label anchors to the row's own leading edge |
| extension-quick-pick-view-controller-020 | checked-state | `canPickMany = true`, item index already in `model.checkedIndices`, row rendered | The row's checkbox shows the checked state |
| extension-quick-pick-view-controller-021 | description-and-detail | `item.description = nil`, `item.detail = "extra"`, row rendered | Description label is hidden; detail label shows "extra" and is visible |
| extension-quick-pick-view-controller-022 | separator-label | Separator `item.label = ""`, row rendered | Separator cell's label is hidden, producing a blank row |
| extension-quick-pick-view-controller-023 | highlight-selection-sync | `model.highlightedIndex` set to an index with no corresponding row in `model.visibleIndices` | All rows are deselected; `onHighlight` is not invoked |
| extension-quick-pick-view-controller-024 | empty-choose | `canPickMany = false`, `model.highlightedIndex = nil`; invoke the accept action via Return | `onAccept` is not invoked |
| extension-quick-pick-view-controller-025 | empty-choose | `canPickMany = true`, `model.checkedIndices` empty; invoke the accept action via Return | `onAccept` is invoked with `[]` |
| extension-quick-pick-view-controller-026 | separator-selection-guard | Evaluate the row-selection gate for a separator row's index | Selection is refused |
| extension-quick-pick-view-controller-027 | test-identifiers | View loaded with any request | Search field's accessibility identifier is `"extension-quick-pick.search-field"`; table's accessibility identifier is `"extension-quick-pick.table"` |
| extension-quick-pick-view-controller-028 | shared-keyboard-controller | With the search field focused, issue the up-arrow, down-arrow, and return/enter commands in turn | Each reaches `model` only via the shared keyboard-routing component — `model.highlightedIndex` moves down then up, and the accept action runs on return/enter; no separate key-handling path in this component intercepts any of the three |
| extension-quick-pick-view-controller-029 | escape-idempotency | With the panel's window active and the search field focused, deliver one physical Escape keypress | `onCancel()` is invoked exactly once; the search field's own cancel key command is never separately triggered for that same keypress |
| extension-quick-pick-view-controller-030 | search-field-position | `model.request.title = "Pick a file"`, view loaded | Search field's top edge is 12pt below the title label's bottom |
| extension-quick-pick-view-controller-031 | search-placeholder | `model.request.placeHolder = "Search extensions"`, view loaded | Search field's placeholder text is "Search extensions" |
| extension-quick-pick-view-controller-032 | arrow-and-return-routing | With the search field focused and a highlighted row that is not the first selectable row, press the Up arrow key | The up-arrow command routes through the shared keyboard-routing component, which calls the component's move-selection handler and `model.highlightedIndex` moves to the previous selectable row |
| extension-quick-pick-view-controller-033 | arrow-and-return-routing | `canPickMany = false`, `model.highlightedIndex` set to a valid item; press Return | The return/enter command routes to the accept action, and `onAccept` is invoked with `[highlightedIndex]` |
| extension-quick-pick-view-controller-034 | highlight-selection-sync | `model.highlightedIndex` set to an index with a corresponding row in `model.visibleIndices`, selection re-synced | That row is selected in the table and `onHighlight` is invoked with that index |
| extension-quick-pick-view-controller-035 | multi-select-checkbox | `canPickMany = true`, a non-separator row is rendered | The row's checkbox is visible; the title label anchors to the checkbox's trailing edge |
| extension-quick-pick-view-controller-036 | description-and-detail | `item.description = "extra info"`, row rendered | Description label is visible and shows "extra info" |
| extension-quick-pick-view-controller-037 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

