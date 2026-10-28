import type { ReactElement } from 'react'
import { DeckScript } from '@agenticdevelopertoolkit/landing'

/**
 * Pinch-zoom back off iOS, on every route. `frameViewport` ships `maximum-scale=1` in every
 * page's viewport meta — the only way to stop iOS Safari zooming when a form field takes
 * focus — and that also disables pinch-zoom, which only iOS has a reason to give up. The landing
 * kit's `DeckScript` strips it back off everywhere else; this is that half of it alone, for the
 * skeleton's root layout to render first in `<body>`, so a site's own routes — an app behind
 * sign-in, the 404 — keep pinch-zoom as `/` does. `LandingFrame`'s own `DeckScript` leaves it
 * to this one.
 */
export function FrameZoomGuard(): ReactElement {
  return <DeckScript openAtTop={false} armSnapping={false} armSmooth={false} />
}
