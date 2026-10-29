// The footer's facts that are not React state: the studio's name and address, the sites
// overview's DOM id, and the build identity. No 'use client' directive, on purpose: the
// server-rendered LandingFooter (marketing/) needs these as real values, and a server module
// importing a constant from a client module gets a client reference, not the string.

// The company the copyright belongs to — Agentic Development Studio, which is also
// the wordmark closing the site menu (see StudioWordmark). NOT FishLamp Design, which
// the copyright used to name and which is still a family site with its own row.
//
// A literal href rather than `siteProdUrl(...)`: the studio deliberately has no
// registry entry (a `registry.test.ts` case pins that agenticdevelopmentstudio.com is
// not a registry host, because an entry would re-add the origin to the OAuth
// return-origin allowlist and to the generated route map). Same reason the menu's
// studio row is an absolute `{ href }`.
export const BRAND_LABEL = 'Agentic Development Studio'
export const BRAND_HREF = 'https://agenticdevelopmentstudio.com/'

/** The DOM id of the single shared sites-overview popover. The footer renders
 *  the panel once; every trigger (the "Sites" entry in the footer's copyright
 *  menu, the header site-switcher's "?" icon and its "help" command) opens it by this id, so
 *  there's exactly one instance — and therefore one crawlable copy of the SEO
 *  interlink set. */
export const SITES_OVERVIEW_POPOVER_ID = 'adh-sites-overview'

/** The footer's build identity: `v1.0.155 · a73e79b7`, or null when neither field exists.
 *
 *  Two fields doing two jobs. The semver is hand-bumped and scoped to ONE site's
 *  directory, so it answers "did my change ship?"; the SHA is stamped on every
 *  build from any cause — including a submodule bump that touched no file under
 *  the site — so it answers "which build is this?". Each covers the other's blind
 *  spot: a version alone only moves when someone remembers, and a bare SHA means
 *  nothing unless you happen to be holding the commit you deployed.
 *
 *  Both are read as literal `process.env.NEXT_PUBLIC_*` expressions so Next's
 *  build-time substitution reaches them (the same mechanism TelemetryProvider
 *  already round-trips for NEXT_PUBLIC_ADH_RELEASE). Exported for the contract test.
 *
 *  The title carries the FULL sha rather than a build timestamp: a timestamp would
 *  make every build's bundle differ from identical source, and this repo has already
 *  paid for non-reproducible artifacts once.
 *
 *  `live` overrides either field, and exists for exactly one mode. Under `next build`
 *  the literals below ARE the build, so nothing overrides them and this argument is
 *  never passed. Under `next dev` they freeze at dev-server boot and then keep
 *  reporting the commit the session started on for as long as it runs — which is how
 *  a bumped `VERSION` could show nothing on screen. AppShell (a Server Component)
 *  resolves the real pair per render and passes it down; see `liveBuildIdentity`.
 *  A field it could not read with confidence arrives `undefined` and the baked
 *  literal shows through, so this can only ever correct a value, never blank one.
 *
 *  @param live the running server's own identity, in development only. */
export function buildVersionLabel(live?: { version?: string; sha?: string }) {
  const version = live?.version ?? process.env.NEXT_PUBLIC_ADH_SITE_VERSION ?? ''
  const sha = live?.sha ?? process.env.NEXT_PUBLIC_ADH_RELEASE ?? ''
  const label = [version && `v${version}`, sha && sha.slice(0, 8)].filter(Boolean).join(' · ')
  if (!label) return null
  return <span title={sha || undefined}>{label}</span>
}
