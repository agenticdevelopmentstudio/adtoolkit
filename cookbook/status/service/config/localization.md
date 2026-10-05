
None of these three files uses a localization mechanism. `envConfig` throws
exactly one user-facing string, always in English, and everything else
these files produce is either numeric/boolean data or a passthrough of a
host-supplied value. Per this recipe's authoring rules, a hardcoded string
is a fact to record, not a gap to excuse.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — thrown `Error` message | `refusing to boot: AUTH_DISABLED / COOKIE_INSECURE must not be set when NODE_ENV=production` | `envConfig`'s SEC-M5 guard |

