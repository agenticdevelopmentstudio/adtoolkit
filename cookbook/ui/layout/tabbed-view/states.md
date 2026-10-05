
| State | Appearance change |
|-------|------------------|
| Default (unselected tab) | Tab button background transparent; label role `secondaryText`; close icon tint `tertiaryText`. |
| Selected (active tab / group) | Tab button background fills with `selection`; label role `selectionText`; close icon tint `selectionText`; its selected-state indicator reports `true`; a content-hosting item's highlighted state is set `true`. |
| Stacked (vertical edge, content-hosting items only) | An item recedes visually behind items nearer the selection: its stack depth (index distance from the selected item) is reported to any hosted item that supports it, and its `-16pt`-overlapping card is drawn and hit-tested beneath nearer items. Title-only items receive the overlap spacing but not the depth reordering — see Design Decisions. |
| Edge hidden | The edge's bar is hidden and dropped from the edge layout entirely; its tabs are preserved but not drawn. |
| Pressed | Not applicable: a click resolves directly to selection or to the close action in the same pointer-down handling; there is no separate, visually distinct pressed appearance before that resolution. |
| Disabled | Not applicable: no tab, button, or bar has a disabled appearance; a tab that exists is always selectable, and an edge that is off is hidden entirely rather than shown disabled. |
| Focused | Not applicable: the tab button and hosted-item wrapper have no keyboard-focus-ring appearance defined (see the Accessibility keyboard-navigation gap). |
| Loading | Not applicable: every tab operation (add, remove, move, rename, select) is synchronous; this concept defines no loading/pending indicator. |

