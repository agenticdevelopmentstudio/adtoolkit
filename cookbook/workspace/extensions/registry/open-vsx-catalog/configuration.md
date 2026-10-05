
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| JSON payload | bytes decoded via the catalog's decoder | none — required | The sole decode input for a search entry, a search page, and an extension detail; a caller constructs its own decoder and decodes into these types — this concept defines no custom key-decoding strategy or side channel. |
| host | a semantic version | none — required | The caller-supplied host version the installability verdict compares a declared `engines.vscode` range against. |

No environment variable, settings key, or injected dependency exists
anywhere in this concept. The literal string `"universal"` is a fixed,
compile-time constant read by two properties and one check — it is not
runtime configuration a caller can vary.

