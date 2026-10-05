
The site registry is the single source of truth for the Agentic Developer Hub (ADH)
site family: roughly seventy independently deployed sites (`hub`, `cookbook`,
`projects`, `billing`, …) that share a header, a cross-site switcher, and a central
OAuth client. It comprises:

- **The site roster** — a closed set of every site identifier the family currently
  knows about, and one definition per site (display names, production host, which
  deploy environments exist, whether the site exposes the shared landing route,
  whether it mounts an authenticated workspace route); environment/host resolution
  for cross-site navigation; the hub's in-workspace feature-segment map; the
  workspace-slug round trip (plus the two disjoint landing-segment sets that tell a
  slug apart from a static page); a per-site build-configuration side table kept
  deliberately outside the mechanically generated part of the roster; and the
  cross-site single-sign-on (SSO) OAuth redirect allowlist.
- **The reserved-slug table** — which top-level path segments a registrant cannot
  claim as a public handle, per site.
- **The generated route map** — per-region generated route shares merged into one
  route table, feeding a "Routes" review surface and, downstream, a sitemap's
  static-segment exclusion list.
- **The brand story and guided tour** — a hand-authored brand-story map (brand tier,
  message-house pillar, funnel stage, and a brand-judgment "next step" per site)
  plus a separately generated, three-ring guided-tour graph merged into one
  next-step map.

All of it is pure, synchronous data and functions with no I/O beyond in-memory
lookups, read by the header, the site switcher, the footer, the hub's workspace
router, and a downstream OAuth-return-origin sync process.

