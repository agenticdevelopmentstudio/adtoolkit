import type { ReactElement } from "react";
/** The class on the footer's root element: the scope a site confines its stylesheet to
 *  (`/*! @confine .adh-landing-footer *\/`). */
export declare const LANDING_FOOTER_CLASS = "adh-landing-footer";
/**
 * The landing page's footer: a directory of the whole family, the way a store's site ends —
 * every group of sites as a column of plain links, who makes them, then one line of fine print
 * with the legal pages, the sites overview and the build.
 *
 * For the `/` of a templated site, through the template's `footer` slot. It is a server
 * component and draws no fixed bar: the routes under `MarketingShell` keep `SiteFooter`, and
 * bitbag stays where the frame pins him. Every link is in the server HTML, so the directory is
 * also the page's crawlable interlink set.
 *
 * The directory and the panel "All sites" opens both list LANDING_SITES: the family's
 * working sites (DIRECTORY_SITES, without the marketing decks and the placeholders), less
 * the few the landing page leaves out.
 */
export declare function LandingFooter(): ReactElement;
//# sourceMappingURL=LandingFooter.d.ts.map