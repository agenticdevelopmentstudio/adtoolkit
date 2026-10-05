
| State | Appearance change |
|-------|------------------|
| Default (style: filled, the default for both construction and restyle) | Solid `color` background; border width 0; label text color computed by `computes-contrasting-text-color` |
| Outlined (style: outlined) | Clear background; 1pt border in `color`; label text color equals `color` |
| Pressed | Not applicable: the component defines no target/action, gesture recognizer, or tracking area in the source — it has no pressed interaction to represent. |
| Disabled | Not applicable: the component exposes no enabled/disabled API; the source defines no `isEnabled` property or dimmed-appearance logic. |
| Focused | Not applicable: the component never becomes key/first responder; the source overrides no responder-chain behavior, and the platform's own default (never focusable) applies unmodified. |
| Loading | Not applicable: the source performs no asynchronous operation and defines no loading flag, spinner, or placeholder state. |

