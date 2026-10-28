// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit.
import type { Metadata } from 'next'
import type { ReactElement } from 'react'
import { Flow } from '@agenticdevelopertoolkit/landing'
import { FrameNotFound, frameNotFoundMetadata } from '@agenticdevelopertoolkit/site-template'
import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'
import siteCopy from '../src/content/site/site.json'
import FrameLayout from './(frame)/layout'

// Typed for the reason the root layout gives.
const copy: FrameCopy = siteCopy

export const metadata: Metadata = frameNotFoundMetadata(copy)

/**
 * Any path the site does not serve: the hero frame, saying so, in the copy's `notFound` words
 * when it has them and Next's own otherwise (FrameNotFound).
 *
 * Next renders a root `not-found` inside the root layout alone — never a group's — so it wraps
 * itself in the frame: the bar and footer a visitor had before the frame became `(frame)`.
 */
export default function NotFound(): ReactElement {
  return (
    <FrameLayout>
      <Flow>
        <FrameNotFound copy={copy} />
      </Flow>
    </FrameLayout>
  )
}
