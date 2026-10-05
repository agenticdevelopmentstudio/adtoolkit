
The secret store conforms to the logger factory contract. Subsystem: the
app's bundle identifier — Category: the store's own type name.

| Event | Level | Message shape |
|-------|-------|----------------|
| the underlying add/update call did not report success in `set` | error | interpolates the account key and the resulting status |
| the underlying lookup call reported a status other than success or item-not-found in `copyValue` | error | interpolates the account key and the resulting status |
| a secret was recovered from a legacy access-group scope or a retired service and re-stored under the current scope | info | interpolates the account key and the scope it was recovered from |

No log call in the secret store interpolates the secret value itself (see
`keychain-secret-value-not-logged` above). The other five utilities in this
recipe produce no log output at all; the logger factory contract only
provides the factory the secret store and other conforming types build
their logger from.

