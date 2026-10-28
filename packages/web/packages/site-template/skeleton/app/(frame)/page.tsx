// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import type { Metadata } from 'next'
import type { ReactElement } from 'react'
import { FrameMark, LandingFrame, frameHomeMetadata } from '@agenticdevelopertoolkit/site-template'
import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'
import landing from '../../src/landing'
import siteCopy from '../../src/content/site/site.json'
import { config } from '../../src/site/config'
import { family } from '../../src/site/family'
import { slots } from '../../src/site/slots'

// Typed for the reason the layout gives.
const copy: FrameCopy = siteCopy

// `/`'s own URL — its canonical and Open Graph `url` — which the root layout leaves out so the
// site's other routes do not inherit them (frame-metadata.ts).
export const metadata: Metadata = frameHomeMetadata(copy, config)

/** `/`: the hero and the bands, from the site's landing content and its slots. */
export default function Home(): ReactElement {
  return (
    <LandingFrame
      page={landing}
      slots={slots}
      mark={<FrameMark config={config} alt={copy.markAlt} />}
      looks={config.bands}
      pendingLabel={copy.screenshotPending}
      heroShot={config.heroShot}
      family={family}
    />
  )
}
