
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Contribution point (constructor argument) | contribution point | none (required) | The extension-contributed language source `languageIdentifiers` reads via its contributed identifiers; the sole dependency this component is constructed with. |

There are no environment variables or settings keys: this component reads
only its injected contribution point and the linked-in built-in language
catalogue's full language list and default language.

