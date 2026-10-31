import { type ComponentType, type ReactNode } from 'react';
import { type SiteContact, type SiteLink } from '@agentic-toolkit/adh/footer';
export type AppShellProps = {
    /** The site header (e.g. <AdhHeader siteId=… />), supplied by the site so it
     *  can wire in its own auth/user. */
    header: ReactNode;
    children: ReactNode;
    /** The site's own footer links (the family footer's "This site" column), and who its
     *  Contact entry writes to (the hub when omitted). The copyright is a fixed brand line
     *  owned by the shared footer, not per-site. */
    footer?: {
        links?: SiteLink[];
        contact?: SiteContact;
    };
    /** Wraps the header and the footer — never the page — and decides whether they render.
     *  A client component (it reads the route), so a site can drop the chrome on the routes
     *  that must stand alone. Omitted, the chrome always renders. See MarketingRootHtml's
     *  prop of the same name. */
    chromeGate?: ComponentType<{
        children: ReactNode;
    }>;
    /** On `/`, the landing page's footer (marketing/LandingFooter: the family directory and the
     *  fine print) in flow in place of the floating copyright, with bitbag beside it; every other
     *  route keeps the floating copyright. For a site whose landing page is under this shell. A templated site's `/` is the
     *  template's own and takes LandingFooter through the template's `footer` slot instead.
     *  Omitted, every route gets the bar. */
    landingFooter?: boolean;
};
/**
 * The shared page shell every adh site renders: header, a flex-growing main region, and the
 * shared footer, with adh's cross-cutting providers mounted around it. Call-site signature is
 * unchanged from the pre-split husk's AppShell.
 *
 * The layout MECHANISM is `AdhAppShell` in `@agentic-toolkit/adh/layout`; this component is the
 * adh-specific composition root — which providers wrap the shell, and what goes in its footer
 * slot. Stays hook-free itself (server-renderable); the providers are client children.
 */
export declare function AppShell({ header, children, footer, chromeGate, landingFooter }: AppShellProps): import("react").JSX.Element;
/**
 * adh's cross-cutting providers, around whatever is put inside them. `AppShell` wraps its whole
 * layout in them; `MarketingFrameHeader` wraps a header alone in them, on a templated site's `/`,
 * where the site template's frame owns the page and no shell is mounted. One list, so the header
 * there reads the same contexts as the header on every other route.
 */
export declare function AppShellProviders({ children }: {
    children: ReactNode;
}): import("react").JSX.Element;
//# sourceMappingURL=AppShell.d.ts.map