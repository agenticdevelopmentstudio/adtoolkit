
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | boolean | — | Controls the modal search interaction. |
| `onOpenChange` | callback taking the new open state | — | Fired when the dialog wants to open or close (e.g. Escape, backdrop). |
| `onPick` | callback taking the selected option | — | Fired with the whole selected option when a result is chosen. |
| `search` | callback taking the query text and a cancellation signal, returning a promise of an array of options | — | Caller-supplied lookup; scoping (e.g. to one entity type) is the caller's, via closure. |
| `entityTypeLabel` | string | none | Named in the group label and default placeholder, e.g. `"ecosystem"` → "Search ecosystem addresses…". |
| `title` | string | `"Choose an address"` | Dialog title; passed through as the composed interaction's accessible label. |
| `placeholder` | string | derived from `entityTypeLabel` | Search field placeholder; overrides the derived default when set. |
| `debounceMs` | number | `200` | Milliseconds of no query change before search is invoked. |

