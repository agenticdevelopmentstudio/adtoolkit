
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | `board fetch failed: <status>` | `Error.message` of a non-OK board response, exposed on the returned `error` field; a hardcoded English string with no localization lookup |

The reason values are machine identifiers, not display strings; consumers word their own per-cause messages.

