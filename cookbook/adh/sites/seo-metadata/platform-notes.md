
- **React/Web** (source platform): `packages/web/packages/adh-registry/src/seo/metadata.ts`,
  alongside `src/sites/registry.ts` (`getSite`, `SiteId`, `SiteDef`) and
  `src/deployment-env.ts` (`DEV_BUILD`). The module is framework-free apart from
  `import type { Metadata, MetadataRoute } from 'next'` — the four exports are plain
  functions returning plain objects; a Next.js App Router `page.tsx`'s exported
  `metadata`, an `app/robots.ts`, and an `app/sitemap.ts` are what actually read those
  shapes. `NEXT_PUBLIC_DEPLOYMENT_ENV` is inlined by webpack at build time.
- **SwiftUI**: there is no Next.js metadata contract on Apple platforms, so a port's
  job is to build the equivalent `<head>` tags directly — a small type constructing an
  HTML-metadata document (title, canonical `<link>`, `og:*`/`twitter:*` `<meta>` tags,
  the `robots` meta content) mirrors `Metadata`; `robots.txt`/`sitemap.xml` become
  plain-text/XML string builders rather than framework route files, called from whatever
  server route serves those two paths.
- **Compose**: no native-app equivalent exists (a device app has no `<head>` or
  `robots.txt`), so a Kotlin port matters only for a Ktor- or Spring-based server
  rendering these pages; use `kotlinx.serialization` data classes for `SiteSeo`/
  `SiteRobotsOptions`/`SiteRoute` and plain functions returning a small `Metadata`-
  shaped data class, with the two text formats built by string templates or an XML
  serializer.
- **AppKit/UIKit**: same non-fit as SwiftUI — this is server/build-time HTML metadata,
  not view code. An AppKit/UIKit app that embeds one of these sites in a `WKWebView`
  consumes the already-emitted HTML/robots/sitemap and has no separate contract to
  implement.
- **WinUI 3**: same non-fit for the UI framework itself, but the concrete .NET port — an
  ASP.NET Core Minimal API host serving the same site — starts from: `System.Text.Json`
  for the `SiteSeo`/`SiteRobotsOptions`/`SiteRoute` records and the plain metadata
  object; `HttpContext.Request.Host` in place of the Next `headers()`-derived `host`
  parameter; a `Task`/`async` Minimal API endpoint returning `text/plain` for
  `robots.txt` and `application/xml` for `sitemap.xml` instead of Next's file-convention
  routes; `DateTimeOffset.UtcNow` in place of `new Date()` for the shared build-time
  `lastModified`; and `IConfiguration`/environment-variable binding (a custom
  `DEPLOYMENT_ENV` config key) in place of the build-inlined `NEXT_PUBLIC_DEPLOYMENT_ENV`
  — .NET has no bundler-level dead-code fold, so the environment check is an ordinary
  runtime `if`, not a compile-time constant.

