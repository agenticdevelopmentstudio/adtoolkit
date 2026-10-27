// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit.
import type { ReactElement } from 'react'
import { Flow, FlowHero } from '@agenticdevelopertoolkit/landing'

/**
 * Any path the site does not serve: the hero frame, saying so. The words are the ones Next's
 * own 404 page says, so a site that had none of its own reads the same as before.
 */
export default function NotFound(): ReactElement {
  return (
    <Flow>
      <FlowHero id="top" fill headline="404" sub="This page could not be found." />
    </Flow>
  )
}
