
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ref` (container reference) | reference to an element, or none | required | The scroll container; its direct children are the rows. |
| `edge` | `"top" \| "bottom"` | required | The edge at which the newest row is rendered. |
| `newestKey` | string or none | required | Key of the newest rendered row; the head key when `edge` is `"top"`. |
| `oldestKey` | string or none | `none` | Key of the oldest rendered row; the head key when `edge` is `"bottom"`. |
| `count` | number | `0` | Number of rendered rows; a change re-runs both effects. |
| `slack` (on the at-edge predicate) | number | `PIN_SLACK_PX` (24) | Pixels from the edge that still count as pinned. |
| `PIN_SLACK_PX` | constant | `24` | Module constant; not configurable from the behavior. |
| Resize notifications facility | runtime global | optional | Enables resize re-pinning when present. |

