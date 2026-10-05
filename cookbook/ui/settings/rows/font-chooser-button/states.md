
| State | Appearance change |
|-------|------------------|
| Default | Draws the title in the current font (the current selection converted to the sample size, or the system font if none is chosen). |
| Pressed | Not styled by the component itself beyond its stock momentary-push feedback (see **rounded-momentary-style**); on release, the platform's font-selection UI opens (see **opens-font-picker**). |
| Disabled | Not implemented: source never reads or sets an enabled flag. A caller may set one directly through the inherited control property, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by the component; any focus ring is the control's own native focus appearance. |
| Loading | Not applicable: the component performs no asynchronous work of its own and defines no loading state. |

