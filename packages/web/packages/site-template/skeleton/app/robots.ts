// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit.
import type { MetadataRoute } from 'next'
import { frameRobots } from '@agenticdevelopertoolkit/site-template'
import { config } from '../src/site/config'

export default function robots(): MetadataRoute.Robots {
  return frameRobots(config)
}
