import type { Metadata, MetadataRoute, Viewport } from 'next'
import type { FrameConfig, FrameCopy } from './types'

// The root files every content site has in common — metadata, viewport, robots, sitemap —
// written once from the site's copy and config. The file is `frame-metadata.ts` rather than
// `metadata.ts`, and the origin helper `frameSiteUrl` rather than `siteUrl`, because the
// repo's abstractr hook refuses a name another shared tier exports (adh-registry has a
// `siteUrl` of its own, a different function).

/**
 * The site's public origin. `SITE_URL` when the deploy sets one; otherwise `configured`, the
 * origin the site states in `site.json`'s `siteUrl`; otherwise Vercel's production hostname,
 * which it sets on every deployment of a project, preview ones included, and which is a
 * `*.vercel.app` name whenever the project's production domain is not the custom one; otherwise
 * the local dev server. An empty value counts as unset.
 */
export function frameSiteUrl(fallbackPort: number, configured?: string): string {
  const explicit = process.env.SITE_URL
  if (explicit !== undefined && explicit !== '') return explicit
  if (configured !== undefined && configured !== '') return configured
  const vercel = process.env.VERCEL_PROJECT_PRODUCTION_URL
  if (vercel !== undefined && vercel !== '') return `https://${vercel}`
  return `http://localhost:${fallbackPort}`
}

/**
 * `config.siteUrl` with any trailing slash removed, so a site that writes its origin as
 * `https://x.example/` still gets `https://x.example/sitemap.xml` rather than `//sitemap.xml`.
 * Every URL below is built by appending a `/`-led path to this.
 */
function origin(config: FrameConfig): string {
  return config.siteUrl.replace(/\/+$/, '')
}

/**
 * The unfurl card's size. The large card is a wide banner; a site whose OG image IS its mark (an
 * app icon, a glyph — square and small) gets the small card, which shows it beside the text
 * rather than cropping it to a banner.
 */
function twitterCard(config: FrameConfig): 'summary' | 'summary_large_image' {
  return config.ogImage === config.mark.src ? 'summary' : 'summary_large_image'
}

/**
 * What every crawler and link unfurler reads. `metadataBase` is what makes the relative `url`
 * and image paths absolute, which Open Graph requires. Icons are not declared: `app/icon.*`
 * and its siblings are Next file conventions, and a list here would override them.
 *
 * This is the ROOT layout's metadata, so it is every route's: the frame's `/`, the not-found
 * page, and every page a site adds under `app-routes/`. It therefore says nothing about which
 * URL a page is — no canonical and no Open Graph `url`. A custom route that inherited
 * `canonical: '/'` would be telling a crawler it is a copy of the home page, and drop out of the
 * index. `/` names itself with `frameHomeMetadata`, from the frame's own page.
 */
export function frameMetadata(copy: FrameCopy, config: FrameConfig): Metadata {
  const title = copy.title ?? copy.name
  return {
    title,
    description: copy.description,
    ...(copy.keywords === undefined ? {} : { keywords: copy.keywords }),
    metadataBase: new URL(config.siteUrl),
    applicationName: copy.name,
    // With a url, Next also writes `<link rel="author">` to the author's page.
    authors: [{ name: copy.people.author, ...(config.authorUrl === undefined ? {} : { url: config.authorUrl }) }],
    creator: copy.people.creator,
    publisher: copy.people.publisher,
    openGraph: {
      type: 'website',
      siteName: copy.name,
      title,
      description: copy.description,
      locale: 'en_US',
      images: [
        {
          url: config.ogImage,
          ...(config.ogImageType === undefined ? {} : { type: config.ogImageType }),
          ...config.ogImageSize,
          alt: copy.ogImageAlt,
        },
      ],
    },
    twitter: {
      card: twitterCard(config),
      title,
      description: copy.description,
      images: [config.ogImage],
    },
  }
}

/**
 * What `/` says about its own URL, exported as the frame page's `metadata`: the canonical and
 * the Open Graph `url`, which the root layout's `frameMetadata` leaves out so no other route
 * inherits them. One page, one canonical: staging and testing serve the same markup on their own
 * hosts, and this points a crawler that finds one of them back at production.
 *
 * Next merges a page's metadata over its layouts' one top-level key at a time, so a page's
 * `openGraph` replaces the layout's whole; this one is therefore the root's full card plus `url`.
 */
export function frameHomeMetadata(copy: FrameCopy, config: FrameConfig): Metadata {
  return {
    alternates: { canonical: '/' },
    openGraph: { ...frameMetadata(copy, config).openGraph, url: '/' },
  }
}

export function frameViewport(config: FrameConfig): Viewport {
  return {
    themeColor: config.themeColor,
    width: 'device-width',
    initialScale: 1,
    // Stops iOS zooming on focus; FrameZoomGuard, which the root layout renders on every route,
    // strips it back off every browser that isn't iOS, so pinch-zoom still works there.
    maximumScale: 1,
    // Android shrinks the layout viewport when its keyboard opens, so a bottom-anchored fixed
    // element (the bitbag dock) lifts on its own. iOS ignores this.
    interactiveWidget: 'resizes-content',
  }
}

/**
 * Only production says yes to crawlers. Every tier serves byte-identical markup on its own
 * hostname, and three crawlable copies of one page compete with each other for the same query.
 * Read when Next calls it, at build time, which is when the tier is known.
 */
export function frameRobots(config: FrameConfig): MetadataRoute.Robots {
  if (process.env.DEPLOYMENT_ENV !== 'production') {
    return { rules: [{ userAgent: '*', disallow: '/' }] }
  }
  return {
    rules: [{ userAgent: '*', allow: '/' }],
    sitemap: `${origin(config)}/sitemap.xml`,
    host: origin(config),
  }
}

/**
 * `/`, then the site's other public paths. `lastModified` is the build time: the site
 * redeploys whenever its copy changes, so the deploy is the modification.
 */
export function frameSitemap(config: FrameConfig): MetadataRoute.Sitemap {
  const lastModified = new Date()
  const base = origin(config)
  return [
    { url: base, lastModified, changeFrequency: 'monthly', priority: 1 },
    ...config.sitemap.map((path) => ({
      url: `${base}${path}`,
      lastModified,
      changeFrequency: 'monthly' as const,
      priority: 0.8,
    })),
  ]
}
