
**Decision**: Membership by an existing customer (`add`, by email) and
membership by one of the caller's own personas (`addPersona`, by key) are
two separate methods on two separate routes, rather than one method
branching on a `kind` argument.
**Rationale**: The two paths differ in both lookup (an email resolved
against the caller's ecosystem vs. a key resolved against the caller's own
personas) and authorization (an ordinary team-scope check vs. the
persona's own `may_act` `'team'` grant); collapsing them into one signature
would hide which check applies to a given call (file header: "added by
EMAIL, resolved to a customer in the ecosystem — 404 if none... or one of
the caller's personas (added by key, gated on the persona's may_act 'team'
grant)").
**Approved**: pending

**Decision**: `teams.ts` (generic CRUD) maps through a `wire.ts` row type
and a `toTeam` mapper; `team-members.ts` (a hand-written route) declares
`TeamMember` directly, with no separate wire row or mapper.
**Rationale**: The generic-CRUD backend's column names (`name`, `slug`)
differ from the UI's vocabulary (`displayName`, `identifier`), so `teams.ts`
needs a translation layer. The hand-written `/api/team/members` route "is
off the generated OpenAPI surface" and was written to match the UI's
vocabulary directly, so there is no generated row to diverge from and
nothing to translate (file headers of both files).
**Approved**: pending

**Decision**: `teamsApi.create`/`update` perform no pre-read for a
duplicate identifier before writing; the backend's unique `(owner, slug)`
constraint is the only guard, translated to a friendly message via
`rethrowConflict` only after the backend rejects the write.
**Rationale**: A pre-read is racy under concurrent writers and "can't see a
soft-deleted row still holding the slug" — the database constraint is the
one place that can answer "is this slug free" correctly (`teamsApi.create`
inline comment).
**Approved**: pending

**Decision**: `ecosystemId` is a required argument on `teamsApi.list`/
`create`, resolved by the caller (via `hub-domain-ecosystems`'s
`ecosystemIdForSlug`), rather than looked up inside this domain.
**Rationale**: A team's owning ecosystem is "the workspace's ecosystem",
and the slug-to-id resolution is `hub-domain-ecosystems`'s own concern; had
`teams.ts` performed that lookup itself, it would take on a dependency on
another domain's data shape instead of accepting the id its caller already
has (file header: "The caller resolves the id with
`ecosystemsApi.ecosystemIdForSlug(slug)`").
**Approved**: pending

**Decision**: fetching a team by id catches every error and returns `null`; only the backend's 404 is meant to mean "not found".

**Rationale**: the catch block does not inspect the error's status; closing the gap takes narrowing the catch to a 404-status check and rethrowing everything else, or an operator-visible log of the swallowed error.

**Approved**: pending

