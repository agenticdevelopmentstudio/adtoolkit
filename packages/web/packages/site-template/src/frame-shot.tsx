import type { ReactElement, ReactNode } from 'react'
import { Shot, renderBlock } from '@agenticdevelopertoolkit/landing'
import type { ShotProps } from '@agenticdevelopertoolkit/landing'

/**
 * The kit's `Shot`, worded once for a whole site: `pendingLabel` is the site's word for a
 * screenshot not yet taken (its copy's `screenshotPending`), and every shot the returned
 * component draws says it unless that one shot passes its own.
 *
 * A factory rather than a context because the frame and a site's slots are server
 * components, which cannot read a React context. The assembler calls it once, in the
 * generated `src/site/shot.tsx`, so a site's custom bands import `SiteShot` from `@/site/shot`
 * instead of threading the word into each shot by hand.
 *
 * The placeholder is drawn by the page model's `renderBlock`, the way every band of `/` draws
 * one, so a site with no word of its own gets the kit's word here too and a slot's shot never
 * reads differently from a band's.
 */
export function frameShot(pendingLabel: ReactNode | undefined): (props: ShotProps) => ReactElement {
  return function SiteShot({ title, caption, media, pendingLabel: own }: ShotProps): ReactElement {
    if (media !== undefined) return <Shot title={title} caption={caption} media={media} />
    return renderBlock({ kind: 'Shot', title, caption }, 0, own ?? pendingLabel)
  }
}
