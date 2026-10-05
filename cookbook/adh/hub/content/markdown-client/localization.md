
Every user-facing error message this package produces is a hardcoded
English string literal, with no localization hook of any kind:

- `markdownApi.publish`'s conflict message: `The route "<route>" is already
  used by one of your papers.`
- `markdownApi.createCategory`'s conflict message: `A category named
  "<name>" already exists somewhere else.`
- `schemasApi.create`'s conflict message (via `rethrowConflict`): `A bucket
  named "<name>" already exists.`
- `assertUniqueTableNames`'s duplicate-name message: `Duplicate table name
  "<name>" in this bucket.`

