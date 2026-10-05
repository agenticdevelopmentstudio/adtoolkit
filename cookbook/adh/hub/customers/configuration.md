
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` (parameter to `CustomersTopic.init`) | `any CustomersDataSource` | none — required | The server access point this topic navigates and posts through; the host supplies its own implementation. |
| `ecosystem` (parameter to every `child(for:path:rail:)` call, and to `createSpec(for:)`) | `Ecosystem` | none — required | Supplies the `ecosystemId` value posted with every create/update call and, per `list-is-ecosystem-scoped`, the scope of `list(ecosystemID:)` reads; not among this recipe's given sources beyond its `id` field. |

None of the three given sources reads an environment variable or a named
settings key; every value `CustomersTopic` needs is supplied by its
`init` parameter, the `Ecosystem`/`Customer` values passed into its
methods, or the user's own form input.

