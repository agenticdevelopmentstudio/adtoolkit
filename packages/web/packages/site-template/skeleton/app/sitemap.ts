// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit.
import type { MetadataRoute } from 'next'
import { frameSitemap } from '@agenticdevelopertoolkit/site-template'
import { config } from '../src/site/config'
import { sitemapRoutes } from '../src/site/sitemap'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  return frameSitemap(config, await sitemapRoutes())
}
