
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `platform` | text value | none (required) | Platform or check key passed to the four platform operations. Unknown keys fall back as described above. |
| `status` | one of the known deploy-status values, or any other text value | none (required) | Deploy status passed to the deploy-status-color and deploy-status-label operations. |
| Deploy-status color map | text-to-theme-role map (module-internal) | built-in | Supplies the status colors. The fallback for unrecognised statuses is its `canceled` entry. |
| Theme color roles | theme tokens | owned by the shared theme package | The returned role names resolve only where the platform's theme system defines them (see Platform Notes for how each platform realizes a theme role). |

The module reads no environment variables and no settings keys, and takes no injected dependencies.

