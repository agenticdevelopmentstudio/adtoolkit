
| State | Appearance change |
|-------|------------------|
| Default | Composer enabled, empty; send button disabled (no text); status row hidden; no typing indicator. |
| Composer disabled (`isComposerEnabled = false` or session `.responding`) | Composer field shows its disabled appearance, prompt tint drops to `placeholderText`, send button loses its accent tint. |
| Responding (session `state == .responding`) | Composer disabled as above; an animated typing indicator is appended to the transcript (see **typing-indicator-while-responding**). |
| Row selected (`isRowSelectionEnabled == true`) | The selected transcript row draws a selection frame; the component itself takes keyboard focus. |
| Pressed | Not applicable: the send button and composer field own their own pressed/hover visuals; the component sets no pressed state of its own. |
| Focused | The composer field can hold keyboard focus (`isComposerFocused`); when row selection is on, the component itself can instead, governing arrow/Return/letter key handling. |
| Loading | See "Responding" above — the typing indicator is this component's only loading affordance. |

