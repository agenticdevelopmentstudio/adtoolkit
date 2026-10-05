
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no custom animated transition (movement, scaling, sliding, zooming, or pulsing) is implemented anywhere in this file; the only motion is the system-rendered indeterminate progress spinner, which this view does not implement or control. |
| Increase Contrast | Not applicable at this layer for most colors: every color other than the context badge's fallback blue is sourced from the shared theme palette; contrast handling for those is a design-system-level concern this view does not decide, per `agenticdevelopercookbook://guidelines/cookbook/ui/platform-design-languages`. The context badge's stored-color-or-fallback-blue (see **window-context-badge**) is the one exception: it is a fixed system color outside the theme, so Increase Contrast has no effect on it. |
| Differentiate Without Color | Handled: the context badge pairs its color with the context's name as text, not color alone; the Accessibility banner pairs its warning tint with an exclamation-triangle icon and explanatory text; and every selection state is shown by the checkbox glyph itself, not by color. |

