// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import type { ReactElement } from 'react'
import { LandingFrame } from '@agenticdevelopertoolkit/site-template'
import landing from '../src/landing'
import siteCopy from '../src/content/site/site.json'
import { config } from '../src/site/config'
import { slots } from '../src/site/slots'

/** `/`: the hero and the bands, from the site's landing content and its slots. */
export default function Home(): ReactElement {
  const { src, shape } = config.mark
  return (
    <LandingFrame
      page={landing}
      slots={slots}
      mark={
        // A plain <img>: the mark is a small static file in public/, and next/image would
        // add a loader and a layout box to something the frame's CSS sizes itself.
        // eslint-disable-next-line @next/next/no-img-element
        <img className={`st-mark st-mark--${shape}`} src={src} alt={siteCopy.markAlt} />
      }
    />
  )
}
