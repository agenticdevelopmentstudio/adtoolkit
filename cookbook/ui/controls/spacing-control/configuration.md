
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style` | one of two styles: `frame` or `paneDividers` | — (required) | Selects which subset of the spacing value the control builds fields, steppers, arrows, and handles for, and which diagram it draws: the four edges (`frame`) or the two gutters (`paneDividers`). |
| `value` | spacing value | all zero | The numbers currently shown. Assigning it redraws the control but does not invoke `onChange`. |
| `range` | inclusive integer range | `0` to `40` | The floor and ceiling every user-driven edit is clamped to; also sets each stepper's minimum/maximum. |
| `onChange` | callback taking the new spacing value | none | Invoked once per user-driven edit that changes `value` (see fires-onchange-only-on-user-edit / skips-redundant-onchange). Not invoked by assigning `value` directly. |
| settings-bound construction | factory function | — | Not a constructor parameter of the control itself, but the documented way every caller in this framework obtains one: builds a control, then attaches a settings-binding layer (a separate concern, out of this recipe's scope) that seeds it from, and keeps it synced with, the given persisted setting values. The edges list (for the `frame` style) or the gutters list (for the `paneDividers` style) needs to be non-empty for the matching style; construction traps when it is empty. |

