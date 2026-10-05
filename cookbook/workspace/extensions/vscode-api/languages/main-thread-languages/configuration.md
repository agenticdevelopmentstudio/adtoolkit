
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `store` | the language configuration store | none (required) | Where every registration this adaptor makes lives; not defaulted, so a caller cannot silently receive a private store nothing else can read, per **main-thread-languages-requires-injected-collaborators**. |
| `vocabulary` | the language vocabulary | none (required) | Answers `getLanguages()`; not defaulted, for the same reason as `store`. The host language vocabulary (see Host Language Vocabulary) is the production conformer; a test hands in a double. |
| `languageId` (1st call argument) | JS string | none (required) | The language identifier `setLanguageConfiguration` registers a configuration under; validated only for being a string, not non-emptiness or uniqueness. |
| `configurationValue` (2nd call argument) | JS value or absent | treated as "every member absent" | Read as the second call argument when present, otherwise treated as absent, then decoded into a language configuration value, which never fails. |
| Maximum decodable array length | integer | `100,000` | The ceiling the shared array-length helper enforces for every array this component walks (`brackets`, `onEnterRules`, `autoClosingPairs`, `notIn`). Not settable per call. |
| Word-pattern empty-match exempt patterns | a set of strings | `["^", "^$", "$", "^\s*$"]` | The `wordPattern` sources exempt from the empty-match refusal, matched against the pattern's source text verbatim. Not configurable by the caller. |

