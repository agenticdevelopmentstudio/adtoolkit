import type { ReactElement } from "react";
import { type SiteContact } from "../footer/identity";
export { LANDING_FOOTER_CLASS } from "../footer/identity";
export type LandingFooterProps = {
    /** Who the Contact entry writes to. The family's sites write to the hub (the default); the
     *  studio and FishLamp Design pass their own. */
    contact?: SiteContact;
};
/**
 * The landing page's footer: the family footer (FamilyFooter) in flow at the foot of `/`, with
 * the dialogs its entries open, one each.
 *
 * For the `/` of a templated site, through the template's `footer` slot. It is a server
 * component and draws no floating copyright: the routes under `MarketingShell` keep
 * `SiteFooter`, and bitbag stays where the frame pins him. Every link is in the server HTML,
 * so the directory is also the page's crawlable interlink set.
 *
 * The directory and the panel "All sites" opens both list FAMILY_SITES.
 */
export declare function LandingFooter({ contact }?: LandingFooterProps): ReactElement;
//# sourceMappingURL=LandingFooter.d.ts.map