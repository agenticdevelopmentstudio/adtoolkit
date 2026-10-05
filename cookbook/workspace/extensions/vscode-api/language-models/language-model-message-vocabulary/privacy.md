
- **Data collected**: this component collects no data of its own; it constructs value objects out of whatever `role`, `content`, `name`, `callId`, `input`, `data`, and `mimeType` values an extension already supplies, without retaining a copy beyond the returned instance and the per-context class cache.
- **Storage**: this component performs no persistent storage of its own; a constructed `LanguageModelChatMessage`/`LanguageModelDataPart`/etc. is only as persistent as whatever the caller does with it.
- **Transmission**: this component makes no network call; it neither sends nor receives anything over a network. The message and part values it constructs may later be transmitted to a language model by code outside this component's scope, which this recipe does not cover.
- **Retention**: nothing in this component is retained beyond the lifetime of one function call's local variables, except the per-context installed-class cache (`__vscodeLanguageModelVocabulary`), which holds only the eight constructor/enum objects, never a message's or part's data.

