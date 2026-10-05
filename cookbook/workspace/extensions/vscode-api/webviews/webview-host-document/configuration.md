
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `extensionHTML` | a string | none — required | The extension's own `webview.html` markup, exactly as it assigned it. |
| `initialState` | a string (optional) | absent | The JSON text of the panel's last `setState` call, or absent if it never called one. |

No environment variable, settings key, feature flag, or injected dependency
exists anywhere in this component. The message channel name and the
`postMessage`/`setState` wire values are fixed constants baked into every
call, not runtime configuration a caller can vary.

