
| State | Appearance change |
|-------|------------------|
| Default | Constructed but `startAnimating()` not yet called: every dot sits at its default full opacity of 1.0, since opacity is only ever changed once animation starts. |
| Pressed | Not applicable: the view has no press or click handling of any kind — nothing in the component responds to a press. |
| Disabled | Not applicable: the component has no enabled/disabled-driven appearance change; nothing disables the indicator. |
| Focused | Not applicable: the component gives the view no focus-driven appearance change of any kind. |
| Loading | This is the component's entire purpose: after `startAnimating()`, the dots pulse in the left-to-right chase pattern (see **single-dot-highlighted-per-tick**) until the view is removed from the view hierarchy (see **timer-invalidated-on-removal**). |

