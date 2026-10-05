
- **React/Web** (source platform): `packages/web/packages/data/src/profile/profile.ts`,
  `usage.ts`, and `wire.ts` hold the client, re-exported as the package's public surface by
  `index.ts`; every network operation is built on `authedJson`/`authedRequest` from
  `@agentic-toolkit/auth/client` (re-exported through `./http`), and the four cache-key functions
  are plain string-array builders with no framework dependency of their own — a consumer wires them
  into whatever cache layer (e.g. react-query) it uses.
- **SwiftUI**: model `SocialLink`/`SocialLinkWrite`/`Address`/`AddressWrite`/`PrivacyGrant`/
  `UsageRow`/`UsageLimits` as `Codable, Hashable, Sendable` structs, `PrivacyLevel`/`UsageScope`/
  `UsageRowKind` as Swift `enum`s, and the client as an `actor` or `@MainActor final class` exposing
  `async throws` functions built on `URLSession`, mirroring the pattern the sibling
  `hub-domain-access` recipe's Swift port note already describes for this repo's Hub Apple targets.
- **AppKit / UIKit**: no direct UI dependency exists in this module; a macOS/iOS feature would
  consume the ported client through an injected data-source protocol rather than calling
  `URLSession` from the view layer, and the `opts.workspace` parameter becomes a constructor/init
  argument on that protocol rather than a per-call option.
- **Compose**: model the wire rows as Kotlin `data class`es annotated `@Serializable`, `PrivacyLevel`
  as a Kotlin `enum class`, and the client as a class exposing `suspend fun` equivalents built on
  Ktor or OkHttp; the cache-key arrays become a small `data class` or sealed key type rather than a
  plain list, since Kotlin has no equivalent to comparing array prefixes at the call site.
- **WinUI 3**: model `SocialLink`/`SocialLinkWrite`/`Address`/`AddressWrite`/`PrivacyGrant`/
  `UsageRow`/`UsageLimits` as `record`s attributed for `System.Text.Json`, `PrivacyLevel` as a C#
  `enum` with a `Dictionary<PrivacyLevel,int>` in place of `AUDIENCE_MASK`, and the client as a class
  exposing `Task<T>`-returning methods built on `HttpClient`, attaching `Authorization: Bearer
  <token>` and the same one-retry-on-401 refresh waterfall `authedFetch` performs. Back the two list
  surfaces (social links, addresses) with `ObservableCollection<T>` for a Settings-page editor, with
  each row implementing `INotifyPropertyChanged` for two-way binding in the address/social-link edit
  forms. The `socialLinksKey`/`addressesKey`/`usageSummaryKey` namespacing has no direct WinUI 3
  analog, since there is no react-query-style cache — a port would instead key any local cache
  `Dictionary` by the same `(ownerKind, ownerId)` tuple to preserve the same non-aliasing guarantee.

