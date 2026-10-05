
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | partial | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | reliability |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | access-patterns |
| [pagination-support](agenticdevelopercookbook://compliance/access-patterns#pagination-support) | failed | access-patterns |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | privacy-and-data |

**separation-of-concerns**: passed. Each of the three domains — research
documents, legacy bucket/schema definitions, and taxonomy writes — is its
own module with its own route constants and its own exported API object,
and wire.ts isolates every backend shape from all three. The one crossing
point, `markdownApi.createCategory` posting to the markdown surface instead
of the generic taxonomy door, is deliberate and documented in taxonomy.ts's
own header comment.

**unit-test-coverage**: partial. markdown.test.ts covers the three pure
fallback helpers (`withTags`, `categoryNodes`, `tagNodes`) and two cases of
`markdownApi.routeAvailable`, but none of `markdownApi`'s other eleven
operations, and schemas.ts and taxonomy.ts have no test file at all.

**explicit-error-handling**: partial. `markdownApi.publish` and
`.createCategory` each catch a 409 and rethrow a friendly message, and
`schemasApi.create` does the same for the parent bucket; every other
markdown.ts/taxonomy.ts operation lets its error propagate unmodified.
`schemasApi.get`, by contrast, catches every error indiscriminately and
discards it — the schemas-get-swallows-errors requirement.

**error-recovery**: partial. `schemasApi.create` has an explicit
compensating rollback (delete every table it created, then the parent
bucket) if a child-table insert fails partway, stating its own goal is
avoiding an orphaned half-built schema. `schemasApi.update`'s table-reconcile
loop has no equivalent path — the schemas-update-reconcile-has-no-rollback-or-lock requirement.

**data-integrity**: partial. `assertUniqueTableNames` stops a caller from
creating or renaming into a client-side duplicate before any request is
sent, and `update`'s delete-before-add ordering is explicitly sequenced to
avoid racing the backend's unique index. The same operation's reconcile can
still leave a schema with a half-applied set of tables if one request in
the sequence fails, with nothing to detect or repair it — the
schemas-update-reconcile-has-no-rollback-or-lock requirement.

**idempotent-operations**: partial. `removeCategoryParent`, `deleteCategory`,
and `deleteTag` are each documented as safe to call twice, and
`createCategory` re-posting an existing name is documented as idempotent
when every requested parent is already one of its parents. Create/update/
delete on `markdownApi` and `schemasApi` are ordinary POST/PUT/DELETE with
no such guarantee, and `schemasApi.update`'s reconcile step is the one
operation this package documents no idempotency story for at all.

**error-response-handling**: partial. Three call sites (`markdownApi.publish`,
`markdownApi.createCategory`, `schemasApi.create`) map a 409 to a message a
form can show directly; every other call — including taxonomy.ts's own
documented 409/400 cases on `addCategoryParent` — surfaces the raw thrown
error to its caller with no client-side translation.

**pagination-support**: failed. `markdownApi.list` has no cursor or page
parameter — it always requests the fixed 200-row page — and
`schemasApi.list`/`.get` fetch every bucket and bucket-type row with no
filter at all, relying on the generic CRUD endpoint's own roughly 500-row
cap; a workspace or ecosystem past either limit silently loses rows with no
signal that more exist.

**no-hardcoded-strings**: failed. Every user-facing error message this
package produces — the route-conflict message, the category-conflict
message, the duplicate-table-name message, and the bucket-conflict message
— is a hardcoded English literal with no localization hook.

**data-minimization**: passed. None of the four files persist anything
client-side or add fields beyond what each backend route already expects;
every request body sent is exactly the caller-supplied input, or its
`compact()`-filtered subset for a PUT, and no telemetry, analytics, or
logging call reads any of it.

