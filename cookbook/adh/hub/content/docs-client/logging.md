
Not applicable: `docs.ts` and the `markdown.ts`/`taxonomy.ts` modules it
delegates to contain no `console`/logger call of any kind. Every failure
path either propagates the caller's error unmodified or, for
`createCategory`'s 409, is mapped to a friendlier `Error` and thrown — never
logged.

