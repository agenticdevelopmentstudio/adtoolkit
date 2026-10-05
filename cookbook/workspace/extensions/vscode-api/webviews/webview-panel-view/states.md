
| State | Appearance change |
|-------|------------------|
| Default | The bare webview surface: no corner radius, border, or shadow, and a background derived from the active theme's surface color (see Appearance) |
| Pressed | Not applicable: this component has no pressed state; it hosts a web document rather than drawing an interactive control of its own. |
| Disabled | Not applicable: neither this component nor its options expose a disabled state for the panel as a whole. |
| Focused | Not applicable: this component installs no explicit focus handling of its own; the webview's own standard focus behavior is unmodified. |
| Loading | Not applicable: no loading indicator exists in this component; the webview shows its own default content while a page loads, and this component does not visually distinguish that interval. |
| Unloaded | Before the view is constructed, the webview does not yet exist; assigning `html` or `options` in this state stores the new value but performs no reload, since there is nothing to reload. |
| Displaying host document | The webview exists and is showing the wrapped extension markup, loaded from the panel's host-document URL; further `html`/`options` changes reload it in place. |
| Awaiting placement | No reveal/removal listener has ever been installed; a reveal request or a dispose call is captured for one-time replay rather than acted on. |
| Placed | A reveal/removal listener is installed; further reveal and dispose calls forward directly to it. |
| Disposed | The webview's navigation delegate and message handler are torn down and its content cleared; posting a message returns `false`, `html`/`options` writes no longer reload, and messages from the page are ignored. |

