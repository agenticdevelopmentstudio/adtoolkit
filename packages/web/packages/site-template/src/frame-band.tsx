import type { ReactElement, ReactNode } from 'react'
import { Band } from '@agenticdevelopertoolkit/landing'
import type { BandTone } from '@agenticdevelopertoolkit/landing'
// By package path and from `/client`: tsup leaves the landing kit external, so Reveal's
// `'use client'` stays on its own module and cannot hoist over this server component.
import { Reveal } from '@agenticdevelopertoolkit/landing/client'

/**
 * One band of the frame: the kit's `Band`, its contents revealed on scroll. Every band of `/`
 * is one, and a route of the site's own uses it so its bands enter the way those do.
 *
 * The `Reveal` goes inside the band, not around it: a transformed wrapper breaks the seam's
 * stacking (the kit's `Band`). Named `FrameBand` because the kit already exports `Band`.
 */
export function FrameBand({
  id,
  tone,
  seam,
  children,
}: {
  id: string
  /** The kit's `Band` default, `dark`, when absent. */
  tone?: BandTone
  seam?: boolean
  children: ReactNode
}): ReactElement {
  return (
    <Band id={id} tone={tone} seam={seam}>
      <Reveal>{children}</Reveal>
    </Band>
  )
}
