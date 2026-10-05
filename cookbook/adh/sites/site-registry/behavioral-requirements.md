
### Site identity and roster

- **site-id-closed-union**: The site identifier type MUST be closed, naming every
  site the family currently knows about; a value obtained from outside that closed
  set (a directory name, a command-line argument, a database column) MUST be
  validated by identifier validation or by directory-based identification before it
  can index the site roster or any table keyed by site identifier.
- **unique-site-ids**: Every entry in the site roster MUST have a unique identifier,
  and the roster MUST NOT contain an entry for the backend service itself.
- **site-def-minimum-fields**: Every site definition MUST declare `id`, `label`, and
  `prodHost`, and MUST declare `hasStaging`, `hasTesting`, and `hasHome` as explicit
  booleans (never omitted, since environment host resolution, the OAuth
  return-origin allowlist, and cross-site link construction's home-carry all branch
  on their literal `true`/`false` value).
- **workspace-route-not-derived-from-has-home**: A site definition's workspace-route
  field MUST NOT be inferred from `hasHome`; the two are independent facts about a
  site's route tree (`bitbag`, `status`, and `admin` have `hasHome: false` and no
  workspace route, while `hub-help` and `personaregistry` have `hasHome` true or
  false independently of having no workspace route at all), and a caller deriving
  one from the other risks sending a workspace switch to a route that 404s.
- **external-site-excluded-from-sso**: A site definition marked `external` MUST be
  excluded from the OAuth return-origin allowlist in every environment, because such
  a site (FishLamp Design) has no auth-callback route and never begins an ADH login.
- **admin-only-derives-admin-ids-and-drops-footer**: The admin-only id set MUST be
  exactly the identifiers of every site definition marked `adminOnly`, and every such
  entry MUST be excluded from the footer site list.
- **listed-sites-filter**: The listed-sites set MUST be exactly the roster entries
  whose `listed` field is not literally `false`; a `listed: false` entry MUST remain
  resolvable by site lookup and identifier validation and MUST only be excluded from
  the roster display, never from the registry itself.
- **footer-sites-filter**: The footer site list MUST be exactly the listed-sites
  entries whose `crawlable` is not `false` and whose `adminOnly` is not `true`, in
  the same order as the listed-sites set.

### Lookup and identification

- **get-site-lookup**: Site lookup by identifier MUST return the roster entry whose
  identifier equals the argument, or nothing when no such entry exists.
- **is-site-id-derived-from-sites**: Identifier validation MUST return true if and
  only if some roster entry has that identifier; it MUST be derived from the roster
  directly rather than from a second, separately maintained list, so it can never
  diverge from the identifiers the registry actually declares.
- **dir-name-strips-tld**: The directory-name derivation (used internally by
  directory-based identification) MUST derive a site's build-tree directory name by
  stripping the trailing `.<tld>` from `prodHost` (e.g. `help.agenticdeveloperhub.com`
  → `help.agenticdeveloperhub`).
- **site-id-for-dir-bare-id-first**: Directory-based identification MUST return the
  given name unchanged (as a valid site identifier) when that name is already a
  valid site identifier, before falling back to a `prodHost`-derived directory-name
  match; it MUST return nothing when the name matches neither a site identifier nor
  any site's derived directory name.

### Family groupings

- **main-marketing-ids-are-disjoint-curated-lists**: The main-family roster and the
  marketing-family roster MUST each be a hand-curated, non-overlapping list of site
  identifiers; an identifier present in one MUST NOT appear in the other, and `mcp`
  and `builds` (which have no build-tree directory anywhere) MUST appear in neither.
- **site-categories-exactly-one-membership**: Every identifier appearing in any
  category grouping's member list MUST appear in exactly one grouping's member list,
  never zero and never more than one.
- **group-by-category-preserves-order-and-collects-leftovers**: Category grouping
  MUST emit groups in the categories' declared order, with members in each group's
  declared order, MUST omit any group with no matching member among the sites being
  grouped, and MUST collect every site that matches no category into a single
  trailing group labelled "More", so that a newly scaffolded site can never be
  silently dropped from a menu built on this grouping.

### Display title

- **header-title-explicit-fulllabel-wins**: Header-title derivation MUST return a
  site's `fullLabel` when it is set, taking priority over any derivation from
  `prodHost`.
- **header-title-derives-from-apex-pattern**: When `fullLabel` is absent and
  `prodHost` matches `agenticdeveloper<x>.com`, header-title derivation MUST return
  `"Agentic Developer <X>"` with `<x>` capitalized, and MUST fall back to the site's
  `label` when `prodHost` matches neither an explicit `fullLabel` nor that pattern.
- **split-title-prefix-detection**: Header-title splitting MUST split the derived
  header title into a lead of `"Agentic Developer"` and an accent of the rest when
  the header title begins with `"Agentic Developer "`, and MUST return an empty lead
  with the whole title as accent for an off-pattern brand name (for example the
  Persona Registry).

### Environment and cross-site navigation

- **detect-env-classification**: Environment detection MUST lower-case and strip any
  trailing `:<port>` before classifying a hostname, MUST classify a hostname as
  `'local'` when it is exactly `localhost`, starts with `127.`, is `::1`, or ends in
  `.local`, `.test`, or `.localhost`; MUST classify a hostname starting with
  `testing.` as `'testing'` and one starting with `staging.` as `'staging'`; and MUST
  classify every other hostname as `'production'`.
- **host-for-env-fallback**: Environment host resolution MUST resolve
  `testing.<prodHost>` when the target environment is `'testing'` and the site has a
  testing deploy; otherwise for `'testing'` it MUST fall back to `staging.<prodHost>`
  when the site has a staging deploy, and otherwise to the bare `prodHost`. For
  `'staging'` it MUST resolve `staging.<prodHost>` when the site has a staging
  deploy and otherwise the bare `prodHost`. For `'production'` it MUST always
  resolve the bare `prodHost`.
- **local-origin-suite-domain-priority**: Local-origin resolution MUST first check
  whether the lower-cased, port-stripped current host ends in one of the recognized
  local suite domains (`sites.localhost`, `dev.test`, `dev.local`, checked in that
  order for readability only); when it does, the target's local origin MUST be
  `https://<sub>.<suite>.<domain>` (no subdomain for `hub`) reusing the current
  host's own `<suite>` label. When the current host matches none of the recognized
  suite domains, local-origin resolution MUST fall back to
  `http://<sub>localhost<:port>`, carrying the current port when one is present.
- **carry-path-home-only**: Path carry-over MUST return the target's landing path
  (`/`) for any path other than `/home` or a path starting with `/home/`; for the
  path `/home` it MUST return `/home` when the target exposes a home route and `/`
  otherwise; for a deeper `/home/*` path it MUST return the same path with a
  `#site-switch` marker appended (so the target's not-found page knows to walk the
  path up), or `/` when the target has no home route at all.
- **build-site-href-env-aware**: Cross-site link construction MUST classify the
  current environment via environment detection; for `'local'` it MUST return the
  local origin concatenated with the carried path; for every other environment it
  MUST return `https://<resolved environment host>` concatenated with the carried
  path.

### Cross-Site SSO Origin Allowlist (security-relevant)

- **sso-return-origins-partitioned-by-env**: The OAuth return-origin allowlist MUST
  return, for `env === 'production'`, the bare `https://<prodHost>` origin of every
  roster entry that is not marked external; for `env === 'staging'`, only the
  `https://staging.<prodHost>` origin of every non-external entry with a staging
  deploy; for `env === 'testing'`, only the `https://testing.<prodHost>` origin of
  every non-external entry with a testing deploy.
- **sso-flag-flip-is-a-one-way-door**: The staging-deploy and testing-deploy flags
  are the OAuth redirect surface the allowlist names, and flipping either from
  `false` to `true` MUST be treated as permanently widening that environment's
  allowlist: the deploy-time sync process that reads the allowlist's output into the
  enforcing database column is additive-only and never prunes a row that a later
  flag flip back to `false` would otherwise remove. A caller changing an existing
  entry's flag back to `false` MUST NOT assume the corresponding origin stops being
  a valid OAuth `return` target without a separate, deliberate, hand-run pruning
  pass against that environment.
- **sso-external-exclusion-fail-closed**: An origin belonging to a site marked
  external MUST NOT appear in the OAuth return-origin allowlist's result for any
  environment, on a fail-closed basis: an origin that cannot complete an ADH login
  has no legitimate reason to be a legal `return` target, so the absence is
  deliberate rather than an oversight to fill in.

### Hub in-workspace feature routing

- **hub-feature-segment-default-is-site-id**: The hub feature-segment map MUST map a
  routed site's identifier to the hub's own feature segment for that site's
  implementation; the default mapping is a site's own identifier, and every entry
  that maps to a different segment MUST do so because the hub already routed that
  feature under a different name before the site existed.
- **hub-feature-segment-many-to-one-allowed**: Two or more site identifiers MAY map
  to the same feature-segment value (for example `ecosystems` and `products` both
  mapping to `'products'`) when the hub renders one pane for both; segment lookup by
  site identifier MUST return that shared segment for either identifier.
- **site-for-hub-segment-tiebreak**: The reverse feature-segment lookup MUST resolve
  a segment shared by more than one site to the site whose own identifier equals
  that segment when one exists (for example `'products'` resolves to the `products`
  site, not `ecosystems`); when no site's identifier equals the segment, it MUST
  resolve to whichever site's mapping was declared first in the feature-segment map.
- **hub-workspace-segments-is-the-full-union**: The full workspace-segment set MUST
  be exactly the union of every value in the feature-segment map and every entry in
  the hub-only extra segments, so a caller answering "is this second path segment a
  hub workspace feature?" never has to consult the two source lists separately.
- **hub-extra-segments-have-no-registry-site**: An entry in the hub-only extra
  segments MUST name a hub workspace feature with no corresponding registry site (a
  hub-only knob, such as an ecosystem's member list, or the persona-data management
  surface); a feature that is some site's own implementation MUST be keyed in the
  feature-segment map by that site's identifier instead.

### Workspace routing

- **workspace-href-single-shape**: Workspace-link construction MUST return nothing
  when the slug is falsy (including the empty string) or when the target has no
  workspace route; otherwise it MUST return exactly `/<slug>`, the one route shape
  every site with a workspace route mounts today.
- **workspace-slug-root-sites-only**: Workspace-slug parsing MUST return nothing
  immediately when the site's workspace root is not the template root (which
  includes every hub-shaped site, i.e. the hub's own workspace root, and every site
  with no workspace route at all); it MUST NOT attempt to parse a slug out of a
  hub-shaped site's path using the template root's landing-segment set.
- **workspace-slug-excludes-landing-segments**: For a site whose workspace root is
  the template root, workspace-slug parsing MUST take the first non-empty path
  segment and return it as the slug unless that segment is a member of the
  landing-segment set, in which case it MUST return nothing — including for the
  empty-path case, which resolves to no first segment and therefore also nothing.
- **landing-and-hub-segment-sets-are-answer-specific**: The landing-segment set MUST
  be consulted only for a template-root site's first path segment, and the hub's own
  route-segment set MUST be consulted only for the hub's own first path segment; a
  caller MUST NOT answer one site's question from the other set, since the two sets
  name different words (the hub serves `/login`, `/explore`, `/settings`, which no
  template site does, and does not serve a template site's own words such as
  `/guidelines` or `/forum`).

### Per-site build configuration

- **build-fields-outside-scaffold-region**: None of the per-site build
  configuration's field names (`legacyHomePaths`, `extraRedirects`,
  `requiresBackendUrl`, `handRolledConfig`) MUST ever appear inside the roster's
  mechanically generated region; they MUST live only in the hand-written build
  configuration table outside that region, because a field written inside the
  generated region is silently dropped the next time the region is regenerated.
- **site-build-config-default-empty**: Build-configuration lookup MUST return a
  site's build configuration entry when one exists, and MUST return an empty
  result — never nothing and never a thrown error — for any site with no entry,
  since most sites need no per-site build behavior at all.
- **cookbook-and-hub-excluded-from-site-build**: `cookbook` and `hub` MUST NOT carry
  `legacyHomePaths`, `extraRedirects`, or `requiresBackendUrl` entries in the build
  configuration table; their redirect data derives from site-local modules this
  registry cannot import, and stamping a frozen copy here would recreate the drift
  those modules exist to prevent.

### Reserved slugs

- **reserved-slug-per-site-lookup**: Reserved-slug lookup MUST look up the given
  site's entry in the reserved-slug table and return true when the normalized slug
  (trimmed and lower-cased) is a member of that site's list, and false when it is
  not.
- **reserved-slug-unknown-site-fail-open**: Reserved-slug lookup MUST return false,
  never true and never throw, when the given site has no entry in the reserved-slug
  table; this fail-open behavior is a documented precondition, not a gap — at least
  one real caller passes a raw, unvalidated database column value that cannot be
  statically confirmed as a known site identifier, and that caller's own validation
  is pinned to fail open rather than reject a write for a site this registry has
  never heard of.
- **reserved-slug-normalization**: Both reserved-slug lookup and the cross-site
  reserved-slug check MUST normalize their slug argument by trimming whitespace and
  lower-casing before comparing against a reserved list, so `" Admin "` and `"admin"`
  are treated identically.
- **reserved-slug-anywhere-is-a-cross-site-or**: The cross-site reserved-slug check
  MUST return true when ANY site named in the reserved-slug table reserves the
  normalized slug, computed as the logical OR across every site's list; it MUST NOT
  answer from a single site's list alone, even on the day every list happens to be
  textually identical, because the lists are declared per-site specifically so they
  can diverge later.

### Generated route map

- **site-route-shares-is-the-sole-roster**: The route shares MUST be the only place
  a route share is registered; adding a new region MUST be done by adding one
  share, and no other source may add a share the merged route map draws from.
- **site-routes-merges-all-shares**: The merged route map MUST be the shallow merge
  of every route share, in the shares' own declared order.
- **route-shares-keyed-only-to-family-sites**: Every identifier present across all
  route shares MUST be a valid site identifier that is a member of the main-family
  roster or the marketing-family roster; a route map MUST NOT name a site outside
  that union.
- **route-shares-are-pairwise-disjoint**: A site identifier MUST NOT appear as a key in
  more than one route share; each site's routes are owned by exactly one region's
  generator.
- **route-list-per-site-is-normalized**: Every non-empty route list inside a share
  MUST consist of absolute paths (each beginning with `/`), sorted, and free of
  duplicates.

### Brand story and guided tour

- **site-stories-total-map**: The brand-story map MUST assign exactly one brand
  story (a `tier`, a `pillar`, a `funnelStage`, and a `nextStep`) to every site
  identifier, and to no identifier outside that set; the mapping's own type MUST
  make omitting a newly scaffolded site's story a build-time error rather than a
  silent gap.
- **exactly-one-masterbrand**: Exactly one brand-story entry MUST have
  `tier: 'masterbrand'`, and it MUST be `hub`.
- **next-step-never-self-referential**: A brand-story entry's `nextStep` MUST NOT equal
  its own site identifier.
- **next-step-chains-converge-on-hub**: Following any site's `nextStep` chain
  repeatedly MUST eventually reach `hub`, for every site in the brand-story map —
  whatever door a visitor entered the family through, the brand story MUST lead back
  to the platform.
- **funnel-stage-never-empty**: Every funnel-stage value (`discover`, `learn`,
  `build`, `ship`, `adopt`) MUST be the `funnelStage` of at least one brand-story
  entry.
- **next-step-distinct-from-tour-graph**: A brand story's `nextStep` MUST be read as
  the hand-authored brand-story cross-link only; it MUST NOT be treated as
  interchangeable with an edge in the merged guided-tour graph, since the two are
  separate, independently maintained edge sets over the same site identifiers that
  happen to agree for many sites but are not guaranteed to.
- **tour-rings-are-separately-generated-and-merged**: Each of the three tour rings
  MUST be generated and maintained independently (each owned by a different region's
  own manifest), and the merged guided-tour graph MUST be their merge in a fixed
  order; a site identifier MUST NOT be declared as a key in more than one ring,
  since a collision is absorbed silently by the merge rather than caught at build
  time.
- **tour-ring-may-be-empty**: A tour ring (for example the main ring, which has
  carried no entries since 2026-08-31) legitimately being empty MUST be treated as a
  real, renderable state — "this region's generator has not populated its ring
  yet" — not as an error condition.
- **get-site-story-direct-lookup**: Brand-story lookup MUST return a site's
  brand-story entry directly, with no fallback and no transformation, for any valid
  site identifier.

### Persona and cross-site URL helpers

- **persona-and-registry-paths-percent-encode-slugs**: The persona and registry path
  builders MUST percent-encode every slug segment they place into a path, since a
  slug is untrusted, registrant-supplied text placed directly into a URL path.
- **persona-profile-url-resolves-current-env**: The persona profile URL builder MUST
  resolve the persona registry's current-environment absolute URL via the cross-site
  URL builder, using the current environment's hostname when one is available and an
  empty string otherwise (this concept is also evaluated in a context with no
  ambient page/window, so it MUST NOT read that hostname from any global page state
  directly).
- **site-url-falls-back-to-bare-path**: The cross-site URL builder MUST return the
  path unchanged when the given site identifier resolves to no known site (via site
  lookup), rather than throwing or returning a malformed URL.
- **site-prod-url-ignores-current-environment**: The production URL builder MUST
  always resolve `https://<prodHost><path>` regardless of the caller's current
  environment, since it exists specifically as the deterministic server-rendered
  default computed before the client's own hostname is known.
- **site-home-path-fallback**: The home-path fallback MUST return `/home` when the
  site's `hasHome` is `true`, and `/` otherwise.

