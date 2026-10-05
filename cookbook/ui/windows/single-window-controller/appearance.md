
| Element | Value | Source |
|---|---|---|
| Default window size | 600 × 480 pt | the type-level default size |
| Default minimum size | 200 × 150 pt | the minimum-size property |
| Default style mask | titled, closable, miniaturizable, resizable | the style-options default |
| HUD style mask | requests a utility or HUD appearance | subclass override, detected by the build step's window-class check |
| HUD transparency | subclass-supplied value, clamped to 0.3-1.0 | the HUD-configuration operation |
| Background color | Not applicable — the base class sets no explicit background color; a HUD window's translucency is the only appearance concern this class owns, and it is described above. Any theme-token background belongs to the hosted content, not to this class. | this class; contrast with content-level theme observers |

