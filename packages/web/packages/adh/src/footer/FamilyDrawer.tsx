'use client'

// The family's half of the site template's drawer: its `drawer` slot (the family, after the
// page's rows) and its `drawerFoot` slot (More Info, in the foot). A client module because the
// foot's Contact, Terms and Privacy open their dialogs rather than load a route.
import type { MouseEvent, ReactElement } from 'react'
import { NavSection } from '@agenticdevelopertoolkit/landing'
import { getSite, siteProdUrl } from '@agentic-toolkit/adh-registry'
import { FLEET_SECTION, HELP_SECTION, SITE_MENU_GROUPS } from '../header/fleetMenuGroups'
import type { MenuLink } from '../header/SiteMenu'
import { CONTACT_POPOVER_ID } from './identity'
import { openLegalModal, PRIVACY_DIALOG_ID, TERMS_DIALOG_ID } from './LegalModals'

type DrawerLink = { label: string; href: string; onClick?: (event: MouseEvent<HTMLAnchorElement>) => void }

/** The hub route Contact names in the site menu, which here opens the Contact dialog. */
const CONTACT_ROUTE = '/contact'

/** A site-menu row as a drawer link: a site at its production home, a hub route on the hub. */
function drawerLink(link: MenuLink): DrawerLink | null {
  if ('site' in link) {
    const label = link.label ?? getSite(link.site)?.label
    return label === undefined ? null : { label, href: siteProdUrl(link.site, link.path ?? '/') }
  }
  if ('route' in link) {
    return {
      label: link.label,
      href: siteProdUrl('hub', link.route),
      ...(link.route === CONTACT_ROUTE ? { onClick: openLegalModal(CONTACT_POPOVER_ID) } : {}),
    }
  }
  return { label: link.label, href: link.href }
}

/** The site menu's rows in one of its sections, in its order: the drawer lists what the
 *  header's menu lists, so the two cannot drift. */
function sectionLinks(section: number): DrawerLink[] {
  return SITE_MENU_GROUPS.flatMap((group) => {
    if (group.kind === 'topic' || group.section !== section) return []
    const link = drawerLink(group.link)
    return link === null ? [] : [link]
  })
}

/** Terms and Privacy, as the family footer's Legal column opens them. */
const LEGAL_LINKS: DrawerLink[] = [
  { label: 'Terms of Use', href: '/terms', onClick: openLegalModal(TERMS_DIALOG_ID) },
  { label: 'Privacy Policy', href: '/privacy', onClick: openLegalModal(PRIVACY_DIALOG_ID) },
]

/**
 * The family, as the drawer's last section: the sites of the header's site menu, as drawer
 * rows. For the site template's `drawer` slot.
 */
export function FamilyDrawerSection(): ReactElement {
  return (
    <NavSection title="Family">
      {sectionLinks(FLEET_SECTION).map((link) => (
        <a key={link.href} className="lp-nav" href={link.href}>
          {link.label}
        </a>
      ))}
    </NavSection>
  )
}

/**
 * More Info, in the drawer's foot: the site menu's Help and Contact, then Terms and Privacy.
 * For the site template's `drawerFoot` slot. Contact, Terms and Privacy open the dialogs the
 * page's footer renders (LandingFooter, SiteFooter); their hrefs stay, so a modified click or a
 * browser without the Popover API still reaches the pages.
 */
export function MoreInfoDrawerFoot(): ReactElement {
  return (
    <NavSection title="More Info">
      {[...sectionLinks(HELP_SECTION), ...LEGAL_LINKS].map((link) => (
        <a key={link.label} href={link.href} onClick={link.onClick}>
          {link.label}
        </a>
      ))}
    </NavSection>
  )
}
