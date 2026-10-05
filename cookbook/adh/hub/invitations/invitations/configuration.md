
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` | `InvitationsDataSource` (apple) | none, required | Injected at each topic's and `AdminNotesRail`'s initializer; the source of every read and write in the Apple side of this domain. |
| `ecosystemID` | `String` (apple) | none, required | Scopes every `InvitationsDataSource` call to one ecosystem; passed at construction. |
| `path` | `[HTDVItem]` (apple) | n/a | Passed into each topic's `child(for:path:rail:)` and `AdminNotesRail.child(path:)` at navigation time; resolved via `RailPath.last`/`RailPath.id(at:in:)`. |
| `rail` | `EcosystemRail` (apple) | n/a | Passed into each topic's `child(for:path:rail:)` per the `EcosystemTopicProvider` contract; not read by any of the three topics' own logic in this domain. |
| `token` | `string` (web) | none, required | Passed to every one of `preview`, `verify`, `accept`, and `registerWithInvite`; identifies which invite the call concerns. Carried in the URL query string for `preview`, in the request body for the other three. |
| `code` | `string` (web) | none, required | Passed to `verify` alongside `token`; the recipient-entered verification code. |
| `input: RegisterWithInviteInput` (`email`, `password`, `name`, `invite`) | object (web) | none, required | Passed to `registerWithInvite`; forwarded to the backend verbatim with no client-side shaping. |
| Endpoint base path | implicit (web) | `/api/*` | Every `fetch`/`authedJson` call in `invitations.ts` targets a relative `/api/...` path; there is no injected base URL or client instance — the host application's own rewrite of `/api/*` onto the backend (noted in the source's own comment) determines where these requests actually land. |

