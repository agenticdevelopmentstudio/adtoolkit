// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit.
import type { Metadata } from 'next'
import type { ReactElement } from 'react'
import { Flow, FlowHero } from '@agenticdevelopertoolkit/landing'
import { frameNotFoundMetadata } from '@agenticdevelopertoolkit/site-template'
import FrameLayout from './(frame)/layout'

/**
 * Any path the site does not serve: the hero frame, saying so. The words are the ones Next's
 * own 404 page says, so a site that had none of its own reads the same as before.
 *
 * Next renders a root `not-found` inside the root layout alone — never a group's — so it wraps
 * itself in the frame: the bar and footer a visitor had before the frame became `(frame)`.
 */
export const metadata: Metadata = frameNotFoundMetadata

export default function NotFound(): ReactElement {
  return (
    <FrameLayout>
      <Flow>
        <FlowHero id="top" fill headline="404" sub="This page could not be found." />
      </Flow>
    </FrameLayout>
  )
}
