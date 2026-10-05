
- **React/Web** (source platform): `packages/web/packages/auth/src/server/proxy.ts`
  holds `resolveBackendUrl`, `proxyToBackend`, and `makeProxyHandlers`;
  `server/index.ts` re-exports all three. A consuming site wires it from a
  catch-all Next.js App Router Route Handler,
  `app/<prefix>/[...path]/route.ts`:
  ```
  import { makeProxyHandlers } from '@agentic-toolkit/auth/server'
  export const dynamic = 'force-dynamic'
  export const { GET, POST, PUT, PATCH, DELETE } = makeProxyHandlers('api')
  ```
  exporting `dynamic = 'force-dynamic'` and the five methods
  `makeProxyHandlers` returns. `ctx.params` is a `Promise` in this router,
  which is why the generated handlers `await` it. The module is built on
  the Fetch API's `Request`/`Response`/`Headers`, and specifically works
  around OpenNext-on-Cloudflare-Workers' default `redirect: 'follow'`
  behavior and Node `undici`'s transparent gzip decoding — both named in the
  file's own comments. Vercel sites that proxy via `next.config` rewrites
  don't need this module at all.
- **SwiftUI / AppKit / UIKit**: these are client UI frameworks with no
  server-rendered page needing a BFF; a native app on these platforms talks
  to the backend directly with `URLSession`, attaching its own bearer token
  or session cookie, rather than replaying this pattern. This module's
  reason for existing — working around a serverless edge runtime's forced
  redirect-following and content-encoding relabeling — has no client-side
  analogue on these platforms.
- **Compose**: same reasoning as SwiftUI/AppKit/UIKit — an Android app calls
  the backend directly (e.g. via OkHttp/Retrofit) with its own auth header;
  it has no Route Handler layer to port this file into.
- **WinUI 3**: a WinUI 3 desktop app has no server-rendered pages and so no
  need for a Next.js-style BFF; it would call the backend directly with
  `HttpClient`, attaching `Authorization: Bearer <token>` from wherever the
  app stores it, and parsing responses with `System.Text.Json`.
  `HttpClientHandler`'s default redirect-following does not exhibit the
  Set-Cookie-dropping bug this file works around, so no `AllowAutoRedirect =
  false` equivalent is needed on that platform. If a future WinUI 3 product
  ever grows a companion ASP.NET Core BFF for its own web surface, the
  analogue of `proxyToBackend`/`makeProxyHandlers` would be an
  `IHttpForwarder` (YARP) or hand-rolled `HttpClient`-based middleware in
  `Microsoft.AspNetCore.Http`, explicitly setting
  `HttpClientHandler.AllowAutoRedirect = false` to preserve `Set-Cookie` the
  same way `redirect: 'manual'` does here, and forcing `Accept-Encoding:
  identity` upstream if that host's HTTP client exhibits the same
  transparent-decode-but-relabel behavior as Node's `undici`.

