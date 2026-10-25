import type { MenuGroup } from './SiteMenu';
/** The section every fleet row carries. See the module comment. */
export declare const FLEET_SECTION = 1;
/** The section {@link ADMIN_MENU_GROUPS} carries — one more than the fleet's, so a
 *  divider falls between the family and the consoles. */
export declare const ADMIN_SECTION: number;
/** The section of the site menu's Help / Contact block — one more than the fleet's, so a
 *  divider falls above it. It shares ADMIN_SECTION's number, which is safe only because
 *  the site menu never shows the admin block (MarketingSiteMenu). */
export declare const HELP_SECTION: number;
/**
 * The family, in the order it is meant to be read.
 *
 * A constant rather than a builder: it takes no arguments, and a stable identity
 * is what keeps {@link useSiteMenu}'s `entries` memo from re-deriving every row
 * on every render.
 */
export declare const FLEET_MENU_GROUPS: MenuGroup[];
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
export declare const SITE_MENU_GROUPS: MenuGroup[];
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
export declare const ADMIN_MENU_GROUPS: MenuGroup[];
//# sourceMappingURL=fleetMenuGroups.d.ts.map