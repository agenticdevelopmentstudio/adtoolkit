
`useTablesWithRows` in `@agentic-toolkit/crud` answers one question for a
data browser's table rail: **which of these tables hold at least one row**,
for the open filter and scope. It is a state-and-network operation with no
visual surface of its own; the `CrudDataBrowser` rail consumes its answer to
list populated tables, set empty ones apart, and mark tables it could not check.

For each candidate table it sends that table's own list request with a
`limit=1` parameter, using the same filter and ecosystem scope the open view
would send, so "has data" is answered by exactly the authorization and scoping
that would serve the rows. It runs the probes with bounded concurrency,
reports the result as three disjoint key sets (`populated`, `empty`,
`unknown`) plus a `failed` flag, and remembers each finished answer so a
remount does not sweep again.

