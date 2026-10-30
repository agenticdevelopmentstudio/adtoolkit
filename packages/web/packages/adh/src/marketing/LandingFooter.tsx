import type { ReactElement } from "react";
import {
  DIRECTORY_SITES,
  getSite,
  groupSitesByCategory,
  siteProdUrl,
  type SiteDef,
  type SiteId,
} from "@agentic-toolkit/adh-registry";
// The panel by package path: SitesOverview is 'use client', and a relative specifier would
// inline it and hoist its directive over this server entry (see MarketingFrameHeader).
import { SitesPopover } from "@agentic-toolkit/adh/footer";
// Relative, deliberately: identity holds constants and one pure function, no state and no
// directive, so the copy inlined here forks nothing.
import {
  BRAND_HREF,
  BRAND_LABEL,
  SITES_OVERVIEW_POPOVER_ID,
  buildVersionLabel,
} from "../footer/identity";

/** The class on the footer's root element: the scope a site confines its stylesheet to
 *  (`/*! @confine .adh-landing-footer *\/`). */
export const LANDING_FOOTER_CLASS = "adh-landing-footer";

type FooterEntry = { label: string; href?: string };

/** Working sites the landing page does not link: Shipr and the Registry, and both FishLamp
 *  doors, since FishLamp Design is linked once, from About. */
const LANDING_OMITTED = new Set<SiteId>(["shipr", "registry", "fishlamp", "fishlampdesign"]);

/** The sites the landing footer lists: the directory less the ones it leaves out. */
const LANDING_SITES: SiteDef[] = DIRECTORY_SITES.filter((s) => !LANDING_OMITTED.has(s.id));

/** Who makes the family. The studio's name and address are the copyright's own; FishLamp
 *  comes from its registry entry, so this column cannot drift from the sites overview. */
function aboutEntries(): FooterEntry[] {
  const fishlamp = getSite("fishlamp");
  return [
    { label: BRAND_LABEL, href: BRAND_HREF },
    ...(fishlamp ? [{ label: fishlamp.label, href: siteProdUrl("fishlamp", "/") }] : []),
    { label: "Tect" },
  ];
}

function Column({ title, entries }: { title: string; entries: FooterEntry[] }): ReactElement {
  return (
    <nav className="adh-landing-footer__column" aria-label={title}>
      <h3 className="adh-landing-footer__heading">{title}</h3>
      <ul className="adh-landing-footer__list">
        {entries.map((e) => (
          <li key={e.label} className="adh-landing-footer__item">
            {e.href ? (
              <a className="adh-landing-footer__link" href={e.href}>
                {e.label}
              </a>
            ) : (
              <span className="adh-landing-footer__link">{e.label}</span>
            )}
          </li>
        ))}
      </ul>
    </nav>
  );
}

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
export function LandingFooter(): ReactElement {
  const groups = groupSitesByCategory(LANDING_SITES);
  const version = buildVersionLabel();
  return (
    <div className={LANDING_FOOTER_CLASS}>
      <div className="adh-landing-footer__directory">
        {groups.map((group) => (
          <Column
            key={group.label}
            title={group.label}
            entries={group.sites.map((site) => ({
              label: site.label,
              href: siteProdUrl(site.id, "/"),
            }))}
          />
        ))}
        <Column title="About" entries={aboutEntries()} />
      </div>
      <div className="adh-landing-footer__fine-print">
        <p className="adh-landing-footer__copyright">
          Copyright © {new Date().getFullYear()}{" "}
          <a className="adh-landing-footer__link" href={BRAND_HREF}>
            {BRAND_LABEL}
          </a>
          . All rights reserved.
        </p>
        <ul className="adh-landing-footer__legal">
          <li className="adh-landing-footer__item">
            <a className="adh-landing-footer__link" href="/terms">
              Terms of Use
            </a>
          </li>
          <li className="adh-landing-footer__item">
            <a className="adh-landing-footer__link" href="/privacy">
              Privacy Policy
            </a>
          </li>
          <li className="adh-landing-footer__item">
            <button
              type="button"
              className="adh-landing-footer__link adh-landing-footer__sites"
              popoverTarget={SITES_OVERVIEW_POPOVER_ID}
            >
              All sites
            </button>
          </li>
          {version && <li className="adh-landing-footer__item adh-landing-footer__version">{version}</li>}
        </ul>
      </div>
      <SitesPopover sites={LANDING_SITES} />
    </div>
  );
}
