import { type ComponentType, type ReactElement, type ReactNode } from "react";
import type { SiteId } from "@agentic-toolkit/adh-registry";
import type { NavLink } from "@agentic-toolkit/adh/header";
import type { FooterLink } from "@agentic-toolkit/adh/footer";
import { type SiteHelp } from "@agenticdevelopertoolkit/ui/components/help-content";
/** The serializable half of a link: what a server layout can hand across the
 *  boundary. NavLink's `icon`/function form and FooterLink's `onSelect` cannot
 *  cross it, and a site that needs either is not describing chrome any more.
 *  Derived from FooterLink so it narrows when that type does. */
type PlainLink = Pick<Extract<FooterLink, {
    href: string;
}>, "label" | "href">;
export type MarketingShellProps = {
    /** Optional site-owned header nav items — the serializable subset of NavLink (this is
     *  a server component, so the function form and icon fields can't cross the boundary;
     *  matchPaths keeps active-link highlighting available to sites). */
    navLinks?: Pick<NavLink, "label" | "href" | "matchPaths">[];
    /** Optional site-owned header items rendered OUTSIDE the collapsing nav, at the bar's
     *  trailing edge — an off-site destination (`toolkit`'s GitHub) rather than a route. */
    trailingNavLinks?: PlainLink[];
    /** Optional site-owned footer links, added to the shared legal/sites row. The
     *  copyright is the brand's, not the site's, and stays owned by SiteFooter. */
    footerLinks?: PlainLink[];
    /** The marketing site this document chrome is for — drives the header brand. */
    siteId: SiteId;
    /**
     * Whether the AuthProvider runs the cross-site cold-load silent-SSO probe (default `true`,
     * the feature-site behaviour) — on EVERY route, the landing page included.
     *
     * `false` means one thing now: this site does not recognize a signed-in visitor. It used to
     * mean something else as well, which is why it exists at all — the probe is a top-level
     * `/authorize?prompt=none` navigation (the central session cookie is host-only + SameSite=Lax,
     * so it CANNOT be done in the background), and it used to make that navigation on a guess, so
     * an origin the AS return-origin allow-list was missing stranded the visitor on the central
     * login page. A fully public site turned the probe off to be sure that never happened.
     * `beginSilentLogin` now asks the AS first (`preflightSsoReturn`) and navigates only on a yes,
     * so a public site keeps that guarantee with the probe ON, and no site in the family passes
     * `false` (<adh-tools>/sites/scripts/verify-site-uniformity.py fails one that starts).
     *
     * Set it only for a surface that must not navigate on load for a reason the preflight does not
     * cover, and say what that reason is. See adh/docs/platform/cross-site-auth.md.
     */
    silentSso?: boolean;
    /**
     * The site's own header, in place of the shared `<MarketingSiteHeader siteId/>`.
     *
     * This slot exists because its absence was expensive. Four sites needed a different header
     * component — community's board controls, the registry's persona search, the cookbook's
     * search/sidebar controls, the hub's app bar — and with no way to pass one, each reproduced
     * the whole `<html>`/`<head>`/`<body>`/`AuthProvider`/`AppShell` scaffold to reach the one
     * `AppShell` prop it wanted. All four then wrote `<html lang="en">` with no `dir`, silently
     * leaving the locale seam this component computes from `getLocale()`. A missing slot does not
     * keep a site on the shared shell; it just moves the whole document into the site.
     *
     * A node rather than a component type: it is rendered in the same server pass, so a site can
     * wrap its header in a `<Suspense>` boundary (the cookbook does — see its layout) without this
     * component knowing anything about it. `navLinks`/`trailingNavLinks` are the shared header's
     * props and are ignored when a site supplies its own.
     */
    header?: ReactNode;
    /**
     * The site's own context providers, mounted between the shared `AuthProvider` and `AppShell`.
     *
     * The cross-cutting providers are NOT here: `AuthProvider` is above (so a site never restates
     * the client id, the token store, or the SSO probe) and `AppShell` mounts the feature-flag,
     * help and telemetry providers below. This is only for context a site genuinely owns — the
     * cookbook's chrome coordinator, the hub's debug console / settings overlay / workspaces menu.
     *
     * A component rather than an element, because it has to WRAP `children`. It renders in the
     * same server pass, so it may be a client component (each of today's is). A site that also
     * wants a document-level node beside the shell — the cookbook's film grain — renders it here
     * as a sibling of `children`; providers emit no DOM, so the result is the same markup a
     * hand-rolled `<body>` produced.
     */
    providers?: ComponentType<{
        children: ReactNode;
    }>;
    /** The site's help copy, published to the whole document.
     *
     *  A provider rather than a header prop: the `header` slot below lets a site
     *  replace the shared header entirely (four do), and a prop would reach the
     *  shared header and miss them. */
    help?: SiteHelp;
    /**
     * Whether the header and footer render on the current route — a client component that
     * wraps each of them and returns its children or nothing.
     *
     * A gate rather than a route list because the question is the site's to answer: on the
     * registry the root segment is a published handle, so "is this a profile" means "is the
     * first segment anything but one of the site's own pages", which no static list can say.
     * Being a client component, it reads the route with `usePathname()`, which Next resolves
     * during the server render too — so a gated-off route ships without the chrome rather than
     * removing it after hydration.
     *
     * It wraps the chrome and never the page, so it cannot change what a route renders, only
     * whether the shared frame is around it. Omitted, the chrome always renders.
     */
    chromeGate?: ComponentType<{
        children: ReactNode;
    }>;
    children: ReactNode;
};
/**
 * The class on the shell's root element, and the scope of the family's stylesheets.
 *
 * `adh-family.css` and the landing bridge write every rule under it (`:root:has(.adh-family)`,
 * `.adh-family …`), so they style a document only while a shell is mounted in it. That matters
 * on a templated site: its family route group imports `family.css`, Next keeps that stylesheet
 * in the document after a client-side navigation to the template's own `/`, and unscoped, the
 * family's `html`, `body` and `:root { --lp-* }` rules went on styling the template's landing.
 */
export declare const FAMILY_ROOT_CLASS = "adh-family";
/**
 * The body half of the ADH marketing family's document: help, auth, the site's own providers
 * and the shared chrome, with nothing around them.
 *
 * `MarketingRootHtml` is this inside `<html>`/`<head>`/`<body>`, and every family site whose
 * root layout is its own mounts that. This exists for the one case where the document is
 * somebody else's: a site built on `@agenticdevelopertoolkit/site-template` has the template's
 * root layout, which already writes `<html>` and `<body>`, and keeps its family routes (privacy,
 * terms, the signed-in pages) in a route group below it. That group mounts this, with
 * `<AdhThemeStyle/>` beside it, instead of copying the chain — the copy is what the uniformity
 * check's `shell` rule exists to stop. The family's design rationale is on `MarketingRootHtml`.
 */
export declare function MarketingShell({ siteId, navLinks, trailingNavLinks, footerLinks, silentSso, header, providers, help, chromeGate, children, }: MarketingShellProps): ReactElement;
export {};
//# sourceMappingURL=MarketingShell.d.ts.map