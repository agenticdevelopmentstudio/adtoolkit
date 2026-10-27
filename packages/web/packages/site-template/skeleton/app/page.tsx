// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import type { ReactElement } from 'react'
import { FrameMark, LandingFrame } from '@agenticdevelopertoolkit/site-template'
import landing from '../src/landing'
import siteCopy from '../src/content/site/site.json'
import { config } from '../src/site/config'
import { slots } from '../src/site/slots'

/** `/`: the hero and the bands, from the site's landing content and its slots. */
export default function Home(): ReactElement {
  return (
    <LandingFrame
      page={landing}
      slots={slots}
      mark={<FrameMark config={config} alt={siteCopy.markAlt} />}
    />
  )
}
