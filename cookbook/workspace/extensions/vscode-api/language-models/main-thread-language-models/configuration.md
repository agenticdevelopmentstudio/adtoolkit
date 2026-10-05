
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | language-model provider seam | none (required) | Sole source of the available chat models and the response stream; not defaulted, per **provider-seam-injected**. |
| not-implemented ledger | shared ledger reference | none (required) | Recorded into for the unimplemented `System` message role and for degraded `sendRequest` options; not defaulted. |
| owning extension identifier | string | none (required) | Which extension owns this component; stamped into every ledger record. Not validated for non-emptiness. |
| `selector` (`selectChatModels` argument) | `vscode.LanguageModelChatSelector?` | absent, matches all | `vendor`/`family`/`version`/`id`, each independently optional; a present-but-non-object value is also treated as "match all." |
| `messages` (`sendRequest` argument) | array of messages | none (required) | Parsed from `sendRequest`'s first argument; a message with an unsupported `role` rejects the whole call. |
| `options.justification` (`sendRequest` argument) | string or absent | absent | Forwarded to the provider's response-streaming call unchanged; never interpreted here. |
| `options.modelOptions` / `.tools` / `.toolMode` (`sendRequest` argument) | present or absent | absent | Presence alone is recorded into the not-implemented ledger; content is never read. |
| `token` (`sendRequest` argument, `CancellationToken`) | duck-typed value or absent | uncancelled | Honoured only when it is an object exposing a callable `onCancellationRequested`; otherwise the request is never cancelled. |
| maximum decodable array length | integer | `100_000` | The ceiling reading array elements enforces for every array this component walks. Not settable per call. |

