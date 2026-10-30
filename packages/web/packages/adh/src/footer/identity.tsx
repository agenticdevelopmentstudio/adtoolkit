// The footer's facts that are not React state: the studio's name and address, the sites
// overview's DOM id, and the build identity. No 'use client' directive, on purpose: the
// server-rendered LandingFooter (marketing/) needs these as real values, and a server module
// importing a constant from a client module gets a client reference, not the string.

import {
  DIRECTORY_SITES,
  FOOTER_SITES,
  getSite,
  groupSitesByCategory,
  siteProdUrl,
  type SiteDef,
  type SiteId,
} from '@agentic-toolkit/adh-registry'

/** The class on the family footer's root element: the scope a site confines its stylesheet to
 *  (`/*! @confine .adh-landing-footer *\/`). Here rather than beside FamilyFooter, which is
 *  'use client': a server module importing it from there would get a client reference. */
export const LANDING_FOOTER_CLASS = 'adh-landing-footer'

/** Working sites the family footer does not link: Shipr and the Registry, and both FishLamp
 *  doors, since FishLamp Design is linked once, from About. */
const FAMILY_OMITTED = new Set<SiteId>(['shipr', 'registry', 'fishlamp', 'fishlampdesign'])

/** The sites the family footer lists: the directory less the ones it leaves out. */
export const FAMILY_SITES: SiteDef[] = DIRECTORY_SITES.filter((s) => !FAMILY_OMITTED.has(s.id))

// The company the copyright belongs to — Agentic Development Studio, which is also
// the wordmark closing the site menu (see StudioWordmark). NOT FishLamp Design, which
// the copyright used to name and which is still a family site with its own row.
//
// A literal href rather than `siteProdUrl(...)`: the studio deliberately has no
// registry entry (a `registry.test.ts` case pins that agenticdevelopmentstudio.com is
// not a registry host, because an entry would re-add the origin to the OAuth
// return-origin allowlist and to the generated route map). Same reason the menu's
// studio row is an absolute `{ href }`.
export const BRAND_LABEL = 'Agentic Development Studio'
export const BRAND_HREF = 'https://agenticdevelopmentstudio.com/'

/** One row of the "All sites" panel (SitesPopover): a name, a line saying what it is, and where
 *  it goes. */
export type SitesPanelEntry = { key: string; label: string; href: string; description?: string }

/** A group of the "All sites" panel, titled like the registry's SITE_CATEGORIES. */
export type SitesPanelGroup = { label: string; entries: SitesPanelEntry[] }

function siteEntry(site: SiteDef): SitesPanelEntry {
  return { key: site.id, label: site.label, href: siteProdUrl(site.id, '/'), description: site.description }
}

function registryEntry(id: SiteId): SitesPanelEntry {
  const site = getSite(id)
  if (!site) throw new Error(`no registry site '${id}'`)
  return siteEntry(site)
}

/** What the panel lists beyond FOOTER_SITES, each with the group it files under. The four the
 *  registry delists (`listed: false`) are still served, each from its own app, so the panel
 *  links them; SITE_CATEGORIES may name only listed sites, so their group is set here. The
 *  studio and My Agentic Projects have no registry entry at all (the studio deliberately; see
 *  BRAND_HREF above), so their rows are literal. */
const SITES_PANEL_ADDITIONS: { group: string; entry: SitesPanelEntry }[] = [
  // By its full name: the hub's own Help is in the panel too, under Hub.
  { group: 'Learn', entry: { ...registryEntry('help'), label: 'Agentic Developer Help' } },
  { group: 'Plan', entry: { key: 'myagenticprojects', label: 'My Agentic Projects', href: 'https://myagenticprojects.com/', description: 'Agentic software projects' } },
  { group: 'Build', entry: registryEntry('recipes') },
  { group: 'Products', entry: registryEntry('education') },
  { group: 'Hire', entry: registryEntry('consulting') },
  { group: 'Hire', entry: { key: 'studio', label: BRAND_LABEL, href: BRAND_HREF, description: 'The studio behind the Hub' } },
]

/** The "All sites" panel: every site the family serves, grouped. FOOTER_SITES in the registry's
 *  groups, with SITES_PANEL_ADDITIONS appended to theirs. The same on every page, the landing
 *  page included. */
export function sitesPanelGroups(): SitesPanelGroup[] {
  const groups: SitesPanelGroup[] = groupSitesByCategory(FOOTER_SITES).map((g) => ({
    label: g.label,
    entries: g.sites.map(siteEntry),
  }))
  for (const { group, entry } of SITES_PANEL_ADDITIONS) {
    const target = groups.find((g) => g.label === group)
    if (!target) throw new Error(`no "All sites" group '${group}'`)
    target.entries.push(entry)
  }
  return groups
}

/** The DOM id of the single shared sites-overview popover. The footer renders
 *  the panel once; every trigger (the "Sites" entry in the footer's copyright
 *  menu, the header site-switcher's "?" icon and its "help" command) opens it by this id, so
 *  there's exactly one instance — and therefore one crawlable copy of the SEO
 *  interlink set. */
export const SITES_OVERVIEW_POPOVER_ID = 'adh-sites-overview'

/** Who a site's Contact column writes to: whose address it is, and the address it links. Per
 *  site, unlike the copyright: a family site writes to the hub, and the studio and FishLamp
 *  Design each to their own (they pass theirs to `LandingFooter`). */
export type SiteContact = { name: string; email: string }

/** The family's own contact, the default for every site that does not pass one. */
export const ADH_CONTACT: SiteContact = {
  name: 'Agentic Developer Hub',
  email: 'hello@agenticdeveloperhub.com',
}

/** The DOM id of the dialog the floating copyright opens: the whole family footer, the one
 *  the landing page ends with, over the page. */
export const FAMILY_FOOTER_DIALOG_ID = 'adh-family-footer'

/** The id of the landing page's family band, the cards of the family's sites: what the drawer's
 *  Hub Websites row jumps to (`/#family`). The band is the page's content, so the id is its heading's. */
export const FAMILY_BAND_ID = 'family'

/** The id the in-flow landing footer carries, once per page: what the drawer's More Info row
 *  jumps to (`/#more-info`). */
export const MORE_INFO_ANCHOR_ID = 'more-info'

/** The footer's build identity: `v1.0.155 · a73e79b7`, or null when neither field exists.
 *
 *  Two fields doing two jobs. The semver is hand-bumped and scoped to ONE site's
 *  directory, so it answers "did my change ship?"; the SHA is stamped on every
 *  build from any cause — including a submodule bump that touched no file under
 *  the site — so it answers "which build is this?". Each covers the other's blind
 *  spot: a version alone only moves when someone remembers, and a bare SHA means
 *  nothing unless you happen to be holding the commit you deployed.
 *
 *  Both are read as literal `process.env.NEXT_PUBLIC_*` expressions so Next's
 *  build-time substitution reaches them (the same mechanism TelemetryProvider
 *  already round-trips for NEXT_PUBLIC_ADH_RELEASE). Exported for the contract test.
 *
 *  The title carries the FULL sha rather than a build timestamp: a timestamp would
 *  make every build's bundle differ from identical source, and this repo has already
 *  paid for non-reproducible artifacts once.
 *
 *  `live` overrides either field, and exists for exactly one mode. Under `next build`
 *  the literals below ARE the build, so nothing overrides them and this argument is
 *  never passed. Under `next dev` they freeze at dev-server boot and then keep
 *  reporting the commit the session started on for as long as it runs — which is how
 *  a bumped `VERSION` could show nothing on screen. AppShell (a Server Component)
 *  resolves the real pair per render and passes it down; see `liveBuildIdentity`.
 *  A field it could not read with confidence arrives `undefined` and the baked
 *  literal shows through, so this can only ever correct a value, never blank one.
 *
 *  @param live the running server's own identity, in development only. */
export function buildVersionLabel(live?: { version?: string; sha?: string }) {
  const version = live?.version ?? process.env.NEXT_PUBLIC_ADH_SITE_VERSION ?? ''
  const sha = live?.sha ?? process.env.NEXT_PUBLIC_ADH_RELEASE ?? ''
  const label = [version && `v${version}`, sha && sha.slice(0, 8)].filter(Boolean).join(' · ')
  if (!label) return null
  return <span title={sha || undefined}>{label}</span>
}
