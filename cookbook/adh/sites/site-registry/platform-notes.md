
- **AppKit / UIKit**: These are TypeScript/web sources with no Apple-framework
  dependency; a macOS/iOS reader of this recipe would model a site definition and a
  brand story as `Codable` `struct`s, the site roster and the brand-story map as
  `static let` constants (loaded from a bundled JSON or a generated Swift file
  rather than re-typed by hand), and environment detection/cross-site link
  construction/the OAuth return-origin allowlist as pure functions over
  `URLComponents`/`String` with no `NSObject` subclassing needed anywhere.
- **SwiftUI**: No SwiftUI dependency exists in the source. A SwiftUI consumer would
  typically expose the registry's derived collections (the listed-sites set, the
  footer site list, category grouping's output) as plain `let` properties on an
  `@Observable` view model computed once at init, since none of the underlying data
  ever changes during a running process.
- **Compose**: A Kotlin port would model the site identifier type as a `sealed
  interface`/`enum class` rather than a string-literal union (closer to identifier
  validation's narrowing contract than TypeScript's own union erasure), a site
  definition/brand story as `data class`es, and the various derived `Set`/`Map`
  constants (the landing-segment set, the full workspace-segment set, the merged
  guided-tour graph) as `kotlinx.collections.immutable` structures built once at
  object-initialization time, mirroring this module's compute-once-at-load pattern.
- **React/Web**: This is the source. The implementation lives in `registry.ts`,
  `reserved-slugs.ts`, the thirteen `routes.*.generated.ts` shares plus the
  hand-written `routes.generated.ts`, and `story.ts`, all under
  `packages/web/packages/adh-registry/src/sites/`. `registry.ts` declares the
  `SiteId` union and the `SiteDef` shape, the `SITES` array, environment/host
  resolution (`detectEnv`, `hostForEnv`, `localOrigin`, `buildSiteHref`), the hub's
  feature-segment map (`HUB_FEATURE_SEGMENT`, `SITE_FOR_HUB_SEGMENT`,
  `HUB_WORKSPACE_SEGMENTS`), the workspace-slug round trip (`siteWorkspaceHref`/
  `siteWorkspaceSlug` plus `SITE_LANDING_SEGMENTS`/`HUB_ROUTE_SEGMENTS`), the
  per-site build-config side table (`SITE_BUILD`/`siteBuildConfig`) kept outside the
  file's `<gen:sites>`…`</gen:sites>` scaffolded region, and the SSO allowlist
  (`ssoReturnOrigins`). `reserved-slugs.ts` holds `RESERVED_SLUGS`,
  `isReservedSlug`, and `isReservedSlugAnywhere`. The route shares merge via
  `Object.assign` into `SITE_ROUTE_SHARES`/`SITE_ROUTES`. `story.ts` holds
  `SITE_STORIES`, `getSiteStory`, and the three generated rings `TOUR_MAIN`/
  `TOUR_MARKETING`/`TOUR_PLACEHOLDER` merged by object spread into
  `SITE_TOUR_NEXT`. A site's build-tree directory name is a Next.js app-router
  folder derived by `dirNameOf`; a site's workspace route is a Next.js
  `app/[workspace]` dynamic route. `personaProfileUrl` reads the current hostname
  from `globalThis.location?.hostname ?? ''` rather than `window` directly, because
  this file is also type-checked in a backend build with no DOM library. The files
  are pure TypeScript with no React import, consumed by React components (the
  header, switcher, and footer) that live elsewhere in the same web packages; a
  caller re-implementing this in another JS/TS codebase should keep the same
  pure-data/pure-function shape rather than folding any of it into a component or a
  hook, since several of the exports (`ssoReturnOrigins`, the route shares) are
  consumed by non-React code (a backend sync job, a sitemap generator) that would
  break if the logic moved into a component. Nothing in the module uses `async`,
  `Promise`, or any mutable module-level state — every export is a `const` computed
  once at module load or a pure function over that data.
- **WinUI 3**: A .NET port would model the site identifier type as an `enum`, a
  site definition/brand story as `record`s (immutable by default, matching this
  module's `readonly`-everywhere shape), the various derived set/map constants as
  `FrozenSet<string>`/`FrozenDictionary<TKey, TValue>` computed once in a static
  constructor, environment detection/environment host resolution/local-origin
  resolution as pure `static` methods over `Uri`/`string`, and `System.Text.Json`
  for deserializing any of this data if it were instead shipped as a generated JSON
  asset rather than compiled Swift/Kotlin/C# source; no `HttpClient`,
  `Windows.Storage`, `Task`/`async`, `ObservableCollection`, or
  `INotifyPropertyChanged` is needed anywhere, since nothing in this component
  performs I/O, runs asynchronously, or changes after process start.

