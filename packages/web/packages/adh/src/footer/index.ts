'use client'

export { AdhFooter, FooterMenu } from './AdhFooter'
export type { AdhFooterProps, FooterLink, FooterMenuItem } from './AdhFooter'

// adh's registry-aware footer, merged in from the former `@adh/chrome/footer`. Renamed from that
// source's `AdhFooter` — this barrel already publishes an `AdhFooter` (the registry-free
// primitive above); the two are unrelated components that happened to share a name.
export { SiteFooter } from './SiteFooter'
export type { SiteFooterProps } from './SiteFooter'
export { SITES_OVERVIEW_POPOVER_ID, CONTACT_POPOVER_ID, FAMILY_FOOTER_DIALOG_ID } from './identity'
export type { SiteContact } from './identity'
// The family footer and the dialogs its entries open, for a footer that is not SiteFooter: the
// landing page's LandingFooter (marketing/), a server component, renders them by package path.
export { FamilyFooter } from './FamilyFooter'
export type { FamilyFooterProps, SiteLink } from './FamilyFooter'
export { ContactPopover } from './ContactPopover'
export { TermsModal, PrivacyModal } from './LegalModals'
// The family's half of the site template's drawer: its `drawer` and `drawerFoot` slots.
export { FamilyDrawerSection, MoreInfoDrawerFoot } from './FamilyDrawer'
// The panel itself, for a footer that is not SiteFooter: the landing page's LandingFooter
// (marketing/) renders it beside its own trigger.
export { SitesPopover } from './SitesOverview'
// For AppShell's `landingFooter` seam (layout/), which is a server component and so reaches
// these client pieces by package path: the route switch, and bitbag beside the landing footer.
export { FooterForRoute } from './FooterForRoute'
export type { FooterForRouteProps } from './FooterForRoute'
export { FooterChat } from './FooterChat'
// The seeded-backend primitives are exported because the Help sites reuse them
// (see sites/help/src/components/helpMockBackend.ts); the footer itself no longer
// does — bitbag speaks his own scripted voice through BitbagDock.
export { BITBAG_PERSONA, createSeededBackend } from './seededBackend'
export type { SeededReply, SeededBackendOptions } from './seededBackend'
// Exported for the hub's Debug console, the only writer — see the module doc for
// why the theme travels as a prop rather than as a host-scoped <style>.
export { useChatTheme } from './chat-theme-store'
