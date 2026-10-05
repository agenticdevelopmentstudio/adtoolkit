
- **React/Web** (source platform): `packages/web/packages/data/src/integrations/integrations.ts` and
  `wire.ts` hold the client; `integrationsApi` and the standalone OAuth-state helpers are built entirely on
  `authedJson`/`authedRequest` from `@agentic-toolkit/auth/client` (re-exported through `./http`) and `enc`
  (`encodeURIComponent`) from `./client-helpers`; `index.ts` re-exports both files as the package's public
  surface. Requirement/operation names in this recipe map onto the module's own exports as follows:
  listing providers → `listProviders`; listing/getting/saving/deleting a provider config by provider id →
  `listProviderConfigs`/`getProviderConfig`/`putProviderConfig`/`deleteProviderConfig`; creating/getting/
  updating/deleting a provider config by id → `createProviderConfig`/`getProviderConfigById`/
  `updateProviderConfig`/`deleteProviderConfigById` (their shared URL template is built by two private
  helpers, `configPath`/`configByIdPath`, see Design Decisions); testing a saved config / draft
  credentials → `testProviderConfig`/`testProviderCredentials`; transferring a config →
  `transferProviderConfig`; rotating a webhook secret → `rotateWebhookSecret`; listing/connecting/
  disconnecting/syncing/patching settings for connections → `listConnections`/`connect`/`disconnect`/
  `sync`/`patchSettings`; the OAuth/install/instance/link-token start endpoints → `getAuthUrl`/
  `getInstallUrl`/`adoptInstallations`/`registerInstance`/`createLinkToken`; the callback path/URL and
  state-claim helpers → `OAUTH_CALLBACK_PATH`/`oauthCallbackUrl`/`decodeOAuthStateClaims`/
  `isOAuthStateFresh`. Wire types referenced generically above (a "provider config record", a
  "connection record", a "test-result record", etc.) are `MaskedProviderConfig`/`SafeConnection`/
  `IntegrationTestResult`, and the connect-request's six variants are the `ConnectRequestBody`
  discriminated union; a thrown error described generically as carrying a status/code is
  `AuthHttpError`.
- **SwiftUI**: a Swift port would model each wire row (`ProviderCatalogEntry`, `MaskedProviderConfig`,
  `SafeConnection`, `AuthUrlResult`, and the rest) as a `Codable, Hashable, Sendable` struct, and
  `integrationsApi` as an `actor` or `@MainActor final class` exposing `async throws` functions built on
  `URLSession`. `ConnectRequestBody`'s `type`-discriminated union needs a hand-written `Codable`
  implementation (a Swift `enum` with associated values does not auto-derive to this shape); `decodeOAuthStateClaims`
  ports to a small standalone function using `Data(base64Encoded:)` (after the `-`/`_` → `+`/`/` substitution
  and padding this module performs) plus `JSONDecoder`, deliberately never verifying the HMAC client-side.
- **AppKit / UIKit**: no direct UI dependency exists in this module; a macOS/iOS Hub integrations feature
  would consume the ported client through an injected data-source protocol — the same pattern the sibling
  Hub `EcosystemConfig` topics already use for their own data sources — rather than calling `URLSession`
  from the view layer.
- **Compose**: model the wire rows as Kotlin `data class`es annotated `@Serializable`, and
  `ConnectRequestBody`'s discriminated union as a `sealed class` (a closer structural match to the
  TypeScript union than Swift's enum-with-associated-values); model `integrationsApi` as a class exposing
  `suspend fun` equivalents built on Ktor or OkHttp, with a sealed error type carrying the HTTP status and
  optional code in place of `AuthHttpError`.
- **WinUI 3**: model the wire rows as C# `record`s attributed for `System.Text.Json` (e.g.
  `record MaskedProviderConfig(string Id, string EcosystemId, string ProviderId, string Name, ...)`), and
  `ConnectRequestBody`'s `type`-keyed union as a `JsonPolymorphic`-attributed abstract record hierarchy
  (`System.Text.Json`'s `JsonDerivedType` attributes keyed on the same `type` discriminator string values —
  `oauth`, `api_key`, `app_password`, `plaid_link`, `oauth_instance`, `github_app`); model `integrationsApi`
  as a class exposing `Task<T>`-returning methods built on `HttpClient`, attaching
  `Authorization: Bearer <token>` and refreshing on a `401` with the same one-retry waterfall this module
  inherits from `authedFetch` — this repo has no existing WinUI 3 prior art for that refresh-and-retry
  contract, so it would need to be built alongside the port, not assumed; port `decodeOAuthStateClaims`/
  `isOAuthStateFresh` as a small helper using `Convert.FromBase64String` (after the same `-`/`_` substitution
  and padding) and `System.Text.Json`, never verifying the HMAC client-side; back the provider catalog and
  connections lists with an `ObservableCollection<T>` or an `INotifyPropertyChanged` view-model for a WinUI 3
  `ListView`/`ItemsView`.

