
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-domain-teams-001 | identifier-validation-shape | Validating the identifier `"com.acme.platform"`. | `null` — accepts reverse-domain identifiers, verified by an existing test in the source. |
| hub-domain-teams-002 | identifier-validation-empty-refused | Validating the empty identifier `""`. | Matches `/required/i` — rejects an empty identifier, verified by an existing test in the source. |
| hub-domain-teams-003 | identifier-validation-shape | Validating the identifier `"platform"`. | Matches `/reverse-domain/i` — rejects a single-label identifier, verified by an existing test in the source. |
| hub-domain-teams-004 | team-vocabulary-mapping | Mapping the backend row `{id:"1", name:"Platform", slug:"com.acme.platform", createdAt:"c", updatedAt:"u"}` to its UI shape. | `displayName === "Platform"`, `identifier === "com.acme.platform"` — renames name→displayName and slug→identifier, verified by an existing test in the source. |
| hub-domain-teams-005 | team-update-partial-via-compact | Updating team `"1"` with `{displayName: "Renamed", identifier: undefined}`. | The update body is `{"name":"Renamed"}` — the `slug` key is absent, not sent as `undefined`. |
| hub-domain-teams-006 | team-create-conflict-rethrown-friendly | Creating a team `{displayName:"X", identifier:"com.acme.x"}` in ecosystem `"eco1"` when the backend throws an error matching "... already exists". | Rethrown as `A team with identifier "com.acme.x" already exists.` |
| hub-domain-teams-007 | team-list-scoped-to-ecosystem, team-list-sorted-by-display-name | Listing teams for ecosystem `"eco1"` over backend rows named `["Beta","Alpha"]`. | `GET /api/team/teams?ecosystemId=eco1`; result names `["Alpha","Beta"]`. |
| hub-domain-teams-008 | team-get-resolves-null-on-thrown-error | Fetching team `"missing"` when the request throws. | Resolves to `null`, does not rethrow. |
| hub-domain-teams-009 | team-delete-issues-delete | Deleting team `"t/1"`. | `DELETE /api/team/teams/t%2F1` (percent-encoded). |
| hub-domain-teams-010 | member-list-tolerates-missing-members-key | Listing members of team `"t1"` when the response body is `{}`. | Resolves to `[]`, no thrown error. |
| hub-domain-teams-011 | member-list-query-scoped-by-team | Listing members of team `"t1"`. | `GET /api/team/members?teamId=t1`. |
| hub-domain-teams-012 | member-counts-maps-team-to-count | Fetching member counts over `{counts:[{teamId:"t1",count:3}]}`. | A map with `get("t1") === 3`. |
| hub-domain-teams-013 | member-add-by-email-resolves-existing-customer | Adding member `"a@b.com"` to team `"t1"` by email. | `POST /api/team/members` with body `{"teamId":"t1","email":"a@b.com"}`. |
| hub-domain-teams-014 | member-add-persona-gated-by-may-act | Adding persona `"sales-bot"` to team `"t1"`. | `POST /api/team/members/personas` with body `{"teamId":"t1","personaKey":"sales-bot"}`. |
| hub-domain-teams-015 | member-remove-addresses-member-row | Removing member `"m/1"`. | `DELETE /api/team/members/m%2F1` (percent-encoded). |
| hub-domain-teams-016 | member-kind-discriminates-customer-vs-persona | A listing row with `memberKind: "elevated"` (an unrecognized value). | Per the field's own documented contract, a consumer MUST treat it as `"customer"`, never as `"persona"`. |

