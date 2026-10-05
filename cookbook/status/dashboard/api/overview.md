
The status dashboard's one port onto its backend, and the two configuration-CRUD clients
built on it. The API client exposes `url`, `request`, `requestJSON`, and
`openEventStream`, all resolved relative to a base path — plus a constructor, a
module-level default client singleton, and a client provider/accessor pair that
every panel and hook call instead of naming a base path themselves. The
monitoring-configuration client covers groups, sites, endpoints, integrations,
and ignored deploy projects, each with a backend row shape mapped to a frontend
view shape. The peer-fleet client is the fleet-membership client: list/create/update/delete
for the peer monitors this one polls, including the shared-secret `token`
field's write-only semantics. All three clients talk to the status backend
through the caller-supplied API client, never naming `/api` themselves except in
the client's one default-base-path constant.

