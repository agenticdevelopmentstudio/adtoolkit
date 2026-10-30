import { type SiteDef } from '@agentic-toolkit/adh-registry';
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
 * `sites` narrows the roster; it defaults to the whole of FOOTER_SITES. A landing
 * page's footer passes DIRECTORY_SITES, so the panel it opens links no more than the
 * directory above it.
 */
export declare function SitesPopover({ sites }?: {
    sites?: SiteDef[];
}): import("react").JSX.Element;
//# sourceMappingURL=SitesOverview.d.ts.map