
Response History produces one hard-coded English string, surfaced as the read's error message rather than rendered by Response History itself. Its one caller, the overview stats view, does not display it.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal in source) | `response-history <status>` | Message of the error raised on a non-ok response, for example `response-history 401` |

