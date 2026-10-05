
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| connection URL | a string | required | The one validated input to the connection-opening operation; a `file:` prefix selects the embedded-file/WAL/checkpoint code paths, anything else a remote-database connection. |
| connection auth token | an optional string | absent | Passed through unchanged to the underlying connection; irrelevant for an embedded file, required by a remote database that enforces one. |
| migrations folder | a string | the migrations-folder constant | Overridable only for tests; production callers always take the default. |
| migrations-folder constant | a module-level constant | the package's own `src/libsql/migrations` subdirectory | The migrations this package ships, resolved via the host runtime's own module-resolution mechanism (see Platform Notes). |

