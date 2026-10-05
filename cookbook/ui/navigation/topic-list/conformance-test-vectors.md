
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| topic-list-001 | group-items-by-section | Populating the list with two sections, each holding two items, in a given order | The list's rows, top to bottom, are exactly those items in the given section/item order |
| topic-list-002 | header-row-for-titled-section | A section titled "Recents" with one item | A group header row reading "Recents" appears above that item's row |
| topic-list-003 | omit-header-for-untitled-section | A section with no title and two items | No group header row appears; only the two item rows are shown |
| topic-list-004 | flat-row-hierarchy, hide-disclosure-controls | Any populated list | Every node is reported as not expandable, and no row shows a disclosure control |
| topic-list-005 | hide-outline-column-header | Inspect the list after it loads | The list's built-in column header bar is disabled and never drawn |
| topic-list-006 | header-rows-not-selectable | Click, or send an accessibility press action to, a group header row | The selection-gating check fails; the row does not become selected |
| topic-list-007 | disabled-item-selectability | An item marked disabled; select it by click | The row becomes selected and the selection callback is invoked with that item, identically to an enabled item |
| topic-list-008 | mute-disabled-item-appearance | Two items, one marked disabled, one not | The disabled row's label/icon use the tertiary text color; the enabled row's use the primary text color/accent color |
| topic-list-009 | render-item-without-icon-when-nil | An item constructed with no icon | Its row's image view holds no image; no placeholder or broken image appears |
| topic-list-010 | user-selection-callback | User clicks an unselected item row | The selection callback is invoked exactly once with that item |
| topic-list-011 | suppress-onselect-on-programmatic-selection | Select an item by id for an unselected, present id | The row becomes selected but the selection callback is NOT invoked |
| topic-list-012 | select-item-by-id, missing-id-selection | Two items with ids "a" and "b"; select by id "b", then select by id "z" | The first call selects "b"'s row; the second call leaves "b" selected (no change, no crash) |
| topic-list-013 | noop-select-already-selected-id | The row for id "b" is already selected; select by id "b" again | No selection command is re-issued; selection and the selection callback are unaffected |
| topic-list-014 | restore-selection-by-id-after-resection | Item "b" selected; call the grouped setter with a new section list that still contains an item with id "b" | After reload, the row for id "b" is selected again, with no selection callback firing for the transient deselection |
| topic-list-015 | restore-selection-across-theme-change | A row is selected; the active theme changes | After the theme change is applied, the same row is still selected, with no spurious empty-selection callback |
| topic-list-016 | stable-row-node-identity | Call the grouped setter once, then select by id an item present since that call | The list resolves a valid row for that item |
| topic-list-017 | hide-header-when-title-and-accessory-empty | Set the title to none and no header accessory view set | The header view is hidden |
| topic-list-018 | hide-footer-when-unset | Set the footer view to none | The footer container is hidden |
| topic-list-019 | header-accessory-below-title | Set the title to "Panels" and set a header accessory view (e.g. a search field) | The header shows the title label above the accessory view, both spanning the header's width |
| topic-list-020 | footer-spans-sidebar-width | Set a footer view (e.g. an actions bar) | The footer view's leading/trailing edges equal the footer container's; it visually spans the sidebar |
| topic-list-021 | content-below-titlebar-safe-area | Host the component's view in a window whose content extends under the titlebar | The content's top sits at the safe-area inset, not the raw top of the view, so the titlebar does not overlap the list |
| topic-list-022 | preferred-width | One item titled "A very long item title" and no title/footer/accessory | Computing the preferred width returns exactly the item's chrome width plus the rendered width of "A very long item title" in the item font, plus the fixed chrome padding (64pt) |
| topic-list-023 | item-accessibility-id-from-title | An item with id "row-7", title "Appearance" | The row label's accessibility identifier is derived from "appearance" (its slugified title), not from "row-7" |
| topic-list-024 | accessibility-press-selection | Send an accessibility press action to an item row's label | The press selects the row and reports success |
| topic-list-024b | accessibility-press-selection | Install a selection-gating override that fails; send an accessibility press action to an item row's label | The press reports failure; the row does not become selected |
| topic-list-025 | repaint-on-theme-change | Active theme changes from light to dark | Root view, content stack, header view, footer container backgrounds, title label font/color, and list/scroll backgrounds all update to the new palette's values |
| topic-list-026 | single-column-fills-width | Enclosing split view widens the sidebar by 40pt | The list's single column widens by the same amount on the next layout pass; no row clips its label |
| topic-list-027 | overlay-autohide-scroller | Inspect the scroll view after it loads | The vertical scroller floats over content and auto-hides when not scrolling |
| topic-list-028 | automatic-outline-style | Inspect the list's rendering style after it loads | The list renders with the theme-following material, not the forced dark material |
| topic-list-029 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

