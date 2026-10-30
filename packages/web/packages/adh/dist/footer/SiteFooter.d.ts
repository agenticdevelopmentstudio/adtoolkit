import { type SiteLink } from './FamilyFooter';
import { type SiteContact } from './identity';
export type SiteFooterProps = {
    /** A site's own links: the family footer's "This site" column. */
    links?: SiteLink[];
    /** Mount bitbag. Default true — he belongs on every real footer; `false` leaves him out.
     *  A {@link SiteFooterProps.specimen | specimen} never mounts him, whatever this says. */
    chat?: boolean;
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
    specimen?: boolean;
    /** The running server's own build identity, passed by {@link AppShell} in development
     *  only. Omitted everywhere else, where the baked `NEXT_PUBLIC_*` literals are the
     *  build and correct by construction — see {@link buildVersionLabel}.
     *
     *  A plain serializable object, deliberately: this component is `'use client'`, so the
     *  value has to cross the server/client boundary as data. It cannot be read here —
     *  resolving it needs `node:fs` and a `git` fork. */
    live?: {
        version?: string;
        sha?: string;
    };
    /** Who the family footer's Contact column writes to; the hub by default. */
    contact?: SiteContact;
};
/** What the `i` says to a screen reader and in its tooltip: what it opens. */
export declare const FAMILY_FOOTER_TRIGGER_LABEL = "About the Agentic Developer family";
/** adh's footer on every page but a landing page: a big `i` in a circle, floating in the
 *  viewport's lower-left corner. It is a button that opens the whole family footer
 *  (FamilyFooter, which carries the studio's copyright) in a dialog over the page, and the
 *  dialogs the family footer's entries open are rendered here beside it, one each. bitbag
 *  rests in the opposite corner (FooterChat), and the circle is the size of his face. */
export declare function SiteFooter({ links, chat, live, specimen, contact }: SiteFooterProps): import("react").JSX.Element;
//# sourceMappingURL=SiteFooter.d.ts.map