// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import type { Metadata, Viewport } from 'next'
import type { ReactElement, ReactNode } from 'react'
import { FrameFooter, frameMetadata, frameViewport } from '@agenticdevelopertoolkit/site-template'
import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'
import { SiteBitbag, SiteChrome } from '@agenticdevelopertoolkit/site-template/client'
import landing from '../src/landing'
import siteCopy from '../src/content/site/site.json'
import { config } from '../src/site/config'
import { fontVariables } from '../src/site/fonts'
import { slots } from '../src/site/slots'
import './theme.css'

// The site's copy, typed: a heading renamed in the markdown is a typecheck failure here
// rather than a blank on the page.
const copy: FrameCopy = siteCopy

export const metadata: Metadata = frameMetadata(copy, config)

export const viewport: Viewport = frameViewport(config)

/**
 * Every route's frame: the bar and drawer above, the footer and bitbag below. They are the
 * page's siblings rather than its children — `<main>` is the bands' flow parent, and the kit's
 * last-band dock clearance holds only while its last child is a band.
 */
export default function RootLayout({ children }: { children: ReactNode }): ReactElement {
  return (
    // The landing kit's DeckScript sets `data-smooth` and `data-snap` on this element from the
    // reader's first input, which can land before React hydrates; that difference is the
    // script's intended effect, not a divergence.
    <html lang="en" className={fontVariables} suppressHydrationWarning>
      <body>
        {config.jsonLd === undefined ? null : (
          <script
            type="application/ld+json"
            // `<` escaped so no string in the site's structured data can close the script.
            dangerouslySetInnerHTML={{ __html: JSON.stringify(config.jsonLd).replace(/</g, '\\u003c') }}
          />
        )}
        <SiteChrome copy={copy} page={landing} extra={config.drawerExtra} />
        {children}
        <FrameFooter copy={copy} slot={slots.footer} />
        <SiteBitbag />
      </body>
    </html>
  )
}
