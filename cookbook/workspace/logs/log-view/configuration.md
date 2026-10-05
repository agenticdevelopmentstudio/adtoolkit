
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | the log provider | required (no default) | The backing data source; its `columns` are captured once at init, its `lines` are re-read on every table reload. |
| `followTail` | boolean | `true` | Whether newly appended rows auto-scroll into view and whether a full replace re-anchors to the bottom; setting it to `false` is how a caller builds a "pause auto-scroll" control. |

A log column (id, title, widths, alignment, click hooks) and a log line
(values, context) are separate value types defined in sibling files, not
owned by this component; this table covers only the options this
component itself exposes.

