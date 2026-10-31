/**
 * `<SiteFooter specimen />` is a COPY of the footer, shown beside the page's own (the theme
 * editor's preview, theme-editor/areas.tsx). The footer carries things a page must have exactly
 * one of, found by id across the whole document or portaled to <body>, and a specimen must
 * bring none of them. What the theme editor sees of that is previews.test's; this is the prop's
 * own contract, for any host that renders a copy.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render } from '@testing-library/react'

// A plain anchor: next/link's own needs an app router this file has no use for.
vi.mock('next/link', () => ({
  default: ({ href, prefetch: _prefetch, ...rest }: { href: string; prefetch?: boolean }) => (
    <a href={href} {...rest} />
  ),
}))

// bitbag as the one element a mounted chat puts on the page. The real one loads through
// next/dynamic and portals itself to <body>; that is footerDock.test's subject, not this one's.
vi.mock('../FooterChat', () => ({
  FooterChat: () => <div className="bb-dock adh-footer__chat" />,
}))

import { SiteFooter } from '../SiteFooter'
import { FAMILY_FOOTER_DIALOG_ID, SITES_OVERVIEW_POPOVER_ID } from '../identity'
import { PRIVACY_DIALOG_ID, TERMS_DIALOG_ID } from '../LegalModals'

/** The dialogs the footer opens, one per page. */
const PAGE_DIALOGS = [
  FAMILY_FOOTER_DIALOG_ID,
  SITES_OVERVIEW_POPOVER_ID,
  TERMS_DIALOG_ID,
  PRIVACY_DIALOG_ID,
]

const present = () => PAGE_DIALOGS.filter((id) => document.getElementById(id) !== null)

afterEach(cleanup)

describe('SiteFooter specimen', () => {
  it('never mounts bitbag, even when asked to', () => {
    // He portals himself to <body>, so no preview can contain him: the copy's dock landed
    // full-size over the console showing it, and shared the page dock's view-transition-name.
    render(<SiteFooter specimen chat />)
    expect(document.querySelector('.bb-dock')).toBeNull()
  })

  it("renders none of the page's dialogs — its copyright opens the page footer's", () => {
    render(<SiteFooter specimen />)
    expect(present()).toEqual([])
    expect(document.querySelector('.adh-footer__copyright-trigger')).toHaveAttribute(
      'popovertarget',
      FAMILY_FOOTER_DIALOG_ID,
    )
  })

  it('leaves every dialog id unique on a page that also holds copies', () => {
    // `popovertarget` finds its panel by id across the whole document; a second dialog under
    // the same id would make which one opens a question of document order.
    render(
      <>
        <SiteFooter />
        <SiteFooter specimen />
        <SiteFooter specimen />
      </>,
    )
    for (const id of PAGE_DIALOGS) expect(document.querySelectorAll(`[id="${id}"]`)).toHaveLength(1)
  })

  it('leaves the page footer as it was', () => {
    // The control: everything the specimen drops is still the page footer's, under the ids
    // the rest of the page (and footer.test) knows it by.
    render(<SiteFooter chat />)
    expect(document.querySelectorAll('.bb-dock')).toHaveLength(1)
    expect(present()).toEqual(PAGE_DIALOGS)
  })
})
