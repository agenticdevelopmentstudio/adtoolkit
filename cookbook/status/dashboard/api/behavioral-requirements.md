
### API client

- **default-base-path**: Constructing the client MUST default the base path to
  a fixed `"/api"` string when the caller supplies no base-path option.
- **url-join**: The url operation MUST return `${basePath}${path}` — a plain
  string concatenation with no encoding, normalization, or leading-slash
  correction.
- **late-request-resolution**: The request operation MUST resolve which
  underlying network-request function to call — an injected one if the
  client was constructed with one, otherwise the platform's default — at the
  time of each call, not once when the client is constructed.
- **json-content-type**: The JSON-request operation MUST send a
  `"Content-Type": "application/json"` header on every request, and MUST let
  any `Content-Type` present in the caller's own headers take precedence over
  that default.
- **json-ok-body**: The JSON-request operation MUST return the parsed
  response body for any successful response whose status is not `204`.
- **json-204-empty**: The JSON-request operation MUST return nothing for a
  successful response with status `204`, without attempting to parse a body.
- **json-error-message**: The JSON-request operation MUST throw an error when
  the response is not successful, with a message of exactly
  `${method} ${url} → ${status}`, where `method` defaults to `"GET"` when the
  caller supplies none, and `url` is the request's resolved URL.
- **json-error-detail**: the thrown error message MUST be suffixed with
  ` — ${text}` when the failed response's body parses as JSON and yields a
  usable detail string, checked in this order: a string `error` field, then
  `error.message`, then a top-level `message` field; the message MUST carry
  no such suffix when the body does not parse as JSON or none of those
  fields is present.
- **event-stream-target**: The open-event-stream operation MUST open a
  Server-Sent-Events connection at the resolved URL for the given path.
- **provider-client-selection**: The client provider MUST use a
  caller-supplied client when one is given, and otherwise MUST construct one
  from the base-path option.
- **provider-memoization**: the client the provider supplies to its consumers
  MUST be cached for as long as the client/base-path identity is unchanged,
  so that re-evaluating the provider with the same identity MUST NOT
  construct a new client instance.
- **accessor-fallback**: The client accessor MUST return the nearest ancestor
  provider's client when one is active, and MUST otherwise return the
  module-level default client singleton, built once at load with no
  arguments.

### Monitoring configuration client

- **endpoint-optional-field-defaults**: The endpoint mapper MUST default each
  of `environment`, `platform`, `deployProject`, and `expectBody` to `null`
  when the corresponding backend row field is absent, and MUST preserve an
  explicit non-absent value (including an explicit `null`) unchanged.
- **endpoint-ignore-warning-default**: The endpoint mapper MUST default
  `ignoreProjectWarning` to `false` when the backend row's field is absent.
- **endpoint-dns-defaults**: The endpoint mapper MUST default each of
  `dnsCheckA`, `dnsCheckAaaa`, and `dnsCheckCname` to `true` when the
  corresponding backend row field is absent, and MUST preserve an explicit
  `false` value rather than overwriting it.
- **site-group-rename**: The site mapper MUST map the backend row's
  group-identifier field to the frontend view's `groupId` field; the
  resulting view MUST NOT carry the backend's original group-identifier
  field name.
- **group-crud**: Listing, creating, updating, and deleting groups MUST call
  `GET`, `POST`, `PATCH`, and `DELETE` respectively against
  `/config/site-groups` (a specific group by appending `/{id}` for update and
  delete), and each of the listing/creating/updating operations MUST return
  its result mapped through the group mapper.
- **site-crud**: Listing, creating, and updating sites MUST call `GET`,
  `POST`, and `PATCH` against `/config/sites` (a specific site by appending
  `/{id}` for update), each returning its result mapped through the site
  mapper; the create-site request body MUST rename the caller's `groupId`
  field to the backend's group-identifier field name.
- **endpoint-list-scope**: Listing endpoints by site MUST request
  `/config/endpoints?siteId={siteId}` (URL-encoded) and MUST map every
  returned row through the endpoint mapper; listing all endpoints MUST
  request the bare `/config/endpoints` path with no `siteId` query
  parameter.
- **endpoint-kind-required**: Creating an endpoint leaves `kind` optional in
  its input shape, and the client passes a caller-supplied `kind` through
  unchecked — the monitoring-configuration client only re-exports the list of
  valid endpoint kinds and never validates against it. A caller that omits
  `kind` sends no `kind` field; the status backend's create-endpoint contract
  accepts it as an optional string and defaults it server-side to `"http"`,
  so the endpoint is stored as an HTTP monitor.
- **endpoint-write-field-list**: Creating and updating an endpoint MUST send
  exactly the endpoint's own writable fields (every endpoint-view field
  except its identifier and site identifier, plus the site identifier/URL on
  create); a field the caller omits MUST be sent as absent, and an absent
  field MUST NOT appear in the serialized request body at all.
- **integration-crud**: Listing, creating, updating, and deleting
  integrations MUST call `GET`, `POST`, `PATCH`, and `DELETE` against
  `/config/integrations` (a specific integration by `/{id}`), passing the
  caller's body object through unmodified — no field allow-list is applied,
  unlike the group/site/endpoint operations.
- **ignored-projects-list**: Listing ignored projects MUST return the result
  of `GET /config/ignored-projects` unmodified (no per-row mapping).
- **ignore-project-fanout**: Marking a batch of projects ignored MUST issue
  one `POST /config/ignored-projects` request per project in its input
  array, concurrently rather than sequentially, and MUST reject as soon as
  any one of those requests rejects; the outcome of every other request
  already in flight at that point MUST NOT be awaited or reported.
- **unignore-project-id**: Un-ignoring a project MUST build its request path
  as `DELETE /config/ignored-projects/{id}`, where `{id}` is the URL-encoded
  string `${platform}|${projectName}`.

### Peer fleet client

- **peer-token-write-semantics**: a caller's partial update to a peer MUST be
  interpreted as: a string value for `token` sets or replaces the stored
  token; `null` clears it; omitting the `token` field from the update MUST
  leave the stored token unchanged, since a redacted token cannot be echoed
  back to distinguish "no change" from "clear."
- **peer-view-redaction**: A peer's returned view MUST NOT carry the raw
  token value; it MUST carry only `hasToken`, a boolean indicating whether a
  token is set.
- **peer-write-passthrough**: Creating and updating a peer MUST serialize the
  caller's body object directly, with no field allow-list step — unlike the
  monitoring-configuration client's group/site/endpoint operations, which
  rebuild an explicit fields object before serializing.
- **peer-crud-routes**: Listing, creating, updating, and deleting peers MUST
  call `GET`, `POST`, `PATCH`, and `DELETE` respectively against
  `/config/peers` (a specific peer by `/{id}` for update and delete).

