'use client'

// The family footer's body. A client module because two of its entries are behaviour: the
// legal links open their dialogs rather than load a route, and the preview badge is a
// disclosure. Everything else is plain links in the server HTML. The server-rendered
// LandingFooter (marketing/) reaches it by package path, and the floating SiteFooter opens
// it in a dialog. It renders none of the dialogs its entries open — see FamilyFooter's doc.
import type { MouseEvent, ReactElement, ReactNode } from 'react'
import { getSite, groupSitesByCategory, siteProdUrl, type SiteDef } from '@agentic-toolkit/adh-registry'
// Relative on purpose: PreviewNotice holds only per-instance state, so the copy this inlines
// into the footer entry forks nothing, and the header barrel is not this entry's to load.
import { PreviewNotice } from '../header/PreviewNotice'
import {
  BRAND_HREF,
  ADH_CONTACT,
  BRAND_LABEL,
  FAMILY_SITES,
  LANDING_FOOTER_CLASS,
  MORE_INFO_ANCHOR_ID,
  SITES_OVERVIEW_POPOVER_ID,
  type SiteContact,
} from './identity'
import { openLegalModal, PRIVACY_DIALOG_ID, TERMS_DIALOG_ID } from './LegalModals'

/** A plain link: the directory's entries, and the "This site" column a site passes. */
export type SiteLink = { label: string; href: string }

type Entry = SiteLink & {
  /** A small pill after the label: the platform of a native tool. */
  badge?: string
  onClick?: (event: MouseEvent<HTMLAnchorElement>) => void
}

type ColumnDef = { title: string; entries: Entry[] }

/** The column the native tools' sites gather in, out of whichever group the registry files
 *  them under, and the badge each one carries. Grouping is the footer's own: the registry
 *  keeps them in their category, which the header's site menu still reads. */
const NATIVE_TOOLS_TITLE = 'Native Tools'
const NATIVE_BADGE = 'macOS'

/** A native tool is listed by its full name (Agentic Developer Kitchen): its short one alone
 *  reads as a generic word next to the web sites. */
function siteEntry(site: SiteDef): Entry {
  return {
    label: site.nativeApp ? site.fullLabel ?? site.label : site.label,
    href: siteProdUrl(site.id, '/'),
    ...(site.nativeApp ? { badge: NATIVE_BADGE } : {}),
  }
}

/** The directory's site columns: the registry's groups, with the native tools pulled out of
 *  theirs into a Native Tools column placed right after the group they came from. */
function siteColumns(sites: SiteDef[]): ColumnDef[] {
  const columns: ColumnDef[] = []
  for (const group of groupSitesByCategory(sites)) {
    const web = group.sites.filter((s) => !s.nativeApp)
    const native = group.sites.filter((s) => s.nativeApp)
    if (web.length > 0) columns.push({ title: group.label, entries: web.map(siteEntry) })
    if (native.length > 0) columns.push({ title: NATIVE_TOOLS_TITLE, entries: native.map(siteEntry) })
  }
  return columns
}

/** Who makes the family. The studio's name and address are the copyright's own; FishLamp
 *  comes from its registry entry, so this column cannot drift from the sites overview. */
function aboutEntries(): Entry[] {
  const fishlamp = getSite('fishlamp')
  return [
    { label: BRAND_LABEL, href: BRAND_HREF },
    ...(fishlamp ? [{ label: fishlamp.label, href: siteProdUrl('fishlamp', '/') }] : []),
  ]
}

/** Terms and Privacy open in a scrolling dialog over the page (LegalModals); the hrefs stay,
 *  so a modified click, or a browser without the Popover API, still reaches the pages. */
const LEGAL_ENTRIES: Entry[] = [
  { label: 'Terms of Use', href: '/terms', onClick: openLegalModal(TERMS_DIALOG_ID) },
  { label: 'Privacy Policy', href: '/privacy', onClick: openLegalModal(PRIVACY_DIALOG_ID) },
]

function Column({ title, entries }: ColumnDef): ReactElement {
  return (
    <nav className="adh-landing-footer__column" aria-label={title}>
      <h3 className="adh-landing-footer__heading">{title}</h3>
      <ul className="adh-landing-footer__list">
        {entries.map((e) => (
          <li key={e.label} className="adh-landing-footer__item">
            <a className="adh-landing-footer__link" href={e.href} onClick={e.onClick}>
              {e.label}
            </a>
            {e.badge && <span className="adh-landing-footer__badge">{e.badge}</span>}
          </li>
        ))}
      </ul>
    </nav>
  )
}

export type FamilyFooterProps = {
  /** The build identity ({@link buildVersionLabel}); null when none was baked, and then the
   *  fine print simply has no version. */
  version: ReactNode
  /** A site's own links, as a "This site" column ahead of the directory. */
  links?: SiteLink[]
  /** Carry the drawer's More Info jump target (MORE_INFO_ANCHOR_ID). For the in-flow landing
   *  footer only: a page holds the id once, and SiteFooter's dialog copy must not repeat it. */
  anchored?: boolean
  /** Who the Contact column writes to; the hub by default. */
  contact?: SiteContact
}

/**
 * The family footer: a directory of the whole family, the way a store's site ends. The
 * preview badge heads it; then every group of sites as a column of plain links, the native
 * tools in a column of their own, who makes them, the legal pages, and the address to write to;
 * then one line of fine print with the copyright, the sites overview and the build.
 *
 * It is the landing page's footer (LandingFooter, in flow at the foot of `/`) and, on every
 * other page, what the floating `i` opens in a dialog (SiteFooter). Every link is in
 * the server HTML either way, so it is also the page's crawlable interlink set.
 *
 * Terms, Privacy and All sites open dialogs, and those dialogs are the CALLER's to
 * render, once per page: a dialog inside this footer would be inside SiteFooter's closed
 * dialog, which is `display: none`, and the header's site switcher opens the same sites
 * overview by id.
 */
export function FamilyFooter({
  version,
  links = [],
  anchored = false,
  contact = ADH_CONTACT,
}: FamilyFooterProps): ReactElement {
  const columns: ColumnDef[] = [
    ...(links.length > 0 ? [{ title: 'This site', entries: links }] : []),
    ...siteColumns(FAMILY_SITES),
    { title: 'About', entries: aboutEntries() },
    { title: 'Legal', entries: LEGAL_ENTRIES },
    { title: 'Contact', entries: [{ label: contact.email, href: `mailto:${contact.email}` }] },
  ]
  return (
    <div id={anchored ? MORE_INFO_ANCHOR_ID : undefined} className={LANDING_FOOTER_CLASS}>
      <div className="adh-landing-footer__head">
        <PreviewNotice variant="badge" />
      </div>
      <div className="adh-landing-footer__directory">
        {columns.map((column) => (
          <Column key={column.title} {...column} />
        ))}
      </div>
      <div className="adh-landing-footer__fine-print">
        <p className="adh-landing-footer__copyright">
          Copyright © {new Date().getFullYear()}{' '}
          <a className="adh-landing-footer__link" href={BRAND_HREF}>
            {BRAND_LABEL}
          </a>
          . All rights reserved.
        </p>
        <ul className="adh-landing-footer__legal">
          <li className="adh-landing-footer__item">
            <button
              type="button"
              className="adh-landing-footer__link adh-landing-footer__sites"
              popoverTarget={SITES_OVERVIEW_POPOVER_ID}
            >
              All sites
            </button>
          </li>
          {version && <li className="adh-landing-footer__item adh-landing-footer__version">{version}</li>}
        </ul>
      </div>
    </div>
  )
}
