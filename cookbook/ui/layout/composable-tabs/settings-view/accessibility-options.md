
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation or transition appears anywhere in this component; any sheet presentation/dismissal animation is owned by the platform's own sheet-transition mechanism, outside this component. |
| Increase Contrast | Not applicable: this component sets no custom color outside theme-role lookups (`.primaryText`, `.secondaryText`, `.elevatedSurface`, `.windowBackground`, `.divider`); those resolve through the active theme palette, which is not overridden here. |
| Differentiate Without Color | Not applicable: each toggle's on/off state is communicated through the platform's own check-mark glyph and track position, not through a color-only signal introduced by this component. |

