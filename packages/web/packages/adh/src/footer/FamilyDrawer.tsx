// The family's half of the site template's drawer: its `drawer` slot (a Hub Websites row, after the
// page's rows) and its `drawerFoot` slot (a More Info row, in the foot). Each jumps to where that
// part of the landing page starts, rather than repeating its cards or links.
import type { ReactElement } from 'react'
import { FAMILY_BAND_ID, MORE_INFO_ANCHOR_ID } from './identity'

/** The drawer's Hub Websites row: to the landing page's family band. For the `drawer` slot. */
export function FamilyDrawerRow(): ReactElement {
  return (
    <a className="lp-nav" href={`/#${FAMILY_BAND_ID}`}>
      Hub Websites
    </a>
  )
}

/** The drawer's More Info row, in its foot: to the landing page's footer (LandingFooter). For
 *  the `drawerFoot` slot. */
export function MoreInfoDrawerFoot(): ReactElement {
  return (
    <a className="lp-nav" href={`/#${MORE_INFO_ANCHOR_ID}`}>
      More Info
    </a>
  )
}
