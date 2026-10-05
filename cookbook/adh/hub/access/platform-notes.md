
- **React/Web** (source platform): `packages/web/packages/data/src/access/access.ts` and
  `wire.ts` hold the client; `accessApi` is built entirely on `authedJson`/`authedRequest`
  from `@agentic-toolkit/auth/client` (re-exported through `./http`) and `enc`
  (`encodeURIComponent`) from `./client-helpers`; `index.ts` re-exports both files as the
  package's public surface for the rest of the web app. The wire row types are
  `AccessFeatureRow`, `AccessGrantRow`, `AccessRoleRow`, `AccessAssignmentRow`,
  `EffectiveAccessRow`; the write input types are `AccessRoleInput` and
  `AccessAssignmentInput`; the fallback feature list is exported as `ACCESS_FEATURES`. The
  ten operations are named `listFeatures`, `listRoles`, `createRole`, `updateRole`,
  `deleteRole`, `listAssignments`, `putAssignment`, `deleteAssignment`, `restrictItem`,
  `restoreItem`, and `effective`. `updateRole`'s patch parameter is typed
  `Partial<Omit<AccessRoleInput,"slug">>`, which is where "slug is excluded" is enforced, at
  compile time, in this implementation. Errors are thrown as `AuthHttpError` (status +
  optional code), extracted via `extractErrorCode`/`extractErrorMessage` in
  `auth/src/client.ts`; the one-retry-on-401 refresh waterfall and token attachment live in
  `authedFetch`/`readAccessToken`/`refreshAccessToken` in that same file. The duck-typed
  status-extraction helper is `httpStatus()` in `http.ts`; write bodies rely on
  `JSON.stringify`'s omission of `undefined` keys rather than calling the `compact()` helper
  also in `client-helpers.ts`.
- **SwiftUI**: a Swift port would model `AccessFeatureRow`/`AccessGrantRow`/`AccessRoleRow`/
  `AccessAssignmentRow`/`EffectiveAccessRow` as `Codable, Hashable, Sendable` structs,
  mirroring the pattern the sibling Hub authentication recipe's `AuthenticationModels.swift`
  already uses, and `accessApi` as an `actor` or `@MainActor final class` exposing `async
  throws` functions built on `URLSession`, with a dedicated error type carrying the HTTP
  status and an optional machine code in place of `AuthHttpError`.
- **AppKit / UIKit**: no direct UI dependency exists in this module; a macOS/iOS Hub feature
  would consume the ported client through an injected data-source protocol — the same
  pattern `ApiTokensRail`/`AccessListsTopic` already use for their own data sources — rather
  than calling `URLSession` from the view layer.
- **Compose**: model the five wire rows as Kotlin `data class`es annotated `@Serializable`,
  and `accessApi` as a class exposing `suspend fun` equivalents built on Ktor or OkHttp, with
  a sealed error type carrying the HTTP status and optional code.
- **WinUI 3**: a .NET port would model the wire rows as `record`s attributed for
  `System.Text.Json`, and `accessApi` as a class exposing `Task<T>`-returning methods built
  on `HttpClient`, attaching `Authorization: Bearer <token>` the way this module's
  `authedFetch` does, refreshing on a `401` the same one-retry way, and defining an
  `AccessApiException` (status, code) parallel to `AuthHttpError` — this is the platform
  with the least existing prior art in this repo for that refresh-and-retry contract, so the
  WinUI 3 port would need to build the equivalent of `authedFetch` itself, not only
  `accessApi`.

