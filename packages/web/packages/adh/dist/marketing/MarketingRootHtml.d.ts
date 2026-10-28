import type { ReactElement } from 'react';
import { type MarketingShellProps } from './MarketingShell';
/** The document's props are the shell's: the document adds `<html>`, `<head>` and
 *  `<body>` and nothing a site can set. Each seam is documented below on the shell's
 *  type, in MarketingShell.tsx. */
export type MarketingRootHtmlProps = MarketingShellProps;
/**
 * The shared root-document shell for the ADH marketing family. Every marketing
 * site's `app/layout.tsx` was byte-identical except its `siteId` + `metadata`
 * (and all 22 `providers.tsx` were byte-identical), so the whole `<html>` …
 * `<AppShell>` scaffold lives here once:
 *  • `<html lang dir>` from the active-locale seam (`getLocale`/`htmlLang`/`localeDir`)
 *  • a `<head>` whose whole content is `<AdhThemeStyle/>` — the theme CSS variables, the
 *    appearance pre-paint script, and the font `<link>`s. The preconnects this line used to
 *    name as a second item are AdhThemeStyle's own: it derives them from the theme's font
 *    origins, so a theme that changes fonts changes them too. Nothing else belongs here;
 *    per-site `<head>` content is `metadata` in the site's own layout.
 *  • an `<AuthProvider clientId="adh" silentSso={silentSso}>` — a feature site
 *    (adh/docs/platform/feature-sites-redesign.md) leaves the probe ON (default): the header is
 *    session-aware and `/home` is the signed-in feature surface. It fires once per tab, on
 *    EVERY route including the landing deck, gated by `shouldSilentRestore` (a readable hint
 *    cookie, or cross-apex where the cookie cannot be read) — and it is safe to fire there
 *    because `beginSilentLogin` asks the AS whether it will return the browser before it
 *    navigates, so an origin the allow-list is missing costs the avatar rather than stranding
 *    the visitor on the central login page. That guarantee is what retired the two client-side
 *    guesses this comment used to describe (a landing-route exemption and a local-hostname
 *    veto); see adh/docs/platform/cross-site-auth.md. `silentSso={false}` opts a site out of
 *    recognition entirely — no site in the family does, and
 *    <adh-tools>/sites/scripts/verify-site-uniformity.py fails one that starts, so the escape hatch cannot
 *    be taken quietly. See the `silentSso` doc on MarketingShellProps.
 *  • `<AppShell header={header ?? <MarketingSiteHeader siteId/>} footer={…}>` — the shared
 *    chrome with the smart auth widget (avatar / Login+Sign up via SSO returnTo).
 *
 * EVERY site in the family mounts this. A site does not build its own `<html>` — a site that
 * needs something different declares it as a prop here, and if no prop fits, the prop is what
 * gets added. That rule is enforced (`<adh-tools>/sites/scripts/verify-site-uniformity.py`, check `shell`)
 * and it is not waivable by recording an exception, because the four documents that were once
 * excused are what taught us the cost: each was a copy of this file made to reach ONE slot, and
 * each silently dropped `dir` and the locale seam on the way. The per-site seams are
 * `header`, `providers`, `navLinks`, `trailingNavLinks`, `footerLinks`, `silentSso` and
 * `chromeGate`.
 *
 * The body half is `MarketingShell`, exported on its own for a layout below a document it does
 * not own (a site-template site's family route group).
 *
 * A server component: it renders the client `AuthProvider`/`SiteHeader` exactly as a
 * site layout would. Per-site `metadata` (the one genuinely per-site, SEO-bearing
 * part) and the site's `globals.css` import stay in each `app/layout.tsx`.
 *
 * Home: `@agentic-toolkit/adh/marketing` — adh VOCABULARY end to end (the ADH marketing
 * family's root document, its siteId, its clientId). It lived in the @adh-shared auth shim only
 * because that package owned the header/auth chrome it composes; Task 6.2 folded `SiteHeader`
 * into the app tier's header barrel and the toolkit took the generic halves, so the
 * circular-dependency reason for the old home is gone. The client pieces are still imported via their package
 * paths (kept external by tsup) so their 'use client' boundaries survive bundling,
 * mirroring the graph subsystem.
 */
export declare function MarketingRootHtml(props: MarketingRootHtmlProps): ReactElement;
//# sourceMappingURL=MarketingRootHtml.d.ts.map