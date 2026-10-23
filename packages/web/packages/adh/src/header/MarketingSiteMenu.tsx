'use client'

import { type ReactElement } from 'react'
import { SiteMenu, type SiteMenuChromeProps } from './SiteMenu'
import { FLEET_MENU_GROUPS, HUB_LANDING_MENU_GROUPS } from './fleetMenuGroups'

// ─────────────────────────────────────────────────────────────────────────────
// MARKETING site menu — the public browse experience, shown on the marketing
// landing `/` (and every non-app context: satellites, signed out). CONFIG ONLY:
// it supplies the tree; the auth-conditional chrome around it — Login / Sign up
// when signed out, Home / Workspaces / Recents when signed in — is added by SiteMenu.
//
// On the hub the tree is HUB_LANDING_MENU_GROUPS, the seven sites the repo owner
// chose for the hub's own pages; every other host gets the whole FLEET_MENU_GROUPS.
// The hub's version also carries no settings gear: the owner took it off the
// landing menu (Mike, 2026-10-23), so the search row falls back to the "?" sites
// overview button, as it does signed out. User Settings is still the avatar menu's
// row, and the workspace menu keeps its gear.
//
// Kept as its own component (distinct from the workspace menu) so the two can
// diverge without churn. The built-in search/filter box is always present
// (rendered by SiteMenu itself).
//
// Both trees are module constants, so they pass straight through — no memo needed to
// give them a stable identity. That is only ONE of `entries`' dependencies; the other
// that changes per render if nobody holds it still is the SSO resolver, which
// `ssoSwitchResolver` keeps stable at module scope for the same reason.
export function MarketingSiteMenu(props: SiteMenuChromeProps): ReactElement {
  if (props.currentSiteId === 'hub') {
    return (
      <SiteMenu
        groups={HUB_LANDING_MENU_GROUPS}
        {...props}
        onSettings={undefined}
        settingsHref={undefined}
      />
    )
  }
  return <SiteMenu groups={FLEET_MENU_GROUPS} {...props} />
}
