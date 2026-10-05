
Document which accessibility display options this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component contains no animation or transition of any kind, so there is no motion for this setting to reduce. |
| Increase Contrast | Not applicable: every color in this view is a semantic theme role (`theme.tertiaryText`, `theme.secondaryText`, `theme.warning`, `theme.accent`, or the inherited ambient foreground) resolved through the active theme's palette; no fixed, non-semantic color literal appears, so contrast adaptation is the active theme's responsibility, not this component's. |
| Differentiate Without Color | Not applicable: no state or meaning in this component is conveyed by color alone. The header icon's color varies by file type (see `header-icon-color-*`), but the same information is always also given as text, in the type description shown right below it. |

