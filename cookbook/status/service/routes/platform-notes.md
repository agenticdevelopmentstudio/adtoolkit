
- **TypeScript / Node (source)**: the routes are `Hono`/`OpenAPIHono`
  sub-apps composed by factory functions taking `storage`/`config`/
  `scheduler` as explicit parameters (dependency injection over module-level
  singletons), validated with Zod, and returning either a JSON body, an SSE
  `ReadableStream`, or an SVG string.
- **Swift (SwiftUI/AppKit/UIKit hosts)**: a client consuming this contract
  polls `/live`, `/snapshot`, or `/status` on a timer or subscribes to
  `/live/stream` via `URLSession`'s bytes-streaming API to parse SSE frames
  incrementally; the device-authorization flow (`/auth/device` →
  `/auth/device/token` polling) maps naturally onto an `AsyncSequence`-driven
  poll loop with the same `slow_down`/`authorization_pending` back-off
  handling the route itself expects.
- **Kotlin (Jetpack Compose hosts)**: the same SSE stream is consumed via
  OkHttp's `EventSource` (or a manual chunked-response reader) feeding a
  `StateFlow`; the device-flow poll loop is a `Flow` emitting on
  `POLL_INTERVAL_SEC` with the same three-state RFC 8628 error handling.
- **C# / WinUI 3**: a WinUI 3 host is a *client* of this contract, not a
  reimplementation of the server — it would use `HttpClient` for the
  JSON endpoints, `System.Text.Json` for (de)serializing the same DTOs this
  file returns, and a background `Task` looping on `HttpClient.GetAsync`
  against `/live/stream`'s chunked response (or a `System.Net.Http`
  SSE-parsing helper) to feed an `ObservableCollection`/`INotifyPropertyChanged`-
  backed view model, mirroring the subscribe-then-render-opening-frame
  ordering this route enforces server-side. A minted device-flow or API
  token would be persisted client-side via `Windows.Storage`'s credential
  vault, never in a plain settings file. If this route layer itself were
  ever reimplemented on .NET (not just consumed), the Hono
  route-factory/middleware-chain shape maps onto ASP.NET Core minimal APIs
  or controllers for routing, `System.Text.Json` + `FluentValidation` (or
  `DataAnnotations`) in place of Zod, `IHostedService`/`HttpResponse`
  streaming in place of the SSE `ReadableStream`, `HMACSHA1` from
  `System.Security.Cryptography` for the Vercel webhook signature, ASP.NET
  Core's rate-limiting middleware in place of `rateLimit`, and ASP.NET Core
  Identity plus a custom bearer-token `AuthenticationHandler` in place of the
  cookie/session/token middleware chain.
- **Web client**: the dashboard's own frontend is the reference client —
  it opens `EventSource`/`fetch`-based SSE against `/live/stream`, polls
  `/auth/device/token` during device-flow sign-in, and treats every
  `HTTPException` response's `{ error: { message } }` envelope uniformly.

