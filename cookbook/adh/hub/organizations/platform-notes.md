
- **React/Web** (source platform): `packages/web/packages/data/src/organizations/organizations.ts`,
  `members.ts`, and `wire.ts` hold the client; every method is a plain async function over
  `authedJson`/`authedRequest` (`@agentic-toolkit/auth/client`, re-exported through `./http`) and
  `enc`/`compact` from `./client-helpers`; `index.ts` re-exports both files as the package's public
  surface (`@agentic-toolkit/data/organizations`). The organizations cache-key prefix is exported
  as `ORGANIZATIONS_QUERY_KEY`, the one-element tuple `["organizations"]`, in the react-query
  key-array convention; a caller appends the workspace slug (`[...ORGANIZATIONS_QUERY_KEY, slug]`)
  to form a complete key. `wire.ts` also exports `OrganizationRenamed`, a type alias of
  `Organization` re-exported by `organizations.ts`; `organizationsApi.rename`'s declared return
  type deliberately stays `Organization`, never that alias — a TypeScript-only distinction with no
  runtime or wire effect.
- **SwiftUI**: a Swift port would model `Organization`/`OrganizationListRow`/
  `OrganizationCreateInput`/`OrganizationProvisioned`/`OrganizationRenameInput`/
  `OrganizationRestored`/`WorkspaceMember`/`WorkspaceMembersResponse` as `Codable, Hashable,
  Sendable` structs, mirroring the pattern the sibling Hub Ecosystems/Access recipes' Apple models
  already use, and `organizationsApi`/`workspaceMembersApi` as an `actor` or `@MainActor final
  class` exposing `async throws` functions built on `URLSession`, with a dedicated error type
  carrying the HTTP status and an optional machine code in place of `AuthHttpError`.
- **AppKit / UIKit**: no direct UI dependency exists in either module; a macOS/iOS Hub feature
  would consume the ported client through an injected data-source protocol — the same pattern the
  sibling `EcosystemsDataSource` already uses — rather than calling `URLSession` from the view
  layer.
- **Compose**: model the eight wire shapes as Kotlin `data class`es annotated `@Serializable`, and
  `organizationsApi`/`workspaceMembersApi` as classes exposing `suspend fun` equivalents built on
  Ktor or OkHttp, with a sealed error type carrying the HTTP status and optional code.
- **WinUI 3**: `HttpClient` with `System.Text.Json` replaces `fetch`/`URLSession` for every
  organizations/roster request this recipe documents. A `ContentDialog` hosting
  `Microsoft.UI.Xaml.Controls` (`TextBox` for `slug`/`name`, a multi-line `TextBox` for
  `description`) is the equivalent of a create/rename form, and a second `ContentDialog` with a
  destructive-styled primary button is the equivalent of an archive-confirmation flow a host would
  build around `archive(id)`. `Task`/`async`-`await` replaces every `Promise` call; a custom
  `AccessApiException`-equivalent exception (status, code) should carry the same conflict-versus-
  not-found distinctions this recipe's error-mapping requirements rely on — and, per
  `organization-restore-conflict-status-based`, a WinUI port MUST keep `restore`'s conflict
  detection status-code-based rather than message-text-based, since the backend's 409 wording
  differs between the create/rename routes and the restore route.

