
- **Data collected**: this component collects no data of its own; it stores whatever `languageId` and language configuration values (comment rules, bracket pairs, word patterns, indentation and on-Enter rules, auto-closing pairs) an extension supplies to `setLanguageConfiguration`, none of which are user personal data or credentials.
- **Storage**: stored configurations live only in the injected language configuration store's in-memory storage; nothing here writes to disk, a database, or any persistent store.
- **Transmission**: this component makes no network call; it neither sends nor receives anything over a network.
- **Retention**: a registration persists in the store until its `Disposable`'s disposal is called or the owning instance of this component's own disposal runs; nothing here expires a registration on a timer or on app restart.

