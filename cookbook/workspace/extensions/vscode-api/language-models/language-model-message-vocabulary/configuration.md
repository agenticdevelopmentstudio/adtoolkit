
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `context` | script context | none (required) | Installation takes the target context explicitly; there is no ambient or singleton context. |
| global cache key | string (fixed constant) | `"__vscodeLanguageModelVocabulary"` | The global key installation caches the built container under; not settable per call. |
| member names list | list of strings (fixed constant) | the eight names in `vscode.d.ts`'s declared order | Used both to validate the resolved container's shape and, on a missing member, to name the first one missing in the log; not settable per call. |
| `mime` (`LanguageModelDataPart.json`'s 2nd argument) | JS string or `undefined` | `'text/x-json'` when omitted | Explicit values are used verbatim, per **data-part-explicit-mime-override**. |
| `mime` (`LanguageModelDataPart.text`'s 2nd argument) | JS string or `undefined` | `'text/plain'` when omitted | Explicit values are used verbatim, per **data-part-explicit-mime-override**. |
| `mime` (`LanguageModelDataPart.image`'s 2nd argument) | JS string or `undefined` | none — passed straight through, `undefined` if omitted | Unlike `.json`/`.text`, `.image` applies no default, per **data-part-image-factory**. |
| `name` (`LanguageModelChatMessage`'s 3rd constructor argument, and `.User`/`.Assistant`'s 2nd) | JS string or `undefined` | `undefined` when omitted | Per **chat-message-name-defaults-undefined**. |

