
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | View model | — (required) | Supplies the row's title and current string value; receives committed edits. The initializer overwrites this view model's change-notification callback with the component's own sync handler (see Edge Cases). An explanation field the view model may carry is accepted but never read or displayed by this component. |
| `visibleLines` | Integer | `6` | Height of the editor, in lines of the editing font; content beyond it scrolls rather than growing the row (see visible-height). |
| `monospaced` | Boolean | `false` | Selects the theme's code-role font (fixed-width) when `true`, or body-role (proportional) when `false` — right for prompts/code, wrong for prose. |

