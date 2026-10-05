
- **default-runtime-config**: the runtime configuration MUST default to
  `{ storageKey: 'auth_tokens', refreshPath: '/api/auth/refresh' }` before it
  has ever been reconfigured.
- **configure-auth-merges**: reconfiguring auth with a partial update MUST
  shallow-merge that update onto the current configuration, leaving any field
  the update omits unchanged.
- **auth-api-base-resolution**: AS base resolution MUST return an explicitly
  supplied base when given, else an environment-configured base, with any
  trailing `/` characters stripped, and MUST return nothing when neither is
  set.
- **as-endpoint-proxy-fallback**: AS endpoint resolution for a path MUST
  return `${base}${path}` when a base resolves, and MUST return `/api${path}`
  (the same-origin proxy) when no base is configured.
- **auth-tokens-shape**: the token bundle MUST carry exactly an access token
  (string) and a refresh token (string).
- **auth-user-shape**: the user record MUST carry `id`, `email`, `name`,
  `avatarUrl` (string), `capabilities` (string list), `authMethods` (a list of
  auth-method records), and `attributes` (a list of attribute records), and
  MAY carry `slug` (string or nothing).
- **has-capability-null-safe**: the capability check MUST return true if and
  only if the user's capabilities include the requested capability, and MUST
  return false when the user is absent.
- **is-admin-derived**: the admin check MUST return the result of the
  capability check for `'admin'`.
- **tokens-from-response-precedence**: token extraction from a response body
  MUST prefer an `accessToken` field over a `token` field when both are
  present.
- **tokens-from-response-refresh-token-blanked**: token extraction MUST
  always set the returned refresh token to `''`, regardless of whether the
  response body carries one — refresh/revoke are cookie-first against an
  HttpOnly cookie, and any refresh-token field the backend returns is
  deliberately never read or persisted.
- **tokens-from-response-throws-when-absent**: token extraction MUST throw
  `Error('Token response missing token/accessToken')` when neither an
  `accessToken` nor a `token` field is present.
- **token-storage-key-configurable**: reading, writing, and clearing the
  stored token bundle MUST read, write, and remove a persistent client-side
  store entry named by the current configuration's storage key, as JSON.
- **token-read-off-browser-returns-null**: reading the stored token bundle
  (and therefore reading the stored access token) MUST return nothing when no
  interactive host environment is present (e.g. during server-side
  rendering).
- **token-read-malformed-json-returns-null**: reading the stored token bundle
  MUST return nothing when the stored value is not valid JSON, without
  throwing.
- **write-tokens-persists-and-announces**: writing the token bundle MUST
  persist it under the storage key and then invoke every subscriber
  registered for session-change notifications.
- **clear-tokens-clears-sibling-user-key**: clearing the token bundle MUST
  remove both the tokens entry and the sibling cached-user entry (keyed as
  `${storageKey}:user`), then invoke every session-change subscriber.
- **read-access-token-derivation**: reading the stored access token MUST
  return the token bundle's access token, or nothing if no bundle is stored.
- **session-change-subscription**: session-change subscription MUST register
  a callback to be called on every subsequent token write/clear, and MUST
  return an unsubscribe function that removes that callback from the
  subscriber set.
- **session-change-payload-free**: session-change subscribers MUST be
  invoked with no arguments — the announcement communicates only that the
  session moved, never what it moved to.
- **session-change-snapshot-iteration**: the session-change announcement MUST
  iterate a snapshot of the subscriber set, so a subscriber that unsubscribes
  itself or another subscriber from inside its own callback does not affect
  delivery to the other subscribers in that same announcement.
- **decode-base64url-json-utf8-strict**: base64url-JSON segment decoding MUST
  base64url-decode the segment and decode the resulting bytes as UTF-8 using
  a strict decoder — never substituting U+FFFD for an invalid byte sequence —
  before parsing the text as JSON.
- **decode-base64url-json-tolerates-missing-padding**: base64url-JSON segment
  decoding MUST tolerate a segment whose `=` padding was stripped, by
  re-padding to a multiple of 4 characters before decoding.
- **decode-base64url-json-never-throws**: base64url-JSON segment decoding
  MUST return nothing, never throw, for input that fails at any step —
  invalid base64, invalid UTF-8, or invalid JSON.
- **read-token-subject-derivation**: reading the token's subject claim MUST
  return the string `sub` claim decoded from the second dot-separated segment
  of the stored access token, and MUST return nothing when no token is
  stored, the token has no second segment, decoding fails, or `sub` is not a
  string.
- **read-user-validates-shape**: reading the cached user record MUST return
  nothing — never the malformed value — when the cached user blob is absent,
  lacks a string `id`, or lacks a list `capabilities`.
- **write-user-persists-off-browser-noop**: writing the cached user record
  MUST persist it under the cached-user key as JSON, and MUST be a no-op when
  no interactive host environment is present.
- **refresh-single-flight-dedup**: the refresh operation MUST return the
  same in-flight promise to every caller while a refresh is outstanding,
  issuing exactly one network request regardless of how many callers invoke
  it concurrently.
- **refresh-request-shape**: a refresh attempt MUST `POST` the literal body
  `'{}'` to the configured refresh path with credentials included and header
  `Content-Type: application/json`.
- **invalidate-refresh-bumps-generation**: refresh invalidation MUST
  increment the module's generation counter and MUST discard any outstanding
  in-flight refresh reference, so a fresh login or logout invalidates a
  refresh that started before it.
- **refresh-generation-guard**: if the generation counter has changed
  between the start of a refresh attempt and its response arriving, that
  attempt MUST resolve to nothing on the success path without writing or
  clearing the token bundle.
- **refresh-success-adopts-current-storage**: on a successful refresh
  response, a refresh attempt MUST compare the access token currently in
  storage against the one read at the start of the attempt; if storage no
  longer holds that starting token (cleared by a logout, or replaced by
  another login/refresh), the attempt MUST return the current stored token
  (or nothing if storage was cleared) instead of writing the newly fetched
  tokens, and MUST only write the token bundle when storage still holds the
  unchanged starting token.
- **refresh-failure-adopts-concurrent-winner**: on a non-OK refresh response,
  if storage's current access token already differs from the one this
  attempt started with, the attempt MUST return that current token rather
  than clearing it.
- **refresh-failure-loser-recheck-delay**: on a non-OK refresh response with
  no immediately visible concurrent winner, the attempt MUST wait exactly
  300ms and re-read storage once before deciding, adopting a winner's token
  if one appeared during the wait.
- **refresh-failure-clears-when-unresolved**: if, after the loser-recheck
  wait, storage still holds the access token this attempt started with, and
  the generation counter has not changed, the attempt MUST clear the token
  bundle and resolve to nothing.
- **refresh-network-error-reports-and-clears**: a thrown network or parse
  error during a refresh attempt MUST be reported via unconditional error
  reporting (tagged with feature `'auth'`, step `'tokenRefresh'`), and MUST
  then clear the token bundle (subject to the same generation guard) and
  resolve to nothing.
- **authed-fetch-bearer-attach**: the authenticated request helpers MUST
  attach `Authorization: Bearer <token>` to the request whenever a stored
  access token is present.
- **authed-fetch-default-content-type**: the underlying request step MUST
  default a `Content-Type: application/json` header whenever a body is set
  and no `Content-Type` header was already supplied.
- **authed-fetch-default-init**: the authenticated request helpers MAY be
  called with no request-options argument; each MUST default it to an empty
  object rather than requiring the caller to pass one.
- **authed-fetch-401-refresh-retry-once**: on a `401` response, the base
  authenticated request helper MUST call the refresh operation exactly once
  and, if it resolves to a token, MUST retry the original request exactly
  once with that token; it MUST NOT call the refresh operation again or
  retry a second time if the retried request also fails.
- **authed-fetch-throws-on-non-ok**: the base authenticated request helper
  MUST throw a typed HTTP error — carrying the response's HTTP status and
  any machine-readable code extracted from the parsed JSON body — for any
  final non-OK response, after the one refresh-and-retry has already been
  attempted.
- **authed-json-rejects-204**: the JSON-parsing request helper MUST throw
  `Error('Unexpected empty response (204 No Content); use authedRequest for
  endpoints with no body')` when the response status is `204`.
- **authed-request-discards-body**: the body-discarding request helper MUST
  perform an authenticated request and resolve to nothing, discarding the
  response body.
- **auth-http-error-shape**: the typed HTTP error MUST behave as an error,
  MUST expose a numeric `status` and an optional string `code`, and MUST set
  its name to `'AuthHttpError'`.
- **extract-error-message-precedence**: error-message extraction (given a
  body and a fallback) MUST return, in order: a string top-level `error`;
  else a string `message` on a nested `error` object; else a string
  top-level `message`; else (RFC 9457 problem+json) `detail` when the body
  also has a string `title` and a numeric `status`; else a string `title`;
  else the fallback.
- **extract-error-code-precedence**: error-code extraction MUST return a
  string `code` from a nested `error.code`, else a top-level `code`, else
  nothing.
- **read-error-message-single-parse**: single-parse error-message reading
  MUST parse the response body exactly once and pass that single parsed
  value to error-message extraction.
- **exchange-sso-code-request-shape**: the SSO code exchange MUST `POST`
  `{ code }` as JSON to an exchange path, which MUST default to
  `'/api/oauth/signin/exchange'`.
- **exchange-sso-code-network-retry-once**: the SSO code exchange MUST retry
  the POST exactly once, after a 750ms delay, only when the first attempt
  fails at the network level (the request itself throws/rejects), and MUST
  propagate the second attempt's outcome — including a second network
  failure — without retrying again.
- **exchange-sso-code-no-http-retry**: the SSO code exchange MUST NOT retry
  when the server returns any HTTP response, including a non-OK one; only a
  network-level failure triggers the retry.
- **exchange-sso-code-success-result**: on a `2xx` response, the SSO code
  exchange MUST return `{ tokens, user }`, where `tokens` is built via token
  extraction and `user` is the response body's `user` field.
- **exchange-sso-code-failure-throws**: on a non-OK response, the SSO code
  exchange MUST throw a typed HTTP error carrying the status and the
  message/code extracted from the parsed body, with fallback message
  `'Sign-in failed'`.
- **link-provider-routes-to-as-host**: the provider-link request MUST
  resolve its target via AS endpoint resolution for `/auth/link-provider` —
  the authorization server directly, never a hard-coded same-origin path —
  falling back to `/api/auth/link-provider` only when no AS base is
  configured.
- **link-provider-authed-post**: the provider-link request MUST `POST` its
  input (`clientSlug`, `providerSlug`, `code`, `redirectUri`) as JSON through
  the body-discarding authenticated request helper (Bearer-authed, with the
  same one-refresh-then-retry waterfall as any other authenticated call), and
  MUST resolve on success or throw a typed HTTP error on failure.
- **retry-marker-hook**: the retry-marker hook MUST register a callback to be
  invoked with the exact request-options object handed to the underlying
  request step for a retried request — a post-refresh retry in the base
  authenticated request helper, or the network-failure retry in the SSO code
  exchange; passing nothing MUST unregister it, and with no callback
  registered, marking MUST be a silent no-op.
- **webauthn-assertion-ceremony-shared**: the shared WebAuthn assertion
  ceremony MUST `POST` a body to an options URL, throw using single-parse
  error-message reading on a non-OK response, otherwise run the platform's
  WebAuthn assertion ceremony with the returned options and return
  `{ token, response }`.
- **assert-second-factor-body**: the second-factor assertion MUST run the
  shared ceremony with body `{ token }` and fallback error `'Could not start
  the passkey check.'`.
- **assert-passwordless-passkey-body**: the passwordless-passkey assertion
  MUST run the shared ceremony with body `{ identifier }` and fallback error
  `'No passkey is available for this account.'`.
- **request-login-sms**: requesting a login SMS code MUST `POST` `{ token }`
  to a fixed same-origin SMS-send path and MUST throw on a non-OK response,
  with fallback message `'Could not send a code.'`.
- **complete-login-code**: completing login with a code MUST `POST`
  `{ token, method, code }` to `/api/auth/login/mfa` and return the parsed
  response on success, else throw with fallback `'That code didn't match.'`.
- **complete-login-passkey**: completing login with a passkey MUST run the
  second-factor assertion against a fixed same-origin WebAuthn-options path,
  then `POST` the resulting assertion to `/api/auth/login/mfa/webauthn`,
  returning the parsed response or throwing with fallback `'Passkey
  verification failed.'`.
- **passwordless-passkey-login**: passwordless passkey login MUST run the
  passwordless-passkey assertion against a fixed same-origin passkey-options
  path, then `POST` the resulting assertion to `/api/auth/login/webauthn`,
  returning the parsed response or throwing with fallback `'Passkey login
  failed.'`.
- **begin-login-navigation**: beginning login MUST be a no-op when no
  interactive host environment is present; otherwise it MUST stash a
  supplied return-to value when given and navigate the top-level view to the
  AS `/oauth/signin/authorize` URL for the given client id (default `'adh'`)
  and a return URL equal to `${origin}${callbackPath ?? '/auth/callback'}`.
- **authorize-url-shape**: building the authorize URL MUST resolve
  `/oauth/signin/authorize` via AS endpoint resolution and MUST include
  `clientId` and `return` query parameters, plus a `prompt` parameter only
  when one is given.
- **provider-signin-url-shape**: building the provider sign-in URL MUST
  resolve `/oauth/signin/start` via AS endpoint resolution with `clientId`,
  `providerId`, and `return` query parameters.
- **sso-hint-cookie-check**: the SSO-hint cookie check MUST return true if
  and only if a cookie named `adh_sso_hint` is present, and MUST return
  false when no interactive host environment is present.
- **sso-checked-guard-tolerates-storage-failure**: marking and clearing the
  once-per-tab restore guard MUST set/remove a fixed session-scoped flag
  (`adh_sso_checked`) and MUST swallow a thrown storage exception without
  propagating it.
- **silent-restore-guard-order**: the silent-restore decision MUST return
  false, checked in this order, when: no interactive host environment is
  present; the inbound fragment carries an SSO code/error (mid-flow); this
  tab has already checked; or no AS base is configured — all before any hint
  or cross-apex evidence is consulted.
- **silent-restore-evidence**: given none of the guards above apply, the
  silent-restore decision MUST return true when the SSO-hint cookie is
  present, and otherwise MUST return true if and only if the site is
  cross-apex with the configured AS host.
- **registrable-domain-apex-comparison**: the cross-apex comparison MUST
  compare the last two dot-separated labels of the AS host and the current
  hostname, treating them as different registrable domains if and only if
  those two-label suffixes differ.
- **preflight-sso-return-contract**: the silent-restore preflight check MUST
  `GET` the AS `/oauth/signin/preflight` endpoint (resolved via AS endpoint
  resolution) with `clientId` and `return` query parameters and credentials
  omitted, and MUST return true if and only if the response is OK and its
  parsed JSON body has `allowed === true`; any other outcome — non-OK,
  thrown/rejected request, or a body without `allowed === true` — MUST
  return false.
- **preflight-sso-return-timeout**: the silent-restore preflight check MUST
  bound its request with a 2000ms timeout when a runtime timeout primitive is
  available, and MUST proceed without one when it is not.
- **begin-silent-login-flow**: beginning a silent login attempt MUST return
  false without navigating when no interactive host environment is present;
  MUST always mark the once-per-tab restore guard first; MUST return false
  without navigating when no AS base is configured or when the silent-restore
  preflight check resolves false for the current URL; and, only when
  preflight allows it, MUST navigate the top-level view to the AS authorize
  URL with `prompt: 'none'` and a return URL equal to
  `${origin}${pathname}${search}` (dropping any existing fragment), returning
  true.
- **parse-inbound-sso**: parsing an inbound SSO fragment MUST return
  `{ code }` when the fragment has a `code` param, else `{ error }` when it
  has an `error` param, else nothing — including for an empty or absent
  fragment.
- **strip-sso-fragment-preserves-other-keys**: stripping the SSO fragment
  MUST remove only the `code` and `error` keys from the fragment, preserving
  every other key-value pair (e.g. a site-switch marker or scroll anchor) in
  its original order, and MUST return `''` when nothing remains.
- **sso-logout-navigation**: SSO logout MUST be a no-op when no interactive
  host environment is present; otherwise it MUST navigate the top-level view
  to the AS `/oauth/signin/logout` endpoint with `clientId` (default
  `'adh'`) and `return` (default `${origin}/`) query parameters.
- **sso-switch-url**: building a site-switch URL MUST return the destination
  URL unchanged when no AS base is configured, and otherwise MUST return a
  `prompt=none` authorize URL whose `return` parameter is the destination
  URL.
- **current-return-to**: the current return-to value MUST equal
  `${pathname}${search}${hash}` of the current location, and MUST return
  nothing when no interactive host environment is present.
- **safe-return-to-rejects-cross-origin**: the safe return-to check MUST
  return nothing for an absent/empty input or for a value that, resolved
  against the current origin, yields a different origin (an open-redirect
  defense that also refuses a protocol-relative `//evil.com/x` form), and
  otherwise MUST return only the resolved URL's `pathname + search + hash`,
  never the raw string.
- **stash-and-take-return-to-single-use**: stashing the return-to value MUST
  persist it in a session-scoped store under a fixed key, swallowing a
  thrown storage exception; taking the return-to value MUST read and remove
  that key (single use) and MUST return the result of the safe return-to
  check on the stored value, or nothing when no interactive host environment
  is present or a storage exception is thrown.
- **read-central-params**: reading relayed central-login parameters MUST
  return nothing when the query has no `return` parameter, and otherwise
  MUST return `{ clientId, returnUrl }` with `clientId` defaulting to
  `'adh'`.
- **central-login-target-resolution**: resolving the central-login target
  MUST return the AS-relayed `{ clientId, returnUrl }` unchanged (via
  reading relayed central-login parameters) when present; otherwise it MUST
  stash a supplied return-to value when given and synthesize
  `{ clientId, returnUrl: \`${origin}${callbackPath ?? '/auth/callback'}\` }`.
- **central-login-step-refuses-without-as-base**: a central-login step MUST
  throw, without making any network request, when no AS base is configured
  for the given target — it MUST NOT silently fall back to the same-origin
  proxy the way AS endpoint resolution does for other callers.
- **central-login-step-outcomes**: a central-login step MUST return the
  parsed MFA-challenge body on a `202` response; MUST navigate the top-level
  view to the response's `redirectUrl` and return nothing on any other OK
  response; and MUST throw a typed HTTP error (status + extracted
  message/code, with fallback `` `Server error (${status})` `` for a `5xx`
  and `'Login failed'` otherwise) on a non-OK, non-`202` response.
- **central-login-step-request-shape**: every central-login step POST MUST
  include credentials included and a JSON body merging the caller's fields
  with `clientId` and `return` (the target's return URL).
- **central-email-login**: central email/password login MUST `POST`
  `{ identifier, password }` (plus `clientId`/`return`) to
  `/oauth/signin/login` via a central-login step.
- **central-send-mfa-sms**: central SMS MFA send MUST `POST` `{ token }` to
  the SMS-send path on the AS and throw a typed HTTP error on a non-OK
  response, with fallback message `'Could not send a code.'`.
- **central-complete-mfa-code**: central MFA code completion MUST `POST`
  `{ token, method, code }` to `/oauth/signin/login/mfa` via a central-login
  step.
- **central-complete-mfa-passkey**: central MFA passkey completion MUST run
  the shared WebAuthn assertion ceremony against the AS's MFA options
  endpoint, then `POST` the assertion to `/oauth/signin/login/mfa/webauthn`
  via a central-login step.
- **central-passwordless-passkey**: central passwordless passkey login MUST
  run the passwordless assertion ceremony against the AS's passkey options
  endpoint, then `POST` the assertion to `/oauth/signin/login/webauthn` via a
  central-login step.
- **begin-link-provider-csrf-nonce**: beginning a provider-link MUST
  generate a random nonce, MUST stash it in a session-scoped store under a
  fixed key BEFORE navigating, and MUST return false without navigating when
  the nonce cannot be stashed; otherwise it MUST navigate the top-level view
  to the AS `/oauth/signin/start` URL with `link=1`, `clientId`,
  `providerId`, `return`, and `linkNonce` query parameters, returning true.
- **mfa-status-fetch**: fetching MFA status MUST `GET` `/api/account/mfa`
  through the JSON-parsing authenticated request helper and return the
  parsed MFA-status body.
- **totp-enroll**: enrolling TOTP MUST `POST` `/api/account/mfa/totp/enroll`
  through the JSON-parsing authenticated request helper and return
  `{ secret, otpauthUri }`.
- **totp-confirm**: confirming a TOTP code MUST `POST` `{ code }` to
  `/api/account/mfa/totp/confirm` through the JSON-parsing authenticated
  request helper.
- **totp-remove**: removing TOTP MUST `DELETE` `/api/account/mfa/totp`
  through the body-discarding authenticated request helper.
- **webauthn-list**: listing WebAuthn credentials MUST `GET`
  `/api/account/mfa/webauthn` through the JSON-parsing authenticated request
  helper and return `{ items }`.
- **webauthn-register-ceremony**: registering a WebAuthn credential MUST
  `POST` `{ kind }` to `/api/account/mfa/webauthn/register/options` through
  the JSON-parsing authenticated request helper, run the platform's WebAuthn
  registration ceremony with the returned options, then `POST`
  `{ token, response, name }` to `/api/account/mfa/webauthn/register/verify`
  through the JSON-parsing authenticated request helper.
- **webauthn-remove**: removing a WebAuthn credential MUST `DELETE`
  `` `/api/account/mfa/webauthn/${encodeURIComponent(id)}` `` through the
  body-discarding authenticated request helper.
- **recovery-codes-regenerate**: regenerating recovery codes MUST `POST`
  `/api/account/mfa/recovery/regenerate` through the JSON-parsing
  authenticated request helper and return `{ codes }`.
- **preferred-method-set**: setting the preferred MFA method MUST `PUT`
  `{ method }` to `/api/account/mfa/preference` through the JSON-parsing
  authenticated request helper and return `{ preferredMethod }`.
- **account-security-authed**: every account-security operation MUST go
  through the JSON-parsing or body-discarding authenticated request helper —
  Bearer-authed, with the same one-refresh-then-retry-on-401 waterfall as any
  other authenticated call — never a bare, unauthenticated request.
- **report-unexpected-status-gate**: unexpected-error reporting MUST NOT
  report (to the injected sink or the console) an error whose numeric status
  (duck-typed off any thrown error, not just this contract's own typed HTTP
  error) is less than 500 — an expected 4xx from either this contract's or a
  host's own error type.
- **report-unexpected-dedup-window**: unexpected-error reporting MUST report
  at most once per exact `` `${message}|${JSON.stringify(context)}` ``
  signature per 60000ms window, dropping duplicate reports of the same
  signature within that window.
- **report-auth-error-unconditional**: unconditional error reporting MUST
  call the injected reporter (if one is registered) and MUST always log the
  error to the console, regardless of the error's status.
- **report-never-throws**: unconditional error reporting MUST swallow any
  exception thrown by the injected reporter and MUST NOT propagate it to the
  caller.
- **set-auth-error-reporter-hook**: the error-reporter hook MUST register a
  callback as the sink error reporting calls; passing nothing MUST
  unregister it, leaving console-only reporting.
- **provider-label-known-and-fallback**: the provider label lookup MUST
  return `'GitHub'` for `'github'`, `'Google'` for `'google'`, and otherwise
  the slug with only its first character capitalized.
- **oauth-error-message-known-codes-and-fallback**: the OAuth error message
  lookup MUST return a fixed message for `'account_exists'`,
  `'user_not_found'`, and `'signups_closed'`; MUST return a fixed
  login-disabled body for `'login_disabled'`; and MUST otherwise return the
  code verbatim inside `` `Sign-in failed (${code})` ``.
- **link-copy-provider-substitution**: every account-linking modal copy
  function MUST substitute the provider label lookup's result for the given
  provider slug into its returned string.

### Security

This recipe is a security-relevant recipe: it handles bearer session tokens,
a cookie-based refresh mechanism, second-factor secrets, WebAuthn ceremonies,
and cross-site redirect targets. The following requirements are this
recipe's dedicated security treatment; each restates or cross-references a
requirement above under its security framing rather than duplicating its
mechanics.

- **sensitive-data-classification**: The following are sensitive within this
  contract: the access token (bearer credential), the deliberately-never-read
  refresh token, the cached user record, TOTP secrets/`otpauthUri`, WebAuthn
  registration/assertion payloads, recovery codes, the CSRF link nonce, and
  the return-to path (open-redirect surface via
  **safe-return-to-rejects-cross-origin**).
- **access-token-transmission**: The access token MUST be attached only via
  the `Authorization: Bearer` header (**authed-fetch-bearer-attach**) and
  MUST NEVER appear in a URL query string, a log message, or an error
  report's context value (the error-report context type is explicitly
  scalars-only — see **report-unexpected-status-gate**).
- **refresh-token-never-persisted**: The refresh token MUST NOT be read from
  a backend response or written to any client-side store —
  **tokens-from-response-refresh-token-blanked** always blanks it to `''`;
  refresh and revoke are cookie-first against an HttpOnly, server-controlled
  cookie this recipe never reads.
- **open-redirect-violation-handling**: A stashed or query-supplied
  return-to value that resolves to a different origin MUST be rejected
  outright (returned as nothing), never partially trusted or redirected to —
  see **safe-return-to-rejects-cross-origin**.
- **link-csrf-violation-handling**: A provider-link completion MUST be
  refused (fails closed, no navigation) when its CSRF nonce cannot be
  stashed before the redirect — see **begin-link-provider-csrf-nonce**; a
  completion callback whose returned nonce does not match the stashed one is
  rejected by the completing consumer (outside this recipe's own logic, but
  the nonce this recipe mints and stashes is the entire defense).
- **token-subject-not-an-authorization-decision**: The unverified, locally
  decoded subject claim read by **read-token-subject-derivation** MUST be
  used only for client-side cache scoping (keying cached data to the current
  principal so an account switch in another tab cannot serve stale rows) and
  MUST NEVER be used as an authorization decision — the token is not
  signature-verified client-side.

