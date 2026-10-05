
| State | Appearance change |
|-------|------------------|
| Default | The choice control shows the item matching the persisted active theme id (or whatever item the control selects by default if none matches, per its own recipe); the preview already shows that theme's full sample, rendered synchronously at construction. |
| Theme picked (choice control) | The choice control's own selection updates immediately; the active-theme setting is written; the preview does not change yet — see **decouples-preview-refresh-from-selection-commit**. |
| Theme changed (notification) | On the next processing turn, the theme manager posts its change notification and the preview fully re-renders. |
| Scope changed (matching) | Same preview re-render, triggered by a theme-scope change notification for this view's resolved scope. |
| Pressed | Not applicable: the component draws no button of its own; the choice control's own press appearance is its own concern. |
| Disabled | Not supported: the component exposes no enabled/disabled property and keeps its choice control private, so neither it nor a host can disable the row (unlike the choice control itself, which exposes that control publicly). |
| Focused | Not styled directly by this component; whichever child view receives keyboard focus (the choice control's own interactive element) follows its own concept's focus rendering. |
| Loading | Not applicable: construction and every refresh are synchronous; there is no asynchronous operation and no loading indicator. |

