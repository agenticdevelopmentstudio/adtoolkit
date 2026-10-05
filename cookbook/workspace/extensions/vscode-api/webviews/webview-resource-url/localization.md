
This component's error-description step produces three hardcoded English
sentences, one per failure case, with no locale parameter and no
externalized string table entry.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — not externalized) | A webview asked for "scheme value" in curly quotes, which is not the webview scheme. | The unexpected-scheme failure, shown when a URL's scheme is not `agentic-webview`. |
| (none — not externalized) | A webview asked for panel "declared value" in curly quotes from panel "expected value" in curly quotes. | The unexpected-panel failure, shown when a URL's decoded host does not match the asking panel. |
| (none — not externalized) | A webview asked for "resolved value", which is outside its localResourceRoots. | The outside-declared-roots failure, shown when a candidate file is not inside any declared root. |

