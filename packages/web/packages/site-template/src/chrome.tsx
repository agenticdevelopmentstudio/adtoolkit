'use client'

import type { ReactElement, ReactNode } from 'react'
import { Btn, indexRows } from '@agenticdevelopertoolkit/landing'
import type { LandingPage, NavLink } from '@agenticdevelopertoolkit/landing'
import { NavChrome } from '@agenticdevelopertoolkit/landing/client'
import type { FrameConfig, FrameCopy } from './types'
import { Words } from './words'

/**
 * The bar, the burger and the drawer: the kit's `NavChrome`, filled from the site's copy and
 * its one section list.
 *
 * The rows are Home, then one per section — the same `indexRows` the bands are built from, so
 * the drawer cannot list a section the page does not have — then the site's own extra rows,
 * then a contact row mailing `copy.contact.email` when the copy words one. Every label is the
 * site's copy (`copy.nav`, an extra row's under `copy.nav.extra`); the frame words nothing.
 * Every in-page row is written `/#id` rather than `#id`, so it still lands on the section
 * from any other route of the site; on `/` itself the kit's drawer still glides there.
 * The copy's `nav.action`, when it words one, is a ghost button in the bar beside the burger.
 *
 * `underHeader` is the same drawer under a site's own header (the frame's `header` slot): the
 * burger alone, below that header, with no wordmark or action, since the header already carries
 * both. The wrapper's class is what moves the chrome down (frame.css).
 *
 * `sections` and `foot` are the frame's `drawer` and `drawerFoot` slots, rendered: the first
 * goes after the rows, the second takes the place of the copy's foot.
 */
export function SiteChrome({
  copy,
  page,
  extra,
  sections,
  foot,
  underHeader = false,
}: {
  copy: FrameCopy
  page: LandingPage
  extra: FrameConfig['drawerExtra']
  sections?: ReactNode
  foot?: ReactNode
  underHeader?: boolean
}): ReactElement {
  const { email } = copy.contact
  const worded = copy.nav.extra ?? {}
  // Refused, not skipped: a row whose label was renamed in the markdown would otherwise leave
  // the drawer with nothing in the build to say so.
  const extraRows: NavLink[] = extra.map((row) => {
    const label = worded[row.nav]
    if (label === undefined) {
      throw new Error(
        `SiteChrome: the drawer row to '${row.href}' names '${row.nav}', which the copy's nav.extra does not word. ` +
          `It words: ${Object.keys(worded).map((key) => `'${key}'`).join(', ') || '(none)'}.`,
      )
    }
    return { href: row.href, label }
  })
  const links: NavLink[] = [
    { href: '/#top', label: copy.nav.home },
    ...indexRows(page).map((row) => ({ href: `/${row.href}`, label: row.label })),
    ...extraRows,
    ...(copy.nav.contact === undefined ? [] : [{ href: `mailto:${email}`, label: copy.nav.contact }]),
  ]
  const footer = foot ?? (
    <>
      {copy.drawer === undefined ? null : (
        <>
          <Words text={copy.drawer.hello} />
          <br />
        </>
      )}
      <a href={`mailto:${email}`}>{email}</a>
      {copy.drawer?.byline === undefined ? null : (
        <>
          <br />
          <Words text={copy.drawer.byline} />
        </>
      )}
    </>
  )
  const { action } = copy.nav
  if (underHeader) {
    return (
      <div className="st-chrome-under-header" style={{ display: 'contents' }}>
        <NavChrome links={links} sections={sections} footer={footer} />
      </div>
    )
  }
  return (
    <NavChrome
      brand={<Words text={copy.brand} />}
      links={links}
      sections={sections}
      footer={footer}
      action={
        action === undefined ? undefined : (
          <Btn href={action.href} variant="ghost">
            {action.label}
          </Btn>
        )
      }
    />
  )
}
