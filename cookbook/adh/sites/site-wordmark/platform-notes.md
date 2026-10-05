
- **SwiftUI**: Not applicable — web-only shared component.
- **Compose**: Not applicable — web-only shared component.
- **React / Web (TypeScript):** Component at
  `packages/web/packages/adh/src/marketing/SiteWordmark.tsx`, exported on its own
  subpath `@agentic-toolkit/adh/marketing/SiteWordmark` (with a dedicated `tsup`
  entry + `exports` key). Reuses `getSite` + `splitSiteTitle` from
  `@agentic-toolkit/adh-registry`. It lives in `@agentic-toolkit/adh` — the
  vocabulary package — rather than a generic package such as
  `@agenticdevelopertoolkit/ui` or `@agenticdevelopertoolkit/themes`, since it
  resolves the ADH site registry; the `HubMark` glyph inside it comes from
  `@agentic-toolkit/adh/header` because that one piece is registry-free. Root
  element is a `<div>` carrying any `className`; the wordmark line is
  `font-serif text-lg leading-tight font-medium tracking-tight text-apt-text
  sm:text-xl`, with the accent word wrapped in `<span
  className="text-apt-gold italic">`; the identity line is `mt-1 font-mono
  text-[0.65rem] uppercase tracking-[0.18em] text-apt-text-dim`. Uses `apt-*`
  tokens only — no raw hex, no `!important`. Pure presentational component (no
  hooks, no client state), so it renders correctly inside both server and
  client trees; is `'use client'`-safe to co-locate with client consumers since
  it imports only the pure registry, not `MarketingLanding`'s content prose.
  Props:
  ```ts
  interface SiteWordmarkProps {
    siteId: SiteId
    tagline?: React.ReactNode   // undefined → site description; null → omit
    className?: string
  }
  export function SiteWordmark(props: SiteWordmarkProps): React.ReactElement
  ```
  Demoed in `ui-showcase` (Chrome group); first consumer is the research site's
  `AuthorPapersIndex`.
- **AppKit / UIKit**: Not applicable — web-only shared component.
- **WinUI 3**: Build it as a `UserControl` holding a vertical `StackPanel` of two `TextBlock`s. The wordmark line uses `Run` inlines inside one `TextBlock`: a lead `Run` in the primary-text theme brush and an accent `Run` with `FontStyle=Italic` in the accent theme brush (a `ThemeResource`), set in a serif `FontFamily`. The identity line is a second `TextBlock` in a monospace `FontFamily`, uppercased, with `CharacterSpacing` for the letter-spacing and the dimmed-text theme brush, collapsed when its text is null or empty. Resolve the brand string through the same site-registry lookup and title split rather than hard-coding it.

