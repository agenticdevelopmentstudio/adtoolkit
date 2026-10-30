import type { ReactElement } from "react";
// The client pieces by package path: each is 'use client', and a relative specifier would
// inline it and hoist its directive over this server entry (see MarketingFrameHeader).
import {
  ContactPopover,
  FamilyFooter,
  PrivacyModal,
  SitesPopover,
  TermsModal,
} from "@agentic-toolkit/adh/footer";
// Relative, deliberately: identity holds constants and one pure function, no state and no
// directive, so the copy inlined here forks nothing.
import { ADH_CONTACT, FAMILY_SITES, buildVersionLabel, type SiteContact } from "../footer/identity";

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
export function LandingFooter({ contact = ADH_CONTACT }: LandingFooterProps = {}): ReactElement {
  return (
    <>
      <FamilyFooter version={buildVersionLabel()} />
      <SitesPopover sites={FAMILY_SITES} />
      <ContactPopover contact={contact} />
      <TermsModal />
      <PrivacyModal />
    </>
  );
}
