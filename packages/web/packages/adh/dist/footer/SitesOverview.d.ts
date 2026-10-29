/**
 * The footer "sites overview" — a modal dialog (AdhModalPopover) that lists every
 * family site (grouped, with descriptions). It is BOTH the human overview panel
 * AND the SEO interlink set: every `<a href>` is rendered into the server HTML
 * (the popover is collapsed via the UA stylesheet's `display:none`, not removed),
 * so crawlers follow the links while the panel stays hidden until opened. No
 * client JS — a `popovertarget` trigger (the Sites entry of SiteFooter's copyright
 * menu) opens it and
 * the modal's close box dismisses it natively.
 */
export declare function SitesPopover(): import("react").JSX.Element;
//# sourceMappingURL=SitesOverview.d.ts.map