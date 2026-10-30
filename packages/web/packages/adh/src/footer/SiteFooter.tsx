'use client'

import { AdhModalPopover } from './AdhModalPopover'
import { FamilyFooter, type SiteLink } from './FamilyFooter'
import { ADH_CONTACT, BRAND_HREF, BRAND_LABEL, FAMILY_FOOTER_DIALOG_ID, buildVersionLabel, type SiteContact } from './identity'
import { FooterChat } from './FooterChat'
import { SitesPopover } from './SitesOverview'
import { TermsModal, PrivacyModal } from './LegalModals'

export type SiteFooterProps = {
  /** A site's own links: the family footer's "This site" column. */
  links?: SiteLink[]
  /** Mount bitbag. Default true — he belongs on every real footer; `false` leaves him out.
   *  A {@link SiteFooterProps.specimen | specimen} never mounts him, whatever this says. */
  chat?: boolean
  /** A COPY of the footer, shown beside the page's own: the theme editor's preview pane
   *  (theme-editor/areas.tsx). The footer carries things a page must have exactly one of,
   *  and a specimen renders none of them:
   *
   *  - No family-footer, Sites, Terms or Privacy dialog. Those are found by id
   *    (`popovertarget` looks across the whole document), so the specimen's copyright opens
   *    the page footer's own. On a page with no SiteFooter it opens nothing, which a
   *    specimen can afford: it is there to show what the footer looks like, not to be one.
   *  - No bitbag. He portals himself to `document.body` (see FooterChatInner), so a
   *    preview cannot contain him with a scoped `display:none`: he escaped the pane and
   *    landed full-size over the console previewing him. And a second dock would share the
   *    first's `view-transition-name` (adh-site.css), which skips every slide while the
   *    specimen is on screen. */
  specimen?: boolean
  /** The running server's own build identity, passed by {@link AppShell} in development
   *  only. Omitted everywhere else, where the baked `NEXT_PUBLIC_*` literals are the
   *  build and correct by construction — see {@link buildVersionLabel}.
   *
   *  A plain serializable object, deliberately: this component is `'use client'`, so the
   *  value has to cross the server/client boundary as data. It cannot be read here —
   *  resolving it needs `node:fs` and a `git` fork. */
  live?: { version?: string; sha?: string }
  /** Who the family footer's Contact column writes to; the hub by default. */
  contact?: SiteContact
}

const COPYRIGHT_PREFIX = '© 2026 '

/** What the `i` says to a screen reader and in its tooltip: what it opens. */
export const FAMILY_FOOTER_TRIGGER_LABEL = 'About the Agentic Developer family'

/** adh's footer on every page but a landing page: a big `i` in a circle, floating in the
 *  viewport's lower-left corner. It is a button that opens the whole family footer
 *  (FamilyFooter, which carries the studio's copyright) in a dialog over the page, and the
 *  dialogs the family footer's entries open are rendered here beside it, one each. bitbag
 *  rests in the opposite corner (FooterChat), and the circle is the size of his face. */
export function SiteFooter({ links = [], chat = true, live, specimen = false, contact = ADH_CONTACT }: SiteFooterProps) {
  const version = buildVersionLabel(live)
  return (
    <>
      <footer className="adh-footer adh-footer--floating" role="contentinfo">
        <div className="adh-footer__copyright">
          <button
            type="button"
            className="adh-footer__copyright-trigger"
            popoverTarget={FAMILY_FOOTER_DIALOG_ID}
            aria-label={FAMILY_FOOTER_TRIGGER_LABEL}
            title={FAMILY_FOOTER_TRIGGER_LABEL}
          >
            <span className="adh-footer__brand-link" aria-hidden>
              i
            </span>
          </button>
          {/* Without the Popover API the trigger is a dead button and the family footer never
              opens, so the studio's link and this build's version have no other way onto the
              screen. Shown only there (adh-site.css). AFTER the trigger, because the theme
              editor reads the brand's current values off the first `.adh-footer__brand-link`
              it finds (theme-editor/areas.tsx), and that has to be the one people see: the `i`. */}
          <span className="adh-footer__copyright-fallback">
            {COPYRIGHT_PREFIX}
            <a className="adh-footer__brand-link" href={BRAND_HREF}>
              {BRAND_LABEL}
            </a>
            {version && <span className="adh-footer__copyright-version"> · {version}</span>}
          </span>
        </div>
      </footer>
      {chat && !specimen && <FooterChat />}
      {/* The page's, one each: a specimen's copyright opens these (see `specimen`). */}
      {!specimen && (
        <>
          <AdhModalPopover id={FAMILY_FOOTER_DIALOG_ID} title="The Agentic Developer family" className="adh-modal--wide">
            <FamilyFooter version={version} links={links} contact={contact} />
          </AdhModalPopover>
          <SitesPopover />
          <TermsModal />
          <PrivacyModal />
        </>
      )}
    </>
  )
}
