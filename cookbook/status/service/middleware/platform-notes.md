
- **React/Web** (source platform): both files live under
  `packages/web/packages/status-server/src/middleware/`, on top of Hono
  (`hono/factory`'s `createMiddleware`, `hono/http-exception`) and plain
  JavaScript `Map`/`Date.now()` for the rate limiter — no external rate-limit
  or auth-middleware package is used. `requireAuth`/`requireAdmin` are typed
  against Hono's `MiddlewareHandler<{ Variables: ... }>` generic; `rateLimit`
  returns a plain `MiddlewareHandler`.
- **SwiftUI / AppKit / UIKit**: an Apple client of this backend is a
  consumer, not a re-implementer, of this middleware — it calls the status
  API with `URLSession` and reacts to the status codes these files produce
  (`401`/`403` by re-authenticating or hiding admin UI, `429` by reading the
  `Retry-After` header and backing off before its next attempt, per
  `URLResponse`'s HTTP header access). A future Apple-side re-implementation
  of this SERVER logic (a companion Swift backend, e.g. Vapor or
  Hummingbird) would model `requireAuth`/`requireAdmin` as async
  middleware/route-group guards throwing a typed HTTP error, and the rate
  limiter as a `Sendable` actor wrapping a `Dictionary` keyed the same way,
  guarded by the actor's own serialized access instead of JavaScript's
  single-threaded event loop.
- **Compose**: same client relationship as SwiftUI/AppKit/UIKit — an
  Android client calls the backend directly (OkHttp/Retrofit) and reacts to
  the same status codes and `Retry-After` header; it has no server-side
  middleware to port. A Kotlin backend re-implementation (Ktor) would use
  `Route.install`/an `ApplicationCall` interceptor for the auth guards and
  Ktor's own `RateLimit` plugin (or a hand-rolled `Mutex`-guarded map) for
  the limiter.
- **WinUI 3**: a WinUI 3 desktop app is likewise a client, calling the
  status API with `HttpClient` and reading `HttpResponseMessage.Headers.RetryAfter`
  after a `429` before its next attempt, and reacting to `401`/`403` by
  redirecting to sign-in or disabling admin-only commands. If a future
  product needed to reimplement this exact middleware pattern on a .NET
  backend (ASP.NET Core Minimal API), `requireAuth`/`requireAdmin` map to
  authentication/authorization middleware and an `IAuthorizationHandler`
  checking a claim equivalent to `tier`, both throwing (or short-circuiting
  to) the matching status via `HttpContext.Response`; `rateLimit` maps
  directly onto the built-in `Microsoft.AspNetCore.RateLimiting` middleware,
  configured with a `PartitionedRateLimiter<HttpContext>` partitioned by the
  same rightmost-`X-Forwarded-For`-hop key and a `FixedWindowRateLimiterOptions`
  matching `opts.max`/`opts.windowMs`, which already emits a `Retry-After`
  header on rejection the same way this source does by hand.

