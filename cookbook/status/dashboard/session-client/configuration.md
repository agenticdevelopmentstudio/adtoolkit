
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| the API-client argument (to the session-fetch function) | the API client | none — required | Resolves the `/auth/me` URL. |
| the transport argument (to the session-fetch function) | a fetch-like function | the platform's default fetch | Injectable transport for tests. |
| the API-client provider's client / base path | the API client / a string | same-origin default client, base `"/api"` | Supplies the client both hooks obtain from the API-client hook (see the dashboard's API client component). |
| the staleness window | a number of milliseconds | `60,000` | Hard-coded in the session hook; not caller-configurable. |
| the retry count | a number | `3` | Hard-coded in the session hook; not caller-configurable. |
| the shared query client | the caching client this logic relies on | host-provided | Must be mounted by the host; supplies all caching defaults the query does not override. |
| `loginHref` / `signupHref` | strings | `"/login"` / `"/signup"` | Hard-coded in the header-auth hook. |
| Post-logout destination | a string | `"/"` | Hard-coded in the logout callback. |

