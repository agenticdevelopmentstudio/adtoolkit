
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `API_BACKEND_URL` | environment variable (string) | unset | Overrides the resolved backend base URL entirely when non-empty; read via backend-URL resolution's environment parameter, which defaults to the process environment. |
| `NODE_ENV` | environment variable (string) | unset | Selects the fallback backend URL when `API_BACKEND_URL` is unset or empty: `https://api.agenticdeveloperhub.com` when exactly `production`, `http://localhost:3000` otherwise. |
| `prefix` | caller parameter, `'auth' \| 'api'` | none — required | Passed to the handler factory by the site's route file; selects the URL-namespace mapping (`api` → backend root, `auth` → backend `/auth/*`). |
| `path` | route path-segment parameter, string list | — | The catch-all segments after the mount point, supplied by the host's routing layer from the matching catch-all route. |
| A route-level dynamic-rendering directive | framework routing directive, exported by the consuming route file | required by convention | Documented in source's comments as part of the wiring a consuming route file must export; not enforced by this module itself. |

