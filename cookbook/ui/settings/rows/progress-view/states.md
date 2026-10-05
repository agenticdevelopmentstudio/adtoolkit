
| State | Appearance change |
|-------|------------------|
| Default | Reflects the view model's progress value at construction time (**reflects-initial-progress-value**): a determinate bar if present, an animating indeterminate bar if absent. The view model's progress value defaults to absent, so a component built from a default-valued view model starts indeterminate and animating. |
| Determinate | The indicator's displayed value equals the view model's progress value; determinate mode is on; animation stopped; the bar shows the filled proportion of that value against the indicator's default 0–100 range (see Configuration). |
| Indeterminate | Indeterminate mode is on; the indeterminate animation has been started, producing the indicator's default bar-style indeterminate animation (a continuously animating bar, not a spinning wheel — no other animation style is ever selected anywhere in source). |
| Pressed | Not applicable: the component defines no click handling of any kind — it is a purely display-only, non-interactive view. |
| Disabled | Not implemented in this component; the source never reads or sets the indicator's enabled state. A caller may set it directly through the public progress-indicator property, at which point the platform's native dimmed appearance applies. |
| Focused | Not applicable: the view never becomes focused; the source overrides no focus-related behavior, and the platform's own default (not focusable) applies unmodified. |
| Loading | This is the Indeterminate state above (the view model's progress value is absent) — the component has no separate loading concept beyond it. |

