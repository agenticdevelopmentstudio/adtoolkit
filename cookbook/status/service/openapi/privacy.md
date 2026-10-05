
- **Data collected**: None. Per `build.ts`'s own eslint-disable comment, "No client input flows through here" — none of these three files reads, stores, or transmits any caller-, request-, or user-scoped data; every fragment they assemble is a static, trusted document piece derived from the route modules' own zod schemas at build/test time.
- **Storage**: Not applicable — these three files write to nothing; `tools/dump-openapi.ts` (external to these three files) is what writes the assembled document to `openapi.json`.
- **Transmission**: Not applicable within these three files — the assembled document is served over HTTP by the app's `GET /doc` route, which lives outside these three files.
- **Retention**: Not applicable — no data is held by these three files between calls.

