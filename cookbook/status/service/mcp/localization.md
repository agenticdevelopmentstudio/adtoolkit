
None of these three files uses a localization mechanism; every user-facing
string (tool description, thrown error message) is a hardcoded English
literal. Per this recipe's authoring rules, a hardcoded string is a fact to
record, not a gap to excuse.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — `forbidden_tier` | `admin tier required` | `registerTool`'s layer-2 re-check refusing an admin-gated tool under `'view'` |
| n/a — `execution_error` | `site not found` | `get_site`, `update_site` when no row matches the given `id` |
| n/a — `execution_error` | `group not found` | `update_group` when no row matches the given `id` |
| n/a — `execution_error` | `integration not found` | `update_platform` when no row matches the given `id` |
| n/a — `execution_error` | `user not found` | `update_user` when `setUserRoleGuarded` resolves `undefined` |
| n/a — `execution_error` | `cannot demote the last admin` | `update_user` when `setUserRoleGuarded` resolves `'blocked'` |
| n/a — `execution_error` | `baseUrl is this monitor's own URL — a monitor is already in its own fleet view` | `add_peer` when `isSelfPeerUrl` matches |
| n/a — `execution_error` | `DUPLICATE_PEER_MESSAGE` (from `peers/base-url.ts`, external to these three files) | `add_peer` when the store insert fails with a duplicate-base-URL constraint violation |

