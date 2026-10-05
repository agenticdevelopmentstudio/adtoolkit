
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| manifest | extension manifest | none (required) | The decoded manifest passed to the top-level sections builder; supplies the configuration list, identifier, display name (or bare name), and decoding failures to the lower-level builder. |
| configuration | list of configuration entries | none (required) | The decoded `contributes.configuration` list (already normalized from VS Code's single-object-or-array form upstream) passed to the lower-level sections builder. |
| identifier (owning extension) | string | none (required) | The extension's case-folded `publisher.name` (or bare `name`), used verbatim in every storage name and every note's extension identifier this call produces. |
| fallbackTitle | string | none (required) | The title a titleless section borrows — the manifest's display name, or its bare name, at the one production call site. |
| decodingFailures | list of decoding failures | empty list | Failures the manifest decoder recorded; only an entry whose key equals `"contributes.configuration"` affects this component's output, distinguishing unreadable from undeclared. |
| key (to computing a storage name) | string | none (required) | The dotted property key a caller wants the storage name for. |

No environment variable, settings key of its own, or injected dependency is read by this component — it is a pure function of its parameters.

