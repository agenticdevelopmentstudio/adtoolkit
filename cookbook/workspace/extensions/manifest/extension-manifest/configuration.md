
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| JSON payload | the manifest's raw JSON bytes | none — required | The sole input. A caller constructs its own JSON decoder and decodes it as a manifest; this component defines no custom key-decoding strategy, date-decoding strategy, or extra decode context of its own. |

No environment variable, settings key, or injected dependency exists
anywhere in this component. The lenient array/dictionary/value helpers'
key arguments (e.g. the literal string `"contributes.themes"`) are fixed
at each call site, not runtime configuration a caller can vary.

