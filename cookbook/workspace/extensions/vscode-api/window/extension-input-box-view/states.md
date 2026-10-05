
| State | Appearance change |
|-------|------------------|
| Default | Title/prompt shown per `model.request` (or omitted, per those requirements); field shows `model.value`; validation message starts hidden. |
| Pressed | Not applicable — no button or other pressable control appears in this component; the field is a text-entry control, not a press target. |
| Disabled | Not applicable — the field (and the title/prompt) is never disabled; it is always enabled once the panel is on screen. |
| Focused | The field can become focused (via normal keyboard/click focus, or via `focusField()`). No custom focus-ring styling is set of its own — the platform's default focus indicator for a text field applies. `focusField()` additionally applies `model.initialSelectionUTF16Range()` as the field's text selection, but only when explicitly invoked — not automatically on every focus event. |
| Loading | No loading indication — `model.isValidating` (set true by `beginValidating()`, cleared by `recordValidation(_:)`) changes only the acceptance logic (Return is held and replayed — see `acceptance-deferral`); no visual property (opacity, a spinner, a disabled state, or any other visual cue) is read from or set based on `model.isValidating` anywhere in this component. |

