
- **React/Web** (source platform): the five files live under
  `packages/web/packages/status-server/src/auth/`, on top of Hono
  (`hono/cookie`, `hono/http-exception`, `hono/utils/cookie`) and Node's
  built-in `node:crypto` (`randomBytes`, `timingSafeEqual`) and global
  `fetch`/`AbortSignal.timeout`. Password hashing uses the `bcryptjs`
  package. The Hono binding that turns an `AuthGate` resolution into an
  HTTP response (`requireAuth`/`requireAdmin`) lives one directory over, in
  `../middleware/auth`, and is not part of this recipe's sources.
- **SwiftUI / AppKit / UIKit**: an Apple client of this backend is a
  consumer, not a re-implementer, of this auth layer — it calls the status
  API with `URLSession`, attaching the session cookie (via
  `HTTPCookieStorage`) or an `sts_` bearer token in an `Authorization`
  header exactly as `default-adapter.ts` expects to receive it. A future
  Apple-side re-implementation of this SERVER logic (a companion Swift
  backend, e.g. Vapor or Hummingbird) would model `AuthGate` as a Swift
  `protocol` with an `async throws` `authenticate(_:) -> AuthVars?` method,
  `AuthVars`/`AuthUser`/`TokenPrincipal` as `Sendable` `struct`s, the
  constant-time peer-token compare via `CryptoKit`'s
  constant-time byte comparison (or a hand-rolled loop, since Foundation has
  no direct `timingSafeEqual` equivalent), and password hashing via a
  bcrypt Swift package at the same cost factor 10.
- **Compose**: same client relationship as SwiftUI/AppKit/UIKit — an
  Android client calls the backend directly (OkHttp/Retrofit), attaching
  its own cookie jar or bearer header; it has no server-side gate to port.
- **WinUI 3**: a WinUI 3 desktop app is likewise a client, calling the
  status API with `HttpClient` and attaching `Authorization: Bearer
  <sts_ token>` or forwarding the session cookie via
  `HttpClientHandler.CookieContainer`. If a future product needed to
  reimplement this AuthGate pattern on a .NET backend (ASP.NET Core Minimal
  API), the port maps as: the `AuthGate` interface becomes a C# interface
  `Task<AuthVars?> AuthenticateAsync(HttpRequest req)`; the session cookie
  is set with `CookieOptions { HttpOnly = true, Secure = config.CookieSecure,
  SameSite = SameSiteMode.Lax, Path = "/", MaxAge = TimeSpan.FromDays(30) }`;
  the `PEER_TOKEN` constant-time compare uses
  `CryptographicOperations.FixedTimeEquals` over two equal-length byte
  spans (matching `safeEqual`'s length-then-timing-safe-compare shape);
  password hashing uses `BCrypt.Net-Next` at work factor 10; and the GitHub
  OAuth exchange is a hand-rolled `HttpClient` POST/GET sequence (no
  built-in GitHub SDK), reusing `System.Text.Json` for the token/profile
  response shapes and `HttpClient`'s per-request `CancellationToken`
  (mapped from a `TimeSpan`) as the `AbortSignal.timeout` analogue.

