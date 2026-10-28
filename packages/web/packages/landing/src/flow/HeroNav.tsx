'use client'

import { Fragment, useRef } from 'react'
import type { ReactElement } from 'react'
import { useTextLens } from '@agenticdevelopertoolkit/textlens'
import type { NavLink } from '../chrome/types'

export interface HeroNavProps {
  /** The rows, in order — a page's own sections, `indexRows(page)`, so the row cannot name a
   * band the page does not have or miss one it does. */
  rows: NavLink[]
  /** The nav's accessible name. Copy, so the host's. */
  label: string
}

/**
 * The words under a hero's name: the page's table of contents as one line of links, separated
 * by drawn bars, swept once by a text lens that says the line is alive and worth clicking.
 *
 * Plain anchors, no click handler, so the hrefs work the same with JavaScript off; the lens is
 * the only script. Its two colours are token names (`--lp-ink-dim` to `--lp-accent-bright`),
 * resolved where the row is mounted, so a repaint of the tokens repaints the sweep. flow.css's
 * `.lp-hero-nav` styles it.
 */
export function HeroNav({ rows, label }: HeroNavProps): ReactElement {
  const rowRef = useRef<HTMLElement>(null)

  useTextLens(rowRef, {
    selector: '.lp-hero-nav__link',
    startDelay: 2000,
    fromColor: '--lp-ink-dim',
    toColor: '--lp-accent-bright',
  })

  return (
    <nav className="lp-hero-nav" aria-label={label} ref={rowRef}>
      {rows.map((row, index) => (
        <Fragment key={row.href}>
          {/* A drawn separator rather than a border: a border would also draw at the ends of a
              wrapped line. */}
          {index > 0 && (
            <span className="lp-hero-nav__sep" aria-hidden="true">
              |
            </span>
          )}
          <a className="lp-hero-nav__link" href={row.href}>
            {row.label}
          </a>
        </Fragment>
      ))}
    </nav>
  )
}
