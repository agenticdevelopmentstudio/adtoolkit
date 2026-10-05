
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| appearance | an appearance value | white color, white text, both flags `false` | The value the caller sets to drive the caret's fill/outline decision; setting it re-evaluates and re-applies the caret's appearance. |
| appearance's caret color | a color | white | The caret's own color — its fill when filled, its outline when hollow. |
| appearance's text color | a color | white | The glyph color under a hollow caret, so the character under the outline reads as ordinary text. |
| appearance's always-hollow flag | a boolean | `false` | Forces the caret hollow unconditionally, regardless of the marks-active-pane flag or the active-pane state. |
| appearance's marks-active-pane flag | a boolean | `false` | When `true` (and the always-hollow flag is `false`), hollows the caret whenever this view is not inside the pane the active-pane tracker currently treats as active. |

