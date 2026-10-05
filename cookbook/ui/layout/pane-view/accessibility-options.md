
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: every appearance change — minimize, restore, zoom, clamping — is an immediate state change (visibility, constraint activation/deactivation, icon swap); no animation context, layer animation, or transition appears anywhere in this concept. |
| Increase Contrast | Not observed in this concept: colors are resolved through the theme system; any contrast adaptation belongs to that system, out of this ingredient's scope. |
| Differentiate Without Color | Not applicable: the pane draws no state distinction using color alone. Its container's fill comes entirely from its container-building hook, which a specialization with a color-only cue (e.g. an active/inactive border) may override — that is the composable-tabs pane view's concern, documented in its own recipe, not this one's. |

