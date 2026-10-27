import type { Metadata, MetadataRoute, Viewport } from 'next'
import type { FrameConfig, FrameCopy } from './types'

// The root files every content site has in common — metadata, viewport, robots, sitemap —
// written once from the site's copy and config. The file is `frame-metadata.ts` rather than
// `metadata.ts`, and the origin helper `frameSiteUrl` rather than `siteUrl`, because the
// repo's abstractr hook refuses a name another shared tier exports (adh-registry has a
// `siteUrl` of its own, a different function).

/**
 * The site's public origin. `SITE_URL` when the deploy sets one; otherwise Vercel's production
 * hostname, which it sets on every deployment of a project, preview ones included; otherwise
 * the local dev server. An empty variable counts as unset.
 */
export function frameSiteUrl(fallbackPort: number): string {
  const explicit = process.env.SITE_URL
  if (explicit !== undefined && explicit !== '') return explicit
  const vercel = process.env.VERCEL_PROJECT_PRODUCTION_URL
  if (vercel !== undefined && vercel !== '') return `https://${vercel}`
  return `http://localhost:${fallbackPort}`
}

/**
 * What every crawler and link unfurler reads. `metadataBase` is what makes the relative `url`
 * and image paths absolute, which Open Graph requires. Icons are not declared: `app/icon.*`
 * and its siblings are Next file conventions, and a list here would override them.
 */
export function frameMetadata(copy: FrameCopy, config: FrameConfig): Metadata {
  const title = copy.title ?? copy.name
  return {
    title,
    description: copy.description,
    metadataBase: new URL(config.siteUrl),
    applicationName: copy.name,
    authors: [{ name: copy.people.author }],
    creator: copy.people.creator,
    publisher: copy.people.publisher,
    // One page, one canonical: staging and testing serve the same markup on their own hosts,
    // and this points a crawler that finds one of them back at production.
    alternates: { canonical: '/' },
    openGraph: {
      type: 'website',
      siteName: copy.name,
      title,
      description: copy.description,
      url: '/',
      locale: 'en_US',
      images: [{ url: config.ogImage, alt: copy.ogImageAlt }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description: copy.description,
      images: [config.ogImage],
    },
  }
}

export function frameViewport(config: FrameConfig): Viewport {
  return {
    themeColor: config.themeColor,
    width: 'device-width',
    initialScale: 1,
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
    sitemap: `${config.siteUrl}/sitemap.xml`,
    host: config.siteUrl,
  }
}

/**
 * `/`, then the site's other public paths. `lastModified` is the build time: the site
 * redeploys whenever its copy changes, so the deploy is the modification.
 */
export function frameSitemap(config: FrameConfig): MetadataRoute.Sitemap {
  const lastModified = new Date()
  return [
    { url: config.siteUrl, lastModified, changeFrequency: 'monthly', priority: 1 },
    ...config.sitemap.map((path) => ({
      url: `${config.siteUrl}${path}`,
      lastModified,
      changeFrequency: 'monthly' as const,
      priority: 0.8,
    })),
  ]
}
