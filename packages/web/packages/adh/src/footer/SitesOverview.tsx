'use client'

import { AdhModalPopover } from './AdhModalPopover'
import { SITES_OVERVIEW_POPOVER_ID, sitesPanelGroups } from './identity'

/**
 * The footer "sites overview" — a modal dialog (AdhModalPopover) that lists every
 * family site (grouped, with descriptions). It is BOTH the human overview panel
 * AND the SEO interlink set: every `<a href>` is rendered into the server HTML
 * (the popover is collapsed via the UA stylesheet's `display:none`, not removed),
 * so crawlers follow the links while the panel stays hidden until opened. No
 * client JS — a `popovertarget` trigger (the Sites entry of SiteFooter's copyright
 * menu) opens it and
 * the modal's close box dismisses it natively.
 *
 * It lists the same roster on every page, the landing page included: every site the family
 * serves (sitesPanelGroups).
 */
export function SitesPopover() {
  const groups = sitesPanelGroups()
  return (
    <AdhModalPopover id={SITES_OVERVIEW_POPOVER_ID} title="The Agentic Developer family">
      {groups.map((group) => (
        <nav
          key={group.label}
          className="adh-sites-popover__group"
          aria-label={group.label}
        >
          <h3 className="adh-sites-popover__group-title">{group.label}</h3>
          <ul className="adh-sites-popover__list">
            {group.entries.map((entry) => (
              <li key={entry.key}>
                <a className="adh-sites-popover__item" href={entry.href}>
                  <span className="adh-sites-popover__name">{entry.label}</span>
                  {entry.description && (
                    <span className="adh-sites-popover__blurb">
                      {entry.description}
                    </span>
                  )}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      ))}
    </AdhModalPopover>
  )
}
