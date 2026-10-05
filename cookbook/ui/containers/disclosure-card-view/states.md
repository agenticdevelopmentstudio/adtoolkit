
| State | Appearance change |
|-------|------------------|
| Default (expanded, `isCollapsed: false`) | Titlebar strip and the full content area are drawn; subtitle text shown if `subtitle` is non-nil; summary line hidden; disclosure indicator open, tooltip/label "Hide details" |
| Collapsed (`isCollapsed: true`) | Content area hidden; subtitle text forced hidden regardless of `subtitle`; summary line shown, right-aligned, if `summary` is non-empty; if `summary` is also empty, the body section is entirely hidden and the card renders as exactly its titlebar; disclosure indicator closed, tooltip/label "Show details" |
| Dimmed (`isDimmed: true`) | Whole view opacity `= 0.55`; no separate dimmed color set is used — every color the card draws is unchanged, only faded uniformly |
| Pressed | Not applicable beyond the embedded disclosure control's own native pressed appearance: the card itself defines no separate pressed interaction or custom pressed appearance of its own. |
| Focused | Not applicable: the card itself is never focusable and draws no custom focus indicator; the only focusable subview is the disclosure control, which gets the platform's own standard focus indicator. |
| Loading | Not applicable: the component performs no asynchronous operation and defines no loading flag, spinner, or placeholder state. |

