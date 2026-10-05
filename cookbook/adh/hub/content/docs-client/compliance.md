
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |
| [pagination-support](agenticdevelopercookbook://compliance/access-patterns#pagination-support) | failed | Access Patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |

`separation-of-concerns` passes: `docs.ts` owns no HTTP call, wire-shape
knowledge, or taxonomy logic of its own — every operation is either a
direct forward to `markdownApi`/`taxonomyApi` or a one-line marker merge
(`doc-marker-on-create`, `list-scoped-to-doc-marker`). `unit-test-coverage`
fails: `docs.ts` has no test file of its own, and neither of its two
marker-merge lines is exercised by any test in the given sources; the
existing coverage in `markdown.test.ts` tests `withTags`/`categoryNodes`/
`tagNodes`, which this component depends on but does not itself invoke
under test. `error-response-handling` is partial: only `createCategory`'s
409 is mapped to a friendly message (`create-category-conflict-message`);
every other documented backend status this client's calls can receive —
403, 404, 500 — propagates unmodified with no per-status handling
(`errors-propagate-unmodified`). `pagination-support` fails: `list`
requests a fixed 200-row page with no cursor and no follow-up fetch
(`list-page-size-fixed`), so a corpus larger than 200 silently loses rows.
`idempotent-operations` is partial: `createCategory` is deliberately
idempotent when re-posting an existing name under its current parents, but
`create` is not idempotent at all (`create-not-idempotent`) and a repeated
`remove` on an already-removed id is not guaranteed to be a no-op.
`data-minimization` passes: every field sent to the backend is either
caller-supplied content/category/tags/note or the fixed `doc: true`
marker; no additional data is collected or appended.

