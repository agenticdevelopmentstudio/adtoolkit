
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| text (parameter to the strip operation) | string | none — required | The JSONC text to normalize into strict JSON text. |
| data (parameter to the parse-to-object and normalize-to-strict-JSON operations) | bytes | none — required | The raw bytes of a JSONC or strict-JSON document, in any of the six candidate encodings. |

Neither operation reads an environment variable or a settings key, and
neither accepts an injected dependency; every value the component operates
on arrives as a call parameter, and the six-item candidate-encoding list is
a fixed, non-configurable constant (**candidate-list-is-fixed**).

