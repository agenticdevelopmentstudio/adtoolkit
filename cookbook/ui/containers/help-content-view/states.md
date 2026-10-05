
| State | Appearance change |
|-------|------------------|
| Default | Heading reads "Help"; scroll area shows whatever the content-setting operation was last called with. |
| Empty (no content, or an empty topics list) | Scroll area shows the single "No Help Yet" group — see **empty-state**. |
| Populated (one or more topics) | Scroll area shows one group per topic, in array order — see **topic-groups**. |
| Pressed | Not applicable: this component defines no target/action, gesture recognizer, or tracking area of its own; it is a non-interactive content view. |
| Disabled | Not applicable: the source exposes no enabled/disabled API; it defines no `isEnabled` property or dimmed-appearance logic. |
| Focused | Not applicable: this component never becomes key/first responder itself; the source overrides no responder-chain behavior, and any keyboard focus lands on the scroll view's own default targets, not on this view. |
| Loading | Not applicable: the content-setting operation is synchronous; the source performs no asynchronous operation and defines no loading flag, spinner, or placeholder state. |

