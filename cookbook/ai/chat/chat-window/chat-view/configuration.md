
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | view model | required, no default | The session/state source the transcript is folded from; supplied once, at construction |
| `isComposerEnabled` | `Bool` | `true` | Whether the composer accepts input at all; `false` greys the field but keeps it in place |
| `composerPrompt` | `String?` | `nil` | Text drawn in front of the composer field (e.g. a shell prompt); `nil` hides the prompt label entirely |
| `rowActions` | row-action callbacks | all-`nil` by default | The open / jump-to-source / toggle-expand / select callbacks wired to merged-feed transcript rows |
| `isRowSelectionEnabled` | `Bool` | `false` | Whether transcript rows can be picked by click or by arrow key |
| `bubbleLineLimit` | `Int?` | `nil` | Lines a transcript row shows before truncating and offering the rest; `nil` shows the whole message. Not applied to plain (non-row) bubbles |
| `bubbleStyle` | bubble style | `.speaker` | The shape every bubble/row in the transcript is drawn in |
| `drawsBackground` | `Bool` | `true` | Whether the view paints the theme's chat-surface fill behind the transcript |

