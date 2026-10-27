import { Fragment } from 'react'
import type { ComponentType, ReactElement } from 'react'
import { SiteFooter } from '@agenticdevelopertoolkit/landing'
import type { FrameCopy } from './types'
import { Words } from './words'

/**
 * The page's foot: the kit's `SiteFooter`, filled from the site's copy.
 *
 * The first line is who made it, set plain; every line after it is fine print — a copyright,
 * a trademark attribution — set `<small>`, one line each. A site whose copy has no footer
 * gets none at all, rather than an empty landmark. A `slot` replaces the lines and keeps the
 * `<footer>` frame, the way every slot keeps its frame.
 */
export function FrameFooter({
  copy,
  slot: Slot,
}: {
  copy: FrameCopy
  slot?: ComponentType
}): ReactElement | null {
  if (Slot !== undefined) {
    return (
      <SiteFooter>
        <Slot />
      </SiteFooter>
    )
  }
  // Insertion order of the keys, which is why footer keys must not be integer-like (those sort first).
  const lines = Object.values(copy.footer ?? {})
  const [first, ...rest] = lines
  if (first === undefined) return null
  return (
    <SiteFooter>
      <Words text={first} />
      {rest.map((line, i) => (
        <Fragment key={i}>
          <br />
          <small>
            <Words text={line} />
          </small>
        </Fragment>
      ))}
    </SiteFooter>
  )
}
