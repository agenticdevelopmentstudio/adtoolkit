
| State | Appearance change |
|-------|------------------|
| Default (arranged) | Panes/nested splits occupy the fractions of the split's extent recorded in their thickness fraction, or share evenly when none is set; dividers are drawn at the gutter thickness for the split's axis. |
| Dragging a divider | The user's drag moves the divider live; once released, the split view's resize notification schedules a 300ms-debounced write of the new fractions rather than persisting on every intermediate frame. |
| Minimized (rail) | The pane's owning split item is pinned to a fixed thickness (minimum thickness equal to maximum thickness) with a high holding priority; the item cannot be dragged narrower or wider, and a window resize is taken out of its neighbours instead. |
| Zoomed | Every split item off the path from the root to the zoomed leaf is collapsed; the zoomed leaf's ancestors on that path stay visible and sized as before. Only one leaf per tab may be zoomed at a time (root-only). |
| Collapsed by spec | Not applicable in this component: whether an item can collapse is set from the pane's descriptor, but nothing here ever collapses an item on that basis outside of the zoom path above — user-driven collapse-by-drag is the split view's own default behavior for a collapsible item. |
| Pressed | Not applicable: neither the split view nor its dividers expose a pressed/highlighted visual state in source. |
| Disabled | Not applicable: no split item, divider, or child is ever disabled in source. |
| Focused | Not applicable to the split itself: input focus moves among the *panes* it hosts (see **remove-rehomes-focus**); the split node has no focus appearance of its own. |
| Loading | Not applicable: every mutation (split, remove, rebuild, move) is synchronous; source defines no loading/pending indicator. |

