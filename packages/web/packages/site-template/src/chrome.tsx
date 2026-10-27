'use client'

import type { ReactElement } from 'react'
import { indexRows } from '@agenticdevelopertoolkit/landing'
import type { LandingPage, NavLink } from '@agenticdevelopertoolkit/landing'
import { NavChrome } from '@agenticdevelopertoolkit/landing/client'
import type { FrameConfig, FrameCopy } from './types'
import { Words } from './words'

/**
 * The bar, the burger and the drawer: the kit's `NavChrome`, filled from the site's copy and
 * its one section list.
 *
 * The rows are Home, then one per section — the same `indexRows` the bands are built from, so
 * the drawer cannot list a section the page does not have — then the site's own extra rows.
 * Every in-page row is written `/#id` rather than `#id`, so it still lands on the section
 * from any other route of the site; on `/` itself the kit's drawer still glides there.
 */
export function SiteChrome({
  copy,
  page,
  extra,
}: {
  copy: FrameCopy
  page: LandingPage
  extra: FrameConfig['drawerExtra']
}): ReactElement {
  const links: NavLink[] = [
    { href: '/#top', label: 'Home' },
    ...indexRows(page).map((row) => ({ href: `/${row.href}`, label: row.label })),
    ...extra,
  ]
  const { email } = copy.contact
  const footer = (
    <>
      {copy.drawer === undefined ? null : (
        <>
          <Words text={copy.drawer.hello} />
          <br />
        </>
      )}
      <a href={`mailto:${email}`}>{email}</a>
      {copy.drawer === undefined ? null : (
        <>
          <br />
          <Words text={copy.drawer.byline} />
        </>
      )}
    </>
  )
  return <NavChrome brand={<Words text={copy.brand} />} links={links} footer={footer} />
}
