import { type FooterLink } from '@agentic-toolkit/adh/footer';
export type SiteFooterProps = {
    links?: FooterLink[];
    /** Mount bitbag. Default true — he belongs on every real footer; `false` leaves him out,
     *  and the bar keeps no corner for him. A {@link SiteFooterProps.specimen | specimen}
     *  never mounts him, whatever this says.
     *
     *  On THIS component, not the {@link ToolkitFooter} primitive it wraps: the
     *  primitive takes a generic `trailing` slot and has no idea bitbag exists, which
     *  is the whole point of the split. */
    chat?: boolean;
    /** A COPY of the footer, shown beside the page's own: the theme editor's preview pane
     *  (theme-editor/areas.tsx). The footer carries things a page must have exactly one of,
     *  and a specimen renders none of them:
     *
     *  - Its menus get ids of their own. `popovertarget` finds its panel by id across the
     *    whole document, so on the page's ids the specimen's copyright opened the PAGE's
     *    menu, and a second copy of each id is invalid HTML besides.
     *  - No About, Sites, Terms or Privacy dialog. Those are found by id too, so the
     *    specimen's entries open the page footer's own. On a page with no SiteFooter they
     *    open nothing, which a specimen can afford: it is there to show what the footer
     *    looks like, not to be one.
     *  - No bitbag. He portals himself to `document.body` (see FooterChatInner), so a
     *    preview cannot contain him with a scoped `display:none` the way it hides the
     *    in-flow theme switcher: he escaped the pane and landed full-size over the console
     *    previewing him. And a second dock would share the first's `view-transition-name`
     *    (adh-site.css), which skips every slide while the specimen is on screen. */
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
};
/** adh's footer: the toolkit's identity-free primitive ({@link ToolkitFooter}, published as
 *  `AdhFooter` from this same barrel) plus everything that IS adh — the studio's copyright
 *  menu, the About dialog, the sites popover, the legal modals, and bitbag himself. The
 *  copyright is a fixed brand line, deliberately not per-site.
 *
 *  Named `SiteFooter` rather than `AdhFooter`: this barrel already publishes an `AdhFooter`
 *  — the registry-free primitive this component wraps. The two are unrelated components
 *  that happened to share a name; this one is adh's REGISTRY-AWARE composition. */
export declare function SiteFooter({ links, chat, live, specimen }: SiteFooterProps): import("react").JSX.Element;
//# sourceMappingURL=SiteFooter.d.ts.map