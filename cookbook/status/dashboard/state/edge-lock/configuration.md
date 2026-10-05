
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ref` (container reference) | reference to an element, or none | required | The scroll container. Its identity decides when listeners are re-wired. |
| `edge` | `"top" \| "bottom"` | required | The edge the list is locked to. |
| `newestKey` | string or none | required | Key of the newest item. A change triggers the item-change handler. |
| `count` | number | `0` | Item count. A change triggers the item-change handler, so an insert anywhere in the list counts. |
| `PIN_SLACK_PX` | constant | `24` | How far from the edge, in px, still counts as resting on it for item changes. Not configurable by the caller. |

No environment variables, settings keys or injected dependencies. The behavior reads the runtime's resize-notification facility if one exists.

