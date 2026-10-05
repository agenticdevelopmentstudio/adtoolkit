
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ecosystem id | string | none (required) | Passed to every operation; URL-encoded into the request path for every operation except triggering a replay, which places it in the create request's body instead. |
| item id | string | none (required for badge/event-type item operations) | A badge id or an event-type id; URL-encoded into the item route. |
| configuration update input | object | none (required) | Partial-update body for updating a realm's configuration; every field optional. |
| badge create/update input | object | none (required) | Full create/update body for creating/updating a realm badge; every field required. |
| level rungs | list | none (required) | Full replacement ladder for replacing a realm's levels. |
| event-type create/update input | object | none (required) | Create/update body for creating/updating an event type; both fields required. |
| access token | implicit environment dependency | none | Attached to every request by the shared authenticated-request layer; not a parameter of any operation here. |
| request base path | implicit environment dependency | `/api/gamification/...` (relative) | Every path is relative, resolved against the current page origin through the host's generic API proxy; no base-URL environment value appears in this component. |

