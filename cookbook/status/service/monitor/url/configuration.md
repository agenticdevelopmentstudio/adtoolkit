
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` (`hostOf`) | `string` | n/a (required positional argument) | The URL string to extract a host from; not validated as an absolute URL before parsing — a parse failure falls back to returning it unchanged. |
| `url` (`projectPageUrl`) | `string \| null \| undefined` | n/a (required positional argument) | The deploy/provider URL to derive a stable project-page link from; `null`, `undefined`, or `''` short-circuits to `null` before any parsing. |

