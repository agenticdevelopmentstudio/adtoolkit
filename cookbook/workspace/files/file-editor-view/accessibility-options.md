
Document which accessibility display options (see agenticdevelopercookbook://guidelines/implementing/accessibility/accessibility#respect-accessibility-display-options) this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation or transition appears anywhere in this component; the switch between the empty, loading, text, system-preview, and unavailable states, and the switch between cached editors, is an instantaneous state change, not an animated one, so there is no motion for this setting to reduce. |
| Increase Contrast | Not observed in this component: every color it sets directly (tertiary-text, secondary-text) and every color the mounted editor uses is resolved through the semantic theme system; any contrast adaptation is that system's responsibility, out of this ingredient's scope. |
| Differentiate Without Color | Not applicable: none of this component's own states (empty, loading, text, system-preview, unavailable) are distinguished from one another by color alone — each is a structurally distinct view or a distinct placeholder message. |

