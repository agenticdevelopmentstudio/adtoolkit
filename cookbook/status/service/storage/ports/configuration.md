
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| db connection url | string | (required) | libSQL connection string held by the adapter; only `SnapshotOptions.dbUrl` (tests) overrides it |
| session TTL | number (ms) | 30 days | `createSession` default when `ttlMs` is omitted |
| `TOKEN_PREFIX` | string | 'sts_' | Prefix of every raw API token |
| `PREFIX_LEN` | number | 12 | Leading characters stored as the token display prefix |
| admin emails | string[] | from ADMIN_EMAILS | `StatusConfig.adminEmails`; `roleForEmail` makes a matching email 'admin' on first account |

