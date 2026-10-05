
Not applicable: none of `build.ts`, `route-key.ts`, or `shared.ts` calls a localization or i18n mechanism, and the English strings they do embed — `info.title: 'status-backend'`, and `shared.ts`'s fixed `description` values `'Error'`/`'Success'` — are OpenAPI documentation metadata read by developers and API tooling from the generated document itself, not runtime messages returned to an end user or API caller (the actual runtime error body's `message`/`code` values are supplied elsewhere, by whatever code throws the error).

