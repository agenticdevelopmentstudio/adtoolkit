
| # | Input | Expected output/effect | Source |
|---|---|---|---|
| 1 | The method text class computed for each of GET/POST/PUT/PATCH/DELETE/TRACE | Equals the first token of that method's badge class for every method | Method and status tone mapping's test coverage |
| 2 | The method dot class computed for an unrecognized method (TRACE) | Falls back to the neutral dot class rather than throwing or returning nothing | Method and status tone mapping's test coverage |
| 3 | The read-allowlist check applied to an admin-exposure table for a non-admin viewer | False (admin-only table denied to a non-admin viewer) | Table visibility gate's test coverage |
| 4 | The write-allowlist check applied to a catalog-exposure table for a non-admin viewer | False (catalog is readable but not writable by a non-admin) | Table visibility gate's test coverage |
| 5 | The column editability check applied to a relational column with an override set for that column's name, in edit mode | False — an override cannot force a relational column editable outside create mode | Column editability's test coverage |
| 6 | Dirty detection applied with no edits, then applied with an edit typed back to the baseline value | False in both cases — no edits, and an edit typed back to the baseline value | Row edit tracking's test coverage |
| 7 | Row removal against an endpoint that answers `204 No Content` | Resolves via the response-body-discarding request helper; using the JSON-parsing helper on the same response would throw | CRUD resource state's test coverage, corroborated by the JSON helper's documented 204 behavior in the auth client recipe |
| 8 | Two list calls issued in quick succession where the first (older sequence number) resolves after the second (newer sequence number) | Only the newer response's rows are written to state; the stale, later-arriving response is discarded | CRUD resource state's test coverage |
| 9 | Slug projection applied to the endpoint `GET /users/{id}` | `'users-id-get'` — braces stripped, method lower-cased and appended | Endpoint slugging (no dedicated test coverage found) |
| 10 | The request builder invoked with no bearer token, versus the same call with a token supplied | No authorization header in the first case; an authorization header carrying the token is present in the second | Request building and execution (no dedicated test coverage found) |

