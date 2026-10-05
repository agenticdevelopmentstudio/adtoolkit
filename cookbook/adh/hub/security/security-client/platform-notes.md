
- **React/Web** (source platform): `packages/web/packages/data/src/security/tokens.ts` and
  `bucket-access.ts` hold the two clients; `wire.ts` holds their shared wire shapes; `index.ts`
  re-exports all three as the package's public surface. Both clients are built entirely on
  `authedJson`/`authedRequest` from `@agentic-toolkit/auth/client` (re-exported through `./http`) and
  `enc` (`encodeURIComponent`) from `./client-helpers`; `tokens.ts` alone calls the global
  `encodeURIComponent` directly rather than the `enc` alias, per `token-revoke-request-shape`.
- **SwiftUI**: a Swift port already exists for this exact backend surface —
  `packages/apple/AgenticToolkit/Hub/Features/Authentication/ApiTokensRail.swift` and
  `AccessListsTopic.swift` (documented in the sibling `auth-client-authentication` recipe) — and models
  the wire rows as `Codable, Sendable` structs and each client as an `@MainActor final class` exposing
  `async throws` methods over an injected data-source protocol, with a `HubError` in place of
  `AuthHttpError`. A fresh port of these two TypeScript files specifically should follow that existing
  pattern rather than introduce a second one.
- **AppKit / UIKit**: no direct UI dependency exists in either TypeScript file; consuming code reaches
  the ported client through an injected data-source protocol (`ApiTokensDataSource`,
  `BucketAccessDataSource` in the existing Swift port), never by calling `URLSession` from the view
  layer directly.
- **Compose**: model the six wire rows (`ApiToken`, `ApiTokenCreated`, `AccessGroup`,
  `AccessGroupMember`, `AccessGrant`, `AccessGroupDetail`) as Kotlin `data class`es annotated
  `@Serializable`, and each client as a class exposing `suspend fun` equivalents built on Ktor or
  OkHttp, with a sealed error type carrying the HTTP status and optional code in place of
  `AuthHttpError`.
- **WinUI 3**: a .NET port would model the wire rows as `record`s attributed for
  `System.Text.Json`, and `TokensApi`/`BucketAccessApi` as classes exposing `Task<T>`-returning methods
  built on `HttpClient`, attaching `Authorization: Bearer <token>` the way `authedFetch` does and
  refreshing on a `401` the same one-retry way, with an `ApiException` (status, code) parallel to
  `AuthHttpError`. This is the platform with the least existing prior art in this repo for that
  refresh-and-retry contract — as with the sibling `hub-domain-access` recipe's `accessApi`, a WinUI 3
  port would need to build the equivalent of `authedFetch` itself before either client can be ported,
  including its own single-refresh-then-retry-on-401 waterfall.

