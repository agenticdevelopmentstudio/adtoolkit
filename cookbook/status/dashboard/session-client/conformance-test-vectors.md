
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-web-src-001 | auth-me-user-resolves (see Platform Notes) | the session-fetch function called with a default API client and a transport that resolves HTTP 200 with body `{"user":{"email":"a@b.c","displayName":"A","role":"admin"}}` | resolves to a user with `email: "a@b.c"`, `displayName: "A"`, `role: "admin"` |
| status-web-src-002 | auth-me-signed-out-resolves-null (see Platform Notes) | the session-fetch function called with a transport that resolves HTTP 200 with body `{"user":null}` | resolves `null` |
| status-web-src-003 | auth-me-non-ok-throws (see Platform Notes) | the session-fetch function called with a transport that resolves HTTP 500 with body `{}` | rejects with an error whose message is exactly `auth/me unavailable (HTTP 500)` |
| status-web-src-004 | auth-me-network-failure-propagates (see Platform Notes) | the session-fetch function called with a transport that rejects with a runtime error whose message is `fetch failed` | rejects with that same error (message `fetch failed`) |
| status-web-src-005 | auth-me-signed-out-resolves-null | the session-fetch function called with a transport that resolves HTTP 200 with body `{}` | resolves `null` (`user` absent reads as signed-out) |
| status-web-src-006 | auth-me-non-ok-throws | the session-fetch function called with a transport that resolves HTTP 401 with body `{"user":null}` | rejects with `auth/me unavailable (HTTP 401)`; never resolves `null` |
| status-web-src-007 | auth-me-url, auth-me-transport | the session-fetch function called with an API client configured with base path `/proxy`, and a recording transport | the transport is called once with the single argument `"/proxy/auth/me"` and no request-options object |
| status-web-src-008 | auth-me-body-parse-failure-propagates | the session-fetch function called with a transport that resolves HTTP 200 with a body that is not valid JSON | rejects with the body-parsing error |
| status-web-src-009 | session-query-key | reading the session query key | deep-equals the pair `["status-auth-me"]` |
| status-web-src-010 | header-signed-out-state, header-loading-spinner | the header-auth hook, when the session hook yields `user: null` and `isPending: true` | returns `user: null`, `authLoading: true`, `loginHref: "/login"`, `signupHref: "/signup"` |
| status-web-src-011 | header-signed-out-state | the header-auth hook, when the session hook yields `user: null` and `isPending: false` | returns `user: null`, `authLoading: false`, `loginHref: "/login"`, `signupHref: "/signup"` |
| status-web-src-012 | header-signed-in-name, header-signed-in-fields | the header-auth hook, when the session hook yields a user with `email: "a@b.c"`, `displayName: "Ann"`, `role: "viewer"` | returns `user: { name: "Ann" }`, an `onLogout` callback, and no `authLoading`/`loginHref`/`signupHref` keys |
| status-web-src-013 | header-signed-in-name | the header-auth hook, when the session hook yields a user with `email: "a@b.c"`, `displayName: ""`, `role: "viewer"` | `user.name` equals `"a@b.c"` |
| status-web-src-014 | header-signed-in-name | the header-auth hook, when the session hook yields a user with `email: "a@b.c"`, `displayName: null`, `role: "admin"` | `user.name` equals `"a@b.c"` |
| status-web-src-015 | logout-request, logout-navigation | invoking `onLogout` in a signed-in state with the default client, when the request resolves HTTP 200 | one `POST` request to `/api/auth/logout`; afterwards the page navigates to `/` |
| status-web-src-016 | logout-navigation, logout-outcome-ignored | invoking `onLogout` as above, when the request resolves HTTP 500 | the page still navigates to `/`; no error thrown synchronously; the session query key is not invalidated |
| status-web-src-017 | logout-navigation, logout-rejection-unhandled | invoking `onLogout` as above, when the request rejects | the page still navigates to `/`; an unhandled rejection carrying that error is raised |
| status-web-src-018 | session-kept-across-errors | the session hook, with a cached user and a refetch whose four attempts all reject with HTTP 503 | still returns that cached user with `isPending: false` |
| status-web-src-019 | session-query-dedupe | two consumers of the session hook mounting together in the same render with an empty cache | exactly one `/auth/me` request is issued |
| status-web-src-020 | session-query-config | the session hook on first load, when every attempt rejects | `/auth/me` is attempted 4 times (the initial attempt plus 3 retries) before the query settles into an error state |

The wire-DTO requirements above are compile-time shapes with no runtime behavior; a port verifies them with type-level assertions (for example, assigning `"unknown"` to a day's uptime record's `status` field MUST fail to compile, while assigning it to a service status record's `status` field MUST compile) rather than runtime vectors.

