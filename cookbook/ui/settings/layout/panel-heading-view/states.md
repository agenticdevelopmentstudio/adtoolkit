
| State | Appearance change |
|-------|------------------|
| Default | Renders the title label's text at the primary-text/heading style; whether a caption follows depends on the caption argument given at construction. |
| Caption present | The caption view is constructed and arranged below the title label, 6pt apart, its width matched to the stack; the caption-label accessor returns its label. |
| Caption absent | The caption view is absent and never constructed; only the title label is an arranged child; the caption-label accessor returns nothing. |
| Pressed | Not applicable: the source defines no target/action, gesture recognizer, or tracking area — the component has no pressed interaction to represent. |
| Disabled | Not applicable: the source exposes no enabled/disabled API; it defines no enabled property or dimmed-appearance logic. |
| Focused | Not applicable: the view never becomes key/first responder; the source overrides no responder-chain behavior, and the platform's own default (unable to become first responder) applies unmodified. |
| Loading | Not applicable: the source performs no asynchronous operation and defines no loading flag, spinner, or placeholder state. |

