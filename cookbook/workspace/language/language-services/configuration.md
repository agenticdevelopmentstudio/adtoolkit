
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `uri` | `DocumentUri` (string) | none (required) | The document's identity throughout the text-document model, the document store, and the save scheduler; conventionally an LSP `file://` string produced by the URL-to-document-URI conversion. |
| `languageId` | string | none (required, document creation/open only) | Passed through and stored verbatim; nothing in this component validates or interprets it. |
| `text` | string | none (required, document creation/open only) | The document's initial content; a duplicate open call's text is ignored (see `store-open-first-caller-authoritative`). |
| `version` | integer | `0` | The text document's starting version; bumped by applying edits and by a full replace thereafter. |
| `debounce` | time interval | 1 second | The save scheduler's per-key quiet period before a pending save runs. |
| `write` | function (an injected, asynchronous persistence operation) | none (required) | The caller-injected persistence operation; the scheduler decides only *when* it runs, never *how*. |
| `maximumRetryInterval` | time interval (internal default) | 30 seconds | Ceiling on the exponential backoff applied after a failed write; not exposed as a construction parameter today — a caller cannot currently override it without constructing its own debounce-and-retry helper. |

