import { type SiteDef } from '@agentic-toolkit/adh-registry';
/** The class on the family footer's root element: the scope a site confines its stylesheet to
 *  (`/*! @confine .adh-landing-footer *\/`). Here rather than beside FamilyFooter, which is
 *  'use client': a server module importing it from there would get a client reference. */
export declare const LANDING_FOOTER_CLASS = "adh-landing-footer";
/** The sites the family footer lists: the directory less the ones it leaves out. The panel
 *  its "All sites" opens on the landing page lists the same set (SitesPopover's `sites`). */
export declare const FAMILY_SITES: SiteDef[];
export declare const BRAND_LABEL = "Agentic Development Studio";
export declare const BRAND_HREF = "https://agenticdevelopmentstudio.com/";
/** The DOM id of the single shared sites-overview popover. The footer renders
 *  the panel once; every trigger (the "Sites" entry in the footer's copyright
 *  menu, the header site-switcher's "?" icon and its "help" command) opens it by this id, so
 *  there's exactly one instance — and therefore one crawlable copy of the SEO
 *  interlink set. */
export declare const SITES_OVERVIEW_POPOVER_ID = "adh-sites-overview";
/** Who a site's Contact entry writes to: the name its dialog is titled with and the address
 *  it links. Per site, unlike the copyright: a family site writes to the hub, and the studio
 *  and FishLamp Design each to their own (they pass theirs to `LandingFooter`). */
export type SiteContact = {
    name: string;
    email: string;
};
/** The family's own contact, the default for every site that does not pass one. */
export declare const ADH_CONTACT: SiteContact;
/** The DOM id of the Contact dialog, opened from the footer's fine print. One per page, for
 *  the same reason as the sites overview's. */
export declare const CONTACT_POPOVER_ID = "adh-contact";
/** The DOM id of the dialog the floating copyright opens: the whole family footer, the one
 *  the landing page ends with, over the page. */
export declare const FAMILY_FOOTER_DIALOG_ID = "adh-family-footer";
/** The id of the landing page's family band, the cards of the family's sites: what the drawer's
 *  Family row jumps to (`/#family`). The band is the page's content, so the id is its heading's. */
export declare const FAMILY_BAND_ID = "family";
/** The id the in-flow landing footer carries, once per page: what the drawer's More Info row
 *  jumps to (`/#more-info`). */
export declare const MORE_INFO_ANCHOR_ID = "more-info";
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
export declare function buildVersionLabel(live?: {
    version?: string;
    sha?: string;
}): import("react").JSX.Element | null;
//# sourceMappingURL=identity.d.ts.map