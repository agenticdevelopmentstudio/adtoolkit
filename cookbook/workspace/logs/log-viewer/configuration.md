
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `controller` | the log controller | required (no default) | Owns the log's provider plus connection/pause/error state; the component starts/stops it and reads its state to drive the toolbar. See the Log Controller Contract below. |
| `minimumContentSize` | size (width × height) | `600×400` | Overridable floor enforced as constraints on the root view's own width/height. |
| `toolbarHeight` | number | `40` | Overridable fixed height of the toolbar strip above the log view. |
| leading-toolbar-items hook | a function returning a list of views | `[]` | Overridable hook for extension-supplied views placed left of the built-in controls. |
| extra-trailing-toolbar-items hook | a function returning a list of views | `[]` | Overridable hook for extension-supplied views inserted before the built-in Pause/Clear/status cluster. |
| (fixed, not an extension hook) | size (width × height) | `900×600` | Non-overridable floor combined with `minimumContentSize` (the larger of the two, per dimension) when computing the root view's initial frame; see **default-start-size-floor**. |

### Log Controller Contract

The log controller is a contract confined to the primary UI thread. The
component reads and calls:

| Member | Type | Notes |
|--------|------|-------|
| `provider` | the log provider | Backing store handed to the hosted log view. |
| `isConnected` | boolean | Selects the connected/connecting branch of the status dot and label. |
| `isPaused` | boolean | Drives the pause button's title. |
| `lastError` | optional text | Displayed verbatim in the status label/tooltip when set and `isConnected` is `false`. |
| `onStateChange` | an optional callback, invoked on the primary thread | Assigned at construction to trigger the status-indicator refresh. |
| `start()` | operation | Called when the view appears; documented safe to call repeatedly. |
| `stop()` | operation | Called when the view is about to disappear. |
| `togglePause()` | operation | Called by the pause button. |
| `clear()` | operation | Called by the clear button. |

