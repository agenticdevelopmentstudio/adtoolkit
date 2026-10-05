
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `emitter` | event emitter (list of URLs) | none (required) | The shared emitter `diagnosticsChanged(for:)` fires. Callers MUST pass the same instance handed to every diagnostics-bridge instance built for the same extension host; the extension host's own installer is the given source's one production wiring site for this. |

