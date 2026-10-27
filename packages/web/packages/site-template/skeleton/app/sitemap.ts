// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit.
import type { MetadataRoute } from 'next'
import { frameSitemap } from '@agenticdevelopertoolkit/site-template'
import { config } from '../src/site/config'

export default function sitemap(): MetadataRoute.Sitemap {
  return frameSitemap(config)
}
