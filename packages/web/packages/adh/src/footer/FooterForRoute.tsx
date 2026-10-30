'use client'

import type { ReactNode } from 'react'
import { usePathname } from 'next/navigation'

export type FooterForRouteProps = {
  /** The footer on `/`, the site's landing page. */
  landing: ReactNode
  /** The footer on every other route. */
  rest: ReactNode
}

/**
 * One of two already-rendered footers, by route: `landing` on `/` and `rest` everywhere else.
 * AppShell's `landingFooter` seam is the one caller; both footers are rendered by the server
 * and handed in, so this decides only which one is shown.
 *
 * A client component because it reads the route. Next resolves `usePathname()` during the
 * server render too, so a route ships with its own footer rather than swapping after hydration.
 */
export function FooterForRoute({ landing, rest }: FooterForRouteProps) {
  return <>{usePathname() === '/' ? landing : rest}</>
}
