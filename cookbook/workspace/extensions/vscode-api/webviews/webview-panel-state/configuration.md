
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewType` | a string | none (required) | The view type its serializer is registered under and the activation event name (`onWebviewPanel:<viewType>`) that identifies the owning extension; given when constructing this component from its four fields. |
| `title` | a string | none (required when constructing directly; `""` when a key is absent during decode) | The panel's title at the moment it was stored. |
| `state` | a string (optional) | none (required when constructing directly; absent when a key is absent during decode) | The JSON text the page last passed to `setState`, carried as opaque text. |
| `options` | a webview panel options value | none (required when constructing directly; the safe no-scripts posture when absent during decode) | What the panel was created with — `enableScripts`, `enableForms`, and any declared `localResourceRoots`. |
| `json` | a string | none (required) | The previously-encoded text passed to the decoding operation to reconstruct a value. |

There are no environment variables, settings keys, or injected dependencies:
every input arrives as a plain argument, and every output is a plain return
value or a raised error.

