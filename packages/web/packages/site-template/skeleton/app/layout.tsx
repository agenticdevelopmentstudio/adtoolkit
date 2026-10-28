// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import type { Metadata, Viewport } from 'next'
import type { ReactElement, ReactNode } from 'react'
import { FrameZoomGuard, frameMetadata, frameViewport } from '@agenticdevelopertoolkit/site-template'
import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'
import siteCopy from '../src/content/site/site.json'
import { SiteAnalytics } from '../src/site/analytics'
import { config } from '../src/site/config'
import { fontVariables } from '../src/site/fonts'
import './theme.css'

// The site's copy, typed: a heading renamed in the markdown is a typecheck failure here
// rather than a blank on the page.
const copy: FrameCopy = siteCopy

export const metadata: Metadata = frameMetadata(copy, config)

export const viewport: Viewport = frameViewport(config)

/**
 * Every route's document: the fonts, the theme, the metadata, the site's structured data and its
 * analytics — and nothing visible. The frame's bar, drawer, footer and bitbag are the `(frame)`
 * group's layout, so a site's `app-routes` (an app behind sign-in, an auth callback) render
 * bare, with their own layouts, at the same URLs they would have had inside it.
 */
export default function RootLayout({ children }: { children: ReactNode }): ReactElement {
  return (
    // The landing kit's DeckScript sets `data-smooth` and `data-snap` on this element from the
    // reader's first input, which can land before React hydrates; that difference is the
    // script's intended effect, not a divergence.
    <html lang="en" className={fontVariables} suppressHydrationWarning>
      <body>
        {/* First in <body>, so the viewport meta it edits is already parsed (see DeckScript). */}
        <FrameZoomGuard />
        {config.jsonLd === undefined ? null : (
          <script
            type="application/ld+json"
            // `<` escaped so no string in the site's structured data can close the script.
            dangerouslySetInnerHTML={{ __html: JSON.stringify(config.jsonLd).replace(/</g, '\\u003c') }}
          />
        )}
        {children}
        <SiteAnalytics />
      </body>
    </html>
  )
}
