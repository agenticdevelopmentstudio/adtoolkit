import type { ReactElement } from 'react'
import type { FrameConfig } from './types'

// The file is `frame-mark.tsx` rather than `mark.tsx` because the repo's abstractr hook refuses
// a stem another shared tier exports (bitbag's `mark` entry, his still likeness).

/**
 * The site's mark, as `site.json` configures it: the hero of `/` draws it, and so does any
 * route of the site's own that puts a hero up, so a change to `mark` reaches every page.
 *
 * A plain <img>: the mark is a small static file in public/, and next/image would add a loader
 * and a layout box to something the frame's CSS sizes itself (frame.css, `.st-mark--*`).
 */
export function FrameMark({ config, alt }: { config: FrameConfig; alt: string }): ReactElement {
  const { src, shape } = config.mark
  return <img className={`st-mark st-mark--${shape}`} src={src} alt={alt} />
}
