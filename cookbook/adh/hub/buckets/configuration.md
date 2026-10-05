
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` (parameter to `BucketsTopic.init`) | `any BucketsDataSource` | none — required | The server access point this topic navigates and posts through; the host supplies its own implementation. |
| `ecosystem` (parameter to every `child(for:path:rail:)` call, and to `createSpec(for:)`/`createTableSpec(for:bucket:)`) | `Ecosystem` | none — required | Supplies the `ecosystemId` value posted with every create call and, per `list-is-ecosystem-scoped`, the scope of `list`/`tables` reads; not among this recipe's given sources beyond its `id` field. |

None of the three given sources reads an environment variable or a named
settings key; every value `BucketsTopic` needs is supplied by its `init`
parameter, the `Ecosystem`/`Bucket`/`BucketTable` values passed into its
methods, or the user's own form input.

