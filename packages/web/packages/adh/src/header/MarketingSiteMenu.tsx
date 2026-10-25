'use client'

import { type ReactElement } from 'react'
import { SiteMenu, type SiteMenuChromeProps } from './SiteMenu'
import { SITE_MENU_GROUPS } from './fleetMenuGroups'

// ─────────────────────────────────────────────────────────────────────────────
// MARKETING site menu — the public browse experience, shown on the marketing
// landing `/` (and every non-app context: satellites, signed out). CONFIG ONLY:
// it supplies the tree; the auth-conditional chrome around it — Login / Sign up
// when signed out — is added by SiteMenu.
//
// EVERY site renders this same menu, the hub and the satellites alike (Mike,
// 2026-10-25): the menu is shared code, so a visitor meets one menu wherever they are
// in the family. It began as the hub's own cut (2026-10-23/24) while satellites kept the
// whole FLEET_MENU_GROUPS, and the owner ruled that per-site variant wrong. So there is
// deliberately no branch on `currentSiteId` here — do not add one back.
//
// The tree is SITE_MENU_GROUPS: the six sites the owner chose, then the Help / Contact
// block. It carries no settings gear: the owner took it off (Mike, 2026-10-23). The "?"
// sites-overview button that took its place went the next day (Mike, 2026-10-24), so the
// search row has no trailing control. User Settings is still the avatar menu's row, and
// the hub's workspace menu keeps its gear.
//
// It also drops SiteMenu's own chrome rows — Home, Workspaces and the Help modal row
// (Mike, 2026-10-24) — so it is the sites and the Help / Contact block, nothing else.
// Signed out it still opens on Login / Sign up.
//
// Nor does it carry the Admin consoles, for an admin or anyone else (Mike, 2026-10-24).
// The hub's workspace routes swap in the WorkspaceMenu, which never had them (see
// SiteMenuSwitcher), so an admin reaches the consoles by their own addresses.
//
// Kept as its own component (distinct from the workspace menu) so the two can
// diverge without churn. The built-in search/filter box is always present
// (rendered by SiteMenu itself).
//
// The tree is a module constant, so it passes straight through — no memo needed to
// give it a stable identity. That is only ONE of `entries`' dependencies; the other
// that changes per render if nobody holds it still is the SSO resolver, which
// `ssoSwitchResolver` keeps stable at module scope for the same reason.
export function MarketingSiteMenu(props: SiteMenuChromeProps): ReactElement {
  return (
    <SiteMenu
      groups={SITE_MENU_GROUPS}
      {...props}
      onSettings={undefined}
      settingsHref={undefined}
      userIsAdmin={false}
      omitChromeRows
      omitHelpButton
    />
  )
}
