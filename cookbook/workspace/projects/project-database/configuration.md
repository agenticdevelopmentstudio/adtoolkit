
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `path` (construction parameter) | string | none — required | Absolute filesystem path to the SQLite file; not validated as absolute, non-empty, or writable before use (see Edge Cases: Null and empty input). |
| `home` (default-path parameter) | directory reference | the current user's home directory | The directory the default path hangs the storage dotfolder off of. |
| `token` (default-path parameter) | string | the shared storage token used by other stores (derived from the running app's name, alphanumeric-filtered) | Names the shared dotfolder this file's database lives in alongside other stores. |
| `at` (mark-opened parameter) | timestamp | the current time at the call site | The timestamp recorded as `last_opened`. |
| `value` (set-setting parameter) | string, optional | none — required | Absent deletes the setting row; any string, including the empty string, upserts it. |

The busy timeout (5,000 milliseconds) and the current schema version
constant (`4`) are fixed constants in this file, not exposed as
configuration a caller can override.

