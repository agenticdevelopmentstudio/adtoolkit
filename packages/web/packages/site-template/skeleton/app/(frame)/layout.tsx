// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import type { ReactElement, ReactNode } from 'react'
import { FrameFooter } from '@agenticdevelopertoolkit/site-template'
import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'
import { SiteBitbag, SiteChrome } from '@agenticdevelopertoolkit/site-template/client'
import landing from '../../src/landing'
import siteCopy from '../../src/content/site/site.json'
import { config } from '../../src/site/config'
import { slots } from '../../src/site/slots'

// Typed for the reason the root layout gives.
const copy: FrameCopy = siteCopy

/**
 * The frame, around `/` and every route of a site's `routes`: the bar and drawer above, the
 * footer and bitbag below. They are the page's siblings rather than its children — `<main>` is
 * the bands' flow parent, and the kit's last-band dock clearance holds only while its last child
 * is a band. `(frame)` is a route group, so it adds nothing to any URL. A `header` slot takes the
 * bar's place.
 */
export default function FrameLayout({ children }: { children: ReactNode }): ReactElement {
  return (
    <>
      {slots.header === undefined ? (
        <SiteChrome copy={copy} page={landing} extra={config.drawerExtra} />
      ) : (
        <slots.header />
      )}
      {children}
      <FrameFooter copy={copy} slot={slots.footer} />
      {slots.bitbag === undefined ? <SiteBitbag /> : <slots.bitbag />}
    </>
  )
}
