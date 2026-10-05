
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `context` | extension environment | (required, no default) | The JavaScript environment installing the class installs into, reading a URL reads `value` against, and building a Uri value builds a result in. |
| `path` (`Uri.file`) | string | (required, no default) | The filesystem path `Uri.file(path)` percent-encodes and stores as `path`, prefixed with `/` if needed (**file-encodes-segments-preserves-slashes**, **file-ensures-leading-slash**). |
| `value` (`Uri.parse`) | string-coercible | (required, no default) | The URI string `Uri.parse(value, strict)` decomposes via its string form before matching (**parse-splits-components**). |
| `strict` (`Uri.parse`) | JavaScript truthy/falsy | falsy | When truthy, requires `value` to carry a scheme or `Uri.parse` throws (**parse-strict-requires-scheme**); never validates the scheme's own grammar. |
| `change` (`with`) | plain object or omitted | `{}` | The field overrides `with(change)` applies; a key with value `undefined` or an absent key both leave that field unchanged (**with-overrides-only-given-fields**). |
| `skipEncoding` (`toString`) | JavaScript truthy/falsy | falsy | When truthy, decodes `authority`/`path`/`query`/`fragment` for that call's return value only (**to-string-skip-encoding**). |
| `base` (`Uri.joinPath`) | `Uri` instance | (required, no default) | The `Uri` whose `path` is extended; MUST be an instance of the installed `Uri` constructor or a `TypeError` is thrown (**join-path-requires-uri-instance**). |
| `...segments` (`Uri.joinPath`) | zero or more strings | (none) | The path segments appended to `base`'s `path`, encoded and joined with `'/'` before insertion (**join-path-inserts-separator**, **join-path-empty-appended-is-unchanged**). |
| `value` (reading a URL) | JavaScript value | (required, no default) | The JavaScript value read as either a real `Uri` instance or a string (**url-from-string**, **url-from-uri-instance**). |
| `url` (building a Uri value) | URL | (required, no default) | The native URL bridged into a `vscode.Uri` via `Uri.parse` on its absolute-string form (**uri-value-builds-via-parse**). |

