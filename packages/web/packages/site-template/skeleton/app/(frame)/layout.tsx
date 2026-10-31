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
 * bar's place, and the burger and drawer move under it. A `drawer` slot adds to the drawer after
 * its rows, and a `drawerFoot` slot takes its foot's place.
 */
export default function FrameLayout({ children }: { children: ReactNode }): ReactElement {
  const sections = slots.drawer === undefined ? undefined : <slots.drawer />
  const foot = slots.drawerFoot === undefined ? undefined : <slots.drawerFoot />
  return (
    <>
      {slots.header === undefined ? (
        <SiteChrome copy={copy} page={landing} extra={config.drawerExtra} sections={sections} foot={foot} />
      ) : (
        <>
          <slots.header />
          <SiteChrome copy={copy} page={landing} extra={config.drawerExtra} sections={sections} foot={foot} underHeader />
        </>
      )}
      {children}
      <FrameFooter copy={copy} slot={slots.footer} />
      {slots.bitbag === undefined ? <SiteBitbag /> : <slots.bitbag />}
    </>
  )
}
