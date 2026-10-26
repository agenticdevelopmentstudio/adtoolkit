import { ADMIN_SITE_IDS } from '@agentic-toolkit/adh-registry'
// `import type` at the STATEMENT level, not per-specifier: `hub-rail-groups.ts` is published
// as its own entry so the hub's data layer can read this tree without the header barrel, and
// a per-specifier form is only guaranteed to erase the specifiers — leaving a bare
// `import './SiteMenu'` would pull the whole menu component into that entry to import nothing.
import type { MenuGroup, MenuLink } from './SiteMenu'

// ─────────────────────────────────────────────────────────────────────────────
// The fleet tree — the whole family as ten rows, used identically by BOTH the
// marketing (logged-out) and workspace (logged-in) menus. Every row here is a
// site anyone may visit; the rows that DO depend on a session (Home, Workspaces,
// Recents, Login/Sign up) are the chrome {@link SiteMenu} builds around this —
// Recents at the head of this very block. The one exception is
// {@link ADMIN_MENU_GROUPS} below, which is a separate export precisely so that
// this one stays unconditional.
//
// Shape: seven of the ten open a submenu, and five of those seven are a link as
// well — "Hub" opens the hub's own pages and IS the hub. The other two ('Plan',
// 'Build') are grouping headers with nowhere of their own to go, because the
// family has no plan.* or build.* site; they exist to give the sites underneath
// them a name. The remaining three rows (Bitbag, Messages, Organizations) are
// plain destinations with nothing under them.
//
// Every row carries an icon and a short trailing tagline. A `{ site }` row takes
// both from the registry unless it says otherwise here, so this file states a
// label or a description only where the registry's would read wrong IN A MENU —
// restating the registry's copy is how the two drift.
//
// ⚠️ The groups MIRROR `SITE_CATEGORIES` in the registry (the footer "sites
// overview"): same labels, same order, and the same site in the same group. They
// are the same answer to "where does this site live?" on two surfaces. Change one,
// change the other; a registry test pins the labels from its side.
//
// The two surfaces are not the same LIST, though, and neither is a subset of the
// other: this tree promotes Bitbag, Messages and Organizations to top-level rows
// (the overview has no such shape, so it files them under Hub) and adds the Studio's
// absolute href, while the overview additionally carries the sites with no menu
// row at all (fishlamp, fishlampdesign, mcp). Only the grouping is shared.
//
// The public tree sits in ONE section (1), so it reads as a single block with one
// divider above it (the chrome, section 0); the admin block below it is section 2,
// which is what puts a divider between them.

/** The section every fleet row carries. See the module comment. */
export const FLEET_SECTION = 1

/** The section {@link ADMIN_MENU_GROUPS} carries — one more than the fleet's, so a
 *  divider falls between the family and the consoles. */
export const ADMIN_SECTION = FLEET_SECTION + 1

/** The section of the site menu's Help / Contact block — one more than the fleet's, so a
 *  divider falls above it. It shares ADMIN_SECTION's number, which is safe only because
 *  the site menu never shows the admin block (MarketingSiteMenu). */
export const HELP_SECTION = FLEET_SECTION + 1

/** A top-level row that is a destination and nothing else. `blurb` surfaces its
 *  description as the trailing tagline, matching every other row. */
function leaf(link: MenuLink): MenuGroup {
  return { kind: 'leaf', section: FLEET_SECTION, blurb: true, link }
}

/** A top-level row that opens a flyout. `link` makes the trigger a destination
 *  too (click navigates, hover/→ still opens); omit it for a grouping header. */
function topic(t: {
  label: string
  description: string
  iconKey?: string
  link?: MenuLink
  links: MenuLink[]
}): MenuGroup {
  return { kind: 'topic', section: FLEET_SECTION, ...t }
}

/**
 * The family, in the order it is meant to be read.
 *
 * A constant rather than a builder: it takes no arguments, and a stable identity
 * is what keeps {@link useSiteMenu}'s `entries` memo from re-deriving every row
 * on every render.
 */
export const FLEET_MENU_GROUPS: MenuGroup[] = [
  leaf({ site: 'bitbag', description: "The hub's AI persona" }),
  leaf({ site: 'messages', description: 'Your messages, everywhere' }),
  topic({
    label: 'Hub',
    description: 'The center of it all',
    link: { site: 'hub' },
    links: [
      { site: 'news' },
      { site: 'status' },
      // A hub ROUTE, not a site: `/contact` exists on the hub and is resolved through
      // it from every other site (see useSiteMenu's routeHref).
      { route: '/contact', label: 'Contact', description: 'Get in touch' },
      { site: 'community' },
      // hub-help (help.adh.com), not the delisted 'help' landing — the family's Help
      // destination since its promotion. Its key is the site id, so it stays distinct
      // from the Help-MODAL action row SiteMenu adds to the chrome above.
      { site: 'hub-help' },
      { site: 'support' },
      { site: 'store' },
      // A page of hub-help, not `{ route: '/details' }`: the hub's `/details` brochure was
      // folded into its landing and only redirects to `/` now, so "Details" is the help site's
      // hub overview. `{ site, path }` rather than a written-out URL, so it keeps its per-env
      // host and SSO wrap (fleetMenuGroups.test pins why an absolute row to a real site is a
      // defect).
      {
        site: 'hub-help',
        path: '/hub/~overview',
        label: 'Details',
        description: 'What the hub does',
        iconKey: '/details',
      },
    ],
  }),
  leaf({ site: 'orgs' }),
  topic({
    label: 'Learn',
    description: 'Guides & courses',
    iconKey: 'learn',
    link: { site: 'help' },
    links: [
      { site: 'academy' },
      // hub-help again, NOT the 'help' landing this topic itself links to. Two reasons,
      // both from the registry: a family "Help" link points at hub-help by rule (see the
      // note above SiteDef 'help' in registry.ts), and `{ site: 'help' }` here would
      // resolve to the identical href as the Learn trigger above it — a row whose only
      // effect is to repeat its own parent. So Hub ▸ Help and Learn ▸ Help are one
      // destination reached from two groups, which is why they read the same.
      { site: 'hub-help' },
    ],
  }),
  topic({
    label: 'Plan',
    description: 'Decide what to build',
    iconKey: 'plan',
    links: [
      { site: 'projects' },
      { site: 'narratives', description: 'Your development story' },
      // The registry calls this site "Notebook"; the menu row is "Notes", so the
      // registry's own tagline ("Notes & notebooks") would echo the row's label.
      { site: 'notebook', label: 'Notes', description: 'Your notebook' },
      { site: 'research' },
      { site: 'docs' },
    ],
  }),
  topic({
    label: 'Build',
    description: 'Make it',
    iconKey: 'build',
    links: [
      { site: 'devteam', label: 'Dev Team' },
      { site: 'codereviews', description: 'Review your code' },
      { site: 'cookbook' },
      { site: 'recipes' },
      { site: 'toolkit' },
      { site: 'tools' },
      { site: 'testing' },
      { site: 'shipr' },
      { site: 'kitchen' },
      { site: 'stenographer' },
    ],
  }),
  topic({
    label: 'Personas',
    description: 'Your agentic personas',
    link: { site: 'personas' },
    links: [
      { site: 'personabuilder' },
      { site: 'personaregistry' },
      { site: 'knowledgebases', label: 'Knowledge' },
      { site: 'teambuilder' },
      { site: 'teamregistry' },
      { site: 'myagenticteams', label: 'My Agentic Teams', description: 'Your own agentic teams' },
    ],
  }),
  topic({
    label: 'Products',
    description: 'Your product platform',
    link: { site: 'products' },
    links: [
      { site: 'storage', label: 'Storage Buckets' },
      { site: 'ecosystems' },
      { site: 'authentication' },
      { site: 'customers' },
      { site: 'billing' },
      { site: 'messaging', description: 'Email & SMS for your products' },
      { site: 'notifications' },
      { site: 'sites' },
      { site: 'communities' },
      { site: 'dashboards' },
      { site: 'devices' },
      { site: 'domains' },
      { site: 'education' },
      { site: 'integrations' },
      { site: 'registries' },
      { site: 'gamification' },
      { site: 'games' },
      { site: 'stores' },
    ],
  }),
  topic({
    label: 'Hire',
    description: 'Get expert help',
    link: { site: 'consulting' },
    links: [
      { site: 'consultants' },
      // Was an absolute href while the family had no registry site; it is a real
      // registry entry now, so the row is env-aware and SSO-wrapped like the rest.
      { site: 'registry' },
      // The studio the family sits under. An absolute href, not a `{ site }`: the
      // Agentic Development Studio has no app in this repo and deliberately no
      // registry entry (`registry.test.ts` pins that agenticdevelopmentstudio.com is
      // NOT a registry host — a registry entry would silently re-add the origin to
      // the OAuth return allowlist and to the generated route map). See MenuLink's
      // `href` variant for the three things this row therefore does without.
      {
        href: 'https://agenticdevelopmentstudio.com',
        label: 'Agentic Development Studio',
        description: 'The studio behind the Hub',
        iconKey: 'consulting',
      },
    ],
  }),
]

/**
 * The site menu EVERY site shows on its marketing pages (MarketingSiteMenu), cut down to
 * the seven sites the repo owner chose (Mike, 2026-10-23): the hub, Help (hub-help),
 * Bitbag, Dev Team, Cookbook, Toolkit and Persona Registry. It began as the hub's own
 * menu, with satellites keeping the whole {@link FLEET_MENU_GROUPS}; the owner ruled that
 * the menu is shared code and every site gets this same one (Mike, 2026-10-25).
 *
 * Every site is its OWN top-level row (Mike, 2026-10-24): with only seven of them there is
 * nothing to fold away, so the fleet tree's grouping headers (`Build`) and its Hub ▸ Help
 * nesting are dropped here — a site one hover deep in a seven-row menu is a site the
 * visitor has to hunt for. Hub is a plain row too: its Contact / Details submenu went the
 * same day, at the owner's word.
 *
 * Help and Contact are a block of their own at the foot, below a divider and just above
 * the studio wordmark (Mike, 2026-10-24): they are where to go for help with the family,
 * not members of it. Details went with the Hub submenu; it was the help site's overview of
 * the hub, which Help itself now reaches.
 *
 * A separate constant, not a filter over the fleet tree: `hub-rail-groups.ts` derives the
 * hub's rail from FLEET_MENU_GROUPS, so the fleet tree has to stay whole, and a filter would
 * leave Plan, Learn and the rest as empty triggers. Each row reads the same as its
 * counterpart in the fleet tree (same label, same tagline).
 */
export const SITE_MENU_GROUPS: MenuGroup[] = [
  leaf({ site: 'bitbag', description: "The hub's AI persona" }),
  leaf({ site: 'hub', description: 'The center of it all' }),
  leaf({ site: 'devteam', label: 'Dev Team' }),
  leaf({ site: 'cookbook' }),
  leaf({ site: 'toolkit' }),
  leaf({ site: 'personaregistry' }),
  { kind: 'leaf', section: HELP_SECTION, blurb: true, link: { site: 'hub-help' } },
  {
    kind: 'leaf',
    section: HELP_SECTION,
    blurb: true,
    // A hub ROUTE, as in the fleet tree's Hub ▸ Contact.
    link: { route: '/contact', label: 'Contact', description: 'Get in touch' },
  },
]

/**
 * The consoles, for admins only — rendered by {@link SiteMenu} beneath the fleet
 * tree when (and ONLY when) the header resolves the signed-in user as an adh
 * admin. A separate export rather than a flag on a row in the tree above, because
 * the tree above is what every visitor sees and is worth being able to read as
 * exactly that.
 *
 * The two site rows are derived from the registry's {@link ADMIN_SITE_IDS} — the
 * sites marked `adminOnly`, the same fact that keeps them out of the footer's
 * sites overview — so the set an admin is shown and the set everyone else is
 * denied cannot drift apart. The third row is the fleet monitor, which is a
 * backend service rather than a family site and so has no registry entry to
 * derive from.
 *
 * ⚠️ Gating a MENU is not authorization. Each console does its own; this only
 * decides who is shown the door.
 */
export const ADMIN_MENU_GROUPS: MenuGroup[] = [
  {
    kind: 'topic',
    section: ADMIN_SECTION,
    label: 'Admin',
    description: 'Operations consoles',
    iconKey: 'admin',
    links: [
      ...ADMIN_SITE_IDS.map((site): MenuLink => ({ site })),
      {
        href: 'https://lewis.agenticdeveloperhub.com',
        label: 'Fleet Monitor',
        description: 'What every service is doing',
        iconKey: 'monitor',
      },
    ],
  },
]
