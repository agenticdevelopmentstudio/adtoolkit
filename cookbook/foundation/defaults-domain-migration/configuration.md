
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| legacyDomain | text | none, required | The previous domain (bundle identifier) to read from. |
| domain | text | none, required | The new domain to write to. |
| defaults | preferences store | standard user preferences | The store to read and write; injectable for tests. |

The migration reads no environment variable or settings key of its own.

