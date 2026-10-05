
- **React/Web** (source platform): the three files live under
  `packages/web/packages/status-server/src/mcp/`, on top of
  `@modelcontextprotocol/sdk` (`McpServer`, `StreamableHTTPServerTransport`),
  Hono (`OpenAPIHono`, `HttpBindings`), `@hono/node-server`'s
  `RESPONSE_ALREADY_SENT` response-passthrough utility, and `zod` for every
  tool's `inputSchema`/parse pair. The `Storage` port and the
  `buildSnapshot`/`boardProblems`/etc. read-service functions these tools
  delegate to live in sibling directories and are not part of this
  recipe's sources.
- **SwiftUI / AppKit / UIKit**: an Apple client of this backend is a
  consumer, not a re-implementer, of this MCP surface — an MCP-capable
  agent host (not this product's own UI layer) would speak Streamable HTTP
  to `/mcp` via an MCP client SDK, attaching the same session cookie or
  `sts_` bearer `status-server-auth` documents. A future Apple-side
  re-implementation of this SERVER logic (a companion Swift backend, e.g.
  Vapor or Hummingbird) would model each `McpTool` as a Swift `struct`
  conforming to a small protocol (`name`, `description`, `readOnly`,
  `adminOnly`, and an `execute(_:_:_:) async throws -> Any`), with the
  tool catalog built once at startup and `selectTools(tier:)` filtering it
  per request exactly as `tools.ts` does.
- **Compose**: same client relationship as SwiftUI/AppKit/UIKit — an
  Android agent host would speak the same Streamable-HTTP protocol
  (OkHttp/Retrofit for the transport); it has no server-side tool surface
  to port.
- **WinUI 3**: a WinUI 3 desktop app is likewise a client, not a
  reimplementer. If a future product needed to reimplement this MCP
  tool-surface pattern on a .NET backend (ASP.NET Core Minimal API), the
  mapping is concrete: the `ModelContextProtocol` NuGet package's
  `McpServerTool`-attributed methods (or its builder API) replace the
  `McpTool` array and `registerTool` loop; each tool's zod `inputSchema`
  maps to a `System.Text.Json`-serializable request record validated with
  `FluentValidation` or `DataAnnotations` in place of `.parse()`; the
  two-layer fail-closed gate maps to an ASP.NET Core authorization filter
  reading a `Tier` claim off `HttpContext.User` for layer 1 (tool
  registration/`Endpoint` filtering per tier) and an explicit
  `if (tier != Tier.Admin) return Forbid(...)` re-check inside each
  admin-gated tool's handler body for layer 2, mirroring
  `mcp-registers-tier-set-only`/`mcp-handler-recheck` exactly; the
  success/failure JSON envelope (`ok`/`fail`) is a small `record` type
  serialized the same way for every tool response.

