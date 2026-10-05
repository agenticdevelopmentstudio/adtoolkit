
| State | Appearance change |
|-------|------------------|
| Default | Toolbar (leading items, Pause, Clear, status dot, status label) above a 1pt divider above the log view, filling the root view; root view background is `.windowBackground`. |
| Pressed | Not applicable: the pause/clear buttons' pressed-state fill (a swap between the `.elevatedSurface` and `.selection` role colors while pressed) is owned by the themed secondary button, a separate themed control; the component applies no pressed-state styling of its own. |
| Disabled | Not applicable: the component never disables the pause or clear button; both remain enabled regardless of connection, pause, or error state. |
| Focused | Not applicable: the component sets no custom focus-ring appearance on any control; whatever focus ring the platform draws by default for a standard button is unmodified. |
| Loading | Represented by the Connecting state below; there is no separate loading spinner or progress indicator. |
| Connected | Connected flag `true`: status dot fills with the `.success` role color; status label text and tooltip read `Connected`. |
| Connecting | Connected flag `false` and no last-error value: status dot fills with the `.warning` role color; status label text and tooltip read `Connecting…`. |
| Error | Connected flag `false` and a last-error value present: status dot fills with the `.danger` role color; status label text and tooltip read the error string verbatim. |
| Paused | Paused flag `true`: pause button title reads `Resume`. Paused flag `false`: pause button title reads `Pause`. |

