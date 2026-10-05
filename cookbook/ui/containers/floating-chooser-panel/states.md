
| State | Appearance change |
|-------|------------------|
| Default | Newly initialized, not yet shown (window not visible); `isDismissing == false`. |
| Pressed | Not applicable — the controller renders no pressable surface of its own; per-press visuals belong to whatever content component an extending component hosts. |
| Disabled | Not applicable — no enabled/disabled state exists for this window controller in source. |
| Focused | Window is key (showing the panel made it key); first responder is whatever the initial-focus hook set, per extending component. |
| Loading | Not applicable — showing the panel is synchronous; no loading/spinner state exists in source. |
| Dismissing | `isDismissing == true`, from entry into closing the panel until the underlying close completes; a nested close call or a focus-loss notification arriving during this interval MUST have no effect. |
| Focus lost, `dismissesOnFocusLoss == true` | Panel closes (losing key status closes the panel). |
| Focus lost, `dismissesOnFocusLoss == false` | Panel remains open and visible; only key-window status is lost. |

