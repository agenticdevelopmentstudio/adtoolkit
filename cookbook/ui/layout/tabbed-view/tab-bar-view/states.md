
| State | Appearance change |
|-------|------------------|
| Default (unselected) | Tab button background transparent; label role `secondaryText`; close icon tint `tertiaryText`. |
| Selected | Tab button background fills with `selection`; label role `selectionText`; close icon tint `selectionText`; the accessibility value reports `true`; a hosted item that supports highlight reporting has its highlighted state set `true`. |
| Stacked (vertical bar, content-hosting items only) | An item recedes behind items nearer the selection: its stack depth (index distance from the selected item) is reported to any hosted item that supports it, and its `-16pt`-overlapping wrapper view is drawn and hit-tested beneath nearer items (see the Edge Cases entry on title tabs not being depth-reordered). |
| Pressed | Not applicable: a pointer-down resolves directly to selection or to the close action inside the same pointer-down handling; there is no separate, visually distinct pressed appearance before that resolution. |
| Disabled | Not applicable: no tab, button, or bar exposes a disabled appearance; any item present is always selectable. |
| Focused | Not applicable: the tab button and hosted-item wrapper are plain view types with no keyboard-focus or focus-ring appearance defined (see the Accessibility keyboard-navigation gap). |
| Loading | Not applicable: every operation (setting items, setting the selection, renaming, rebuilding, restacking, resizing) is synchronous; this concept defines no loading/pending indicator. |

