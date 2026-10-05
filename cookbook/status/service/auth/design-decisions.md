
- **Decision**: check the session cookie before the `sts_` bearer token in
  `authenticate`'s resolution order.
  **Rationale**: the source comment states the status BFF (a proxy external
  to these five files) forwards the session cookie's *value* verbatim as an
  inert `Authorization: Bearer` header on some requests; gating the bearer
  branch to values that start with `sts_` and checking the cookie first
  means a dashboard request authenticated by cookie never pays a token
  lookup against that inert forwarded value, and never risks the forwarded
  cookie value being mistaken for an API token.
  **Approved**: pending
- **Decision**: compare the `PEER_TOKEN` bearer with `timingSafeEqual`, but
  compare the OAuth `state` value with plain `!==`.
  **Rationale**: `PEER_TOKEN` is a long-lived shared secret worth protecting
  from a timing side-channel; the OAuth `state` is a single-use, freshly
  generated nonce whose possession already required reading the
  `gh_oauth_state` cookie set on the same login attempt, so a timing
  side-channel on the comparison itself adds no practical attack surface.
  **Approved**: pending
- **Decision**: recover from a `createUser`/`attachGithubId` unique-violation
  by re-querying instead of propagating the raw error.
  **Rationale**: the source comment explains this directly — the loser of a
  concurrent first-login race for the same identity should log into the
  winner's row rather than fail with a raw database error; the old
  human-token login paths this replaced did not have this problem because
  they had no signup race, but GitHub-identity signup does.
  **Approved**: pending
- **Decision**: export a precomputed `DUMMY_PASSWORD_HASH` from
  `password.ts` rather than let a login route skip the bcrypt comparison
  entirely when no user is found.
  **Rationale**: the module comment states this directly: comparing against
  a real cost-10 hash even when no such user/hash exists keeps a login
  response's timing from revealing whether an email is registered; computing
  it once at module load (rather than per request) avoids paying bcrypt's
  cost repeatedly for a value that never changes.
  **Approved**: pending
- **Decision**: use a long-lived (30-day), revocable session cookie rather
  than a short-lived token with refresh rotation.
  **Rationale**: not stated in source; this is a plain fact about the
  code's actual behavior (see the `token-lifecycle` compliance result
  below), not an idealized rationale invented for this recipe.
  **Approved**: pending

