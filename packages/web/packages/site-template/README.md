# @agenticdevelopertoolkit/site-template

The content-site frame. Every content site renders the same page: a window-tall hero, a run of
scrolling bands, the burger drawer and bitbag docked at the foot of the window. This package owns
all of that. A site supplies its copy, its config and any custom slots, and nothing of the frame.

It is built on the landing kit (`@agenticdevelopertoolkit/landing`) and never imports adh.

## Exports

From `@agenticdevelopertoolkit/site-template` (server-safe, no `'use client'`):

| Export | What it is |
| --- | --- |
| `LandingFrame({ page, slots, mark, looks?, pendingLabel? })` | The hero and every band of a landing-kit `LandingPage`. Bands alternate `soft` / `dark`, each wrapped in `Reveal` and headed by `Head` unless the section sets `headingInBlock`. A section with no title shows its eyebrow alone (`aria-hidden`) and gets an `<h2 class="st-sr-only">` of the same words, so every band is still a heading; `looks[sectionId]` (a `BandLook`, from `site.json`'s `bands`) gives one band its own tone or drops its seam, and a look naming no section throws. A hero `Shot` is drawn below the hero, bled right. `pendingLabel` (the copy's `screenshotPending`) words every shot not yet taken; absent, the landing kit's own word. |
| `FrameBand({ id, tone?, seam?, children })` | One band as the frame draws it: the kit's `Band` with its contents in a `Reveal` (inside the band, so the seam's stacking holds). `LandingFrame` draws every band with it; a route of the site's own uses it so its bands enter the way `/`'s do. |
| `frameShot(pendingLabel)` | The landing kit's `Shot` worded once for a site: a shot not yet taken says `pendingLabel` unless it passes its own. The assembler binds it to the copy's `screenshotPending` in the generated `src/site/shot.tsx` as `SiteShot`, so a custom band imports that from `@/site/shot` instead of passing the word to each shot. A factory, not a context, because the frame and slots are server components. |
| `FrameFooter({ copy, slot? })` | The site footer from `copy.footer`; the first line plain, the rest in `<small>`. A `slot` replaces the lines. Renders nothing when the copy has no footer. |
| `FrameMark({ config, alt })` | The site's mark as `site.json` configures it (`mark.src`, in `st-mark st-mark--<shape>`). The skeleton's `/` passes it to `LandingFrame`; a route of the site's own with a hero uses it too, so a change to `mark` reaches every page. |
| `Words({ text })` | A `CopyText`: a plain string, or `{ html }` rendered as markup. |
| `FrameZoomGuard()` | Pinch-zoom back off iOS on every route. `frameViewport` ships `maximum-scale=1` (the only way to stop iOS zooming into a focused field), which also kills pinch-zoom everywhere else; this strips it back off outside iOS. The skeleton's root layout renders it first in `<body>`, so a site's own routes and the 404 keep pinch-zoom as `/` does. |
| `frameMetadata`, `frameViewport`, `frameRobots`, `frameSitemap` | The Next metadata routes, from `FrameCopy` + `FrameConfig`. Copy `keywords` (site.md's `# keywords` list), when worded, become the metadata's keywords. Robots allow crawling only when `DEPLOYMENT_ENV === 'production'`. The twitter card is `summary` when `ogImage` is the mark's `src` (a square icon beside the text) and `summary_large_image` otherwise; `ogImageSize`, when set, gives the OG image its width and height, and `ogImageType` its `og:image:type`. `authorUrl`, when set, is the author's `url`, which Next also writes as `<link rel="author">`. `frameMetadata` is the root layout's, so every route inherits it; it therefore carries no canonical and no Open Graph `url`. |
| `frameHomeMetadata(copy, config)` | `/`'s own metadata: the canonical (`/`) and the Open Graph card with its `url`, which only the home page carries, so a site's custom routes never claim to be copies of `/`. The skeleton's `app/(frame)/page.tsx` exports it. |
| `frameNotFoundMetadata(copy)` | The 404's metadata: `copy.notFound.title` when the copy words a 404, otherwise the title Next's built-in 404 gives its tab (`404: This page could not be found.`), so a site that had no 404 of its own keeps the same tab text. A plain title either way. It also undoes what the 404 would inherit from the root layout: `noindex, nofollow`, no canonical, and no Open Graph or twitter card, so a dead link neither names the home page canonical nor unfurls as it. The skeleton's `app/not-found.tsx` exports it. |
| `FrameNotFound({ copy })` | The 404's screen in the window-tall hero frame. With `copy.notFound` (`title`, `code`, `heading`, `body`, `back`) it shows the code as a caption, the heading, the body and a plain link back to `/`; without it, Next's own `404` / `This page could not be found.`. The skeleton's `app/not-found.tsx` renders it inside the frame. |
| `frameSiteUrl(fallbackPort, configured?)` | `SITE_URL`, else `configured` (`site.json`'s `siteUrl`, which the assembler passes), else the Vercel production URL, else `http://localhost:<port>`. |
| types `BandLook`, `CopyText`, `FrameCopy`, `FrameConfig`, `SlotMap` | The shapes a site fills in. |

From `@agenticdevelopertoolkit/site-template/client` (`'use client'`):

| Export | What it is |
| --- | --- |
| `SiteChrome({ copy, page, extra })` | The burger drawer: a Home row labelled `copy.nav.home`, one link per section, then `extra` (`site.json`'s `drawer` rows, `{ href, nav }`, each labelled by the copy's `nav.extra[nav]` — site.md's `# nav` / `## extra` list; a `nav` the copy does not word throws), then — when the copy has `nav.contact` — a row with that label mailing `copy.contact.email`. Every label is the site's copy; the frame words nothing. The foot carries the drawer hello, the contact email and, when the copy words one, the byline. When the copy has `nav.action` (`{ label, href }`, a paragraph that is only a link), it is a ghost button at the bar's right end on a wide viewport. |
| `SiteBitbag(props?)` | bitbag, client-only via `next/dynamic`, with his dock stylesheet; his `BitbagStandalone` props pass through (`voice`, `rest`, `theme`). Mount once beside `<main>`. |

From `@agenticdevelopertoolkit/site-template/next` (node, for `next.config.ts` only; never a page):

| Export | What it is |
| --- | --- |
| `frameThemeFonts(site, appDir)`, `frameBuildIdentity(site, appDir)` | The build's side of `themeFonts` and `buildIdentity`: the theme's faces copied under `<appDir>/public/fonts/`, and the `NEXT_PUBLIC_ADH_*` identity env. Each does nothing for a site that leaves its key out. See "Theme fonts, build identity and stale times" below. |
| `frameNext(site, env)` | `site.json`'s `rewrites` and `publicEnv` resolved against `env` (`process.env`), and its `headers` and `redirects` as written: `{ env, rewrites, headers, redirects }`, which the skeleton's `next.config.ts` merges into its config. Throws, naming the variable and where it was used, when a `${NAME}` has no value. See "Rewrites and public env" below. |
| types `FrameNextSite`, `FrameRewrite`, `FrameHeader`, `FrameRedirect`, `FrameEnvDefault`, `FrameEnvChoice`, `FrameNextResult`, `FrameNextHeader` | The generated `src/site/next.ts`'s shape (`FrameHeader` is one `site.json` `headers` rule; `FrameEnvChoice` an `envDefaults` value chosen by a variable), and the result (`FrameNextHeader` is a header rule with the mutable list Next's `headers` takes). |

## Slots

`SlotMap` lets a site replace a piece of the frame without owning it:

- `header` replaces the bar and drawer with the site's own header — for a site whose visitors
  sign in, where the header carries the session. It is the one slot that replaces its place
  rather than the place's contents.
- `hero` replaces the data hero; the `#top` full-height frame stays.
- `afterHero` renders between the hero and the first band.
- `bands[sectionId]` replaces that band's blocks; the band, its tone, `Reveal` and `Head` stay. A key
  that names no section throws, naming the page's sections.
- `footer` replaces the footer lines.
- `bitbag` replaces the frame's `<SiteBitbag />`. A site whose bitbag speaks in its own voice
  needs it: a voice holds RegExps, which cannot pass from the server layout into his client-only
  mount, so the site's own `'use client'` component renders `SiteBitbag` with them.

If the page's hero data carries a `status`, the pill is rendered first in the hero's actions row.
A hero `Shot` (`{shot: id}` in the hero's markdown) is the hero's one screenshot, below it.

## Themes (`themes.json`)

Each theme names its stylesheet and the fonts it needs, which the assembler self-hosts through
`next/font/local`. Font file paths are relative to the toolkit's `packages/web/`.

| Theme | Sheet | For |
|---|---|---|
| `fishlamp` (the default) | `themes/styles/fishlamp.css` | fishlamp.com's palette, with its lamp glow on `body` |
| `mikefullerton` | `themes/styles/mikefullerton-landing.css` | mikefullerton.com's `/`: fishlamp's ink and ember with the site's own dim text and hover edge, as roles only — no `body` rule, so a site's other routes keep their own look. Not the manifest's `mikefullerton.css`, which is the previous site's palette |
| `charcoal` | `themes/styles/charcoal.css` | the ADH family's own palette (near-black charcoal, brand gold), dark-always, as roles only — no `body` rule, so a site's family routes keep the look their own layout gives them |

- **One face per weight and style.** Only the base cut of each face is listed, not the `-ext` one.
  `next/font/local` cannot give a file its own `unicode-range`, so two files with the same
  weight and style would become two identical faces, and the later one would win every glyph. The
  base cut covers the glyphs the sites use.
- **`role` and `fallback`.** next/font hashes the family name, so a theme sheet that names its
  family (`--font-mono: 'Iosevka', …`) never finds the self-hosted face. A font's `role` names
  the theme custom property it fills, or a list of them. For each one the assembler writes
  `<role>: var(<variable>), <fallback>;` into one rule in `app/theme.css`, after the theme and
  kit sheets and before the site's tokens. Its prelude is the assembler's `RAISED_ROOT`, the
  five selectors every template theme declares its palette on: `html:root` (0,1,1) and the four
  `html:root[data-color-mode]…` states, up to (0,5,1). A plain `:root` (0,1,0) loses to the
  first wherever it sits, and a lone `html:root` loses to the rest once anything sets
  `data-color-mode` on `<html>` (a family shell's colour-mode provider does, on every route it
  draws). On the same list, source order decides in every state. `fallback` is the rest of the
  theme's own stack.
  fishlamp lists `--font-mono`, `--font-sans` and `--font-serif`, every property its sheet names
  `'Iosevka'` in. `--font-display` is left out because it follows `--font-serif`. A site's
  `fonts` in `site.json` take the same two keys. A font file is woff2, woff, ttf or otf.
- **`preload`.** A file is preloaded unless it says `"preload": false`. A family with an
  unpreloaded face is written as two `localFont` calls declaring one family name (the second
  with `preload: false`), so the face still serves the same family and is fetched only when a
  page sets it. A family must preload at least one face. fishlamp serves the toolkit's site cut
  of Iosevka (`iosevka-site-*.woff2`, from the themes package's `scripts/subset-fonts.py --cut
  site`): Regular and Bold preload, the italic does not.

## A site's layout

A site repo holds `site/` and the app the assembler writes from it, and nothing of the frame.

```
site/
  site.json        placement config (schema/site.schema.json): output, port, theme, tokens, mark, slots, ...
  theme.css        the token sheet (named by `tokens` in site.json)
  components/      custom slot components      -> src/components/
  routes/          routes inside the frame     -> app/(frame)/
  app-routes/      routes outside the frame    -> app/
  src/             code those need             -> src/
  public/          static assets               -> public/
  app-root/        files for the app root
```

`site.json` is closed: a misspelt key is an error. `schema/site.schema.json` lists every key.

### The frame is a route group

The skeleton's root `app/layout.tsx` is the document alone: `<html>` and `<body>`, the fonts,
`theme.css`, the metadata and viewport, the site's JSON-LD and its analytics. The frame — the
bar and drawer, the footer, bitbag — is `app/(frame)/layout.tsx`, which wraps the skeleton's `/`
(`app/(frame)/page.tsx`) and every route under `site/routes/`. `site/app-routes/` lands at `app/`,
outside the group: a route there renders bare and brings its own `layout.tsx` and providers — an
app behind sign-in, an auth callback. `(frame)` is a route group, so neither tree changes a URL.

`robots`, `sitemap` and a site's metadata files (an `icon.png` belongs in `app-routes/`, so it
stays at the root) are outside the frame. The 404 (`app/not-found.tsx`) stays at the root too —
Next renders a root `not-found` inside the root layout alone — and wraps itself in the frame's
layout, so a missing page keeps the bar and footer. Two files that would
serve one URL — the same route in both trees, a page and a route handler, an `app-routes/page.tsx`
against the frame's `/` — are refused, naming both. So is a site file on any path the skeleton
writes (`app-routes/layout.tsx` is the root layout's path).

`robots.txt` disallows everything on every tier but production. In production it allows `/` and
disallows the paths `site.json`'s `robotsDisallow` lists, when it lists any — the sign-in pages
and the app behind them, on a site that has one.

The sitemap lists `/` and `site.json`'s `sitemap` paths. A site whose pages are not knowable when
it is written — a corpus read from a backend — names a function that computes the rest:
`"sitemapRoutes": "lib/sitemap-routes.ts#loadRoutes"`, a file under `site/src/` and its export.
It is an async function returning `FrameSitemapRoute[]` (a `path` and, optionally, the
`lastModified`, `changeFrequency` and `priority` it knows; the listed paths' monthly, 0.8 and
build time fill what it leaves out). The assembler writes `src/site/sitemap.ts`, which the
skeleton's `app/sitemap.ts` awaits. It runs when Next renders the sitemap — at build, and again
on the revalidation its own fetches set — so it should fail soft and return `[]`: a sitemap
missing its corpus for one window is recoverable, a failed build is not.

## Rewrites and public env in `site.json`

```json
"rewrites": [{ "source": "/api/:path*", "destination": "${API_BACKEND_URL}/:path*" }],
"publicEnv": ["NEXT_PUBLIC_AUTH_API_URL"],
"envDefaults": {
  "API_BACKEND_URL": {
    "by": "DEPLOYMENT_ENV",
    "values": { "production": "https://api.example.com", "staging": "https://staging.api.example.com" },
    "local": "https://staging.api.example.com"
  },
  "NEXT_PUBLIC_AUTH_API_URL": "${API_BACKEND_URL}"
}
```

The assembler writes them to `src/site/next.ts`; `next.config.ts` resolves them with `frameNext`
as it loads, so a missing value fails `next build` rather than a request. A `${NAME}` (or
`${NAME:-default}`) is the environment's value when it is set and non-empty, else the
`envDefaults` entry, else the inline default; with none, the build fails naming it. An
`envDefaults` entry is a string (which may use `${…}` itself) or `{ by, values, local? }`: the
value `values` names for the variable `by`, and `local` when `by` names none — off Vercel only,
so a misspelt tier on Vercel fails the build instead of quietly getting `local`'s backend.
`local` may itself be a `{ by, values, local? }` choice, one level deep, for a site whose local
builds pick a backend by a second variable — production's API for a local `next build`, a local
one under `next dev`:

```json
"API_BACKEND_URL": {
  "by": "DEPLOYMENT_ENV",
  "values": { "production": "https://api.example.com" },
  "local": { "by": "NODE_ENV", "values": { "production": "https://api.example.com" }, "local": "http://localhost:3000" }
}
```

A value joined to a path (`${API_BACKEND_URL}/auth/:path*`) loses its trailing slashes, so
`API_BACKEND_URL=https://api.example.com/` still gives one slash at the join; a value with no path
after it is substituted whole.

One exemption: under `next typegen`, which the workspace typecheck runs before `tsc`, an unset
variable in a rewrite's destination resolves to `http://typegen-only.invalid` instead of
throwing. Typegen types each rewrite's source and never serves a destination, but it loads the
config under the same phase as `next build`, so the typecheck says which it is with
`TYPEGEN_ONLY=1` (read by `@agentic-toolkit/next-env`'s `isTypegenOnly`). `next build` and
`next dev` never set it and still fail by name. `publicEnv` is not exempt.

`publicEnv` names go to Next's `env` (inlined into client code). One with no value anywhere fails
the build, naming it — a client bundle inlining `undefined` is the failure it would otherwise be —
unless the site writes it `${NAME:-}`, which says the variable is optional; that one is left out.
A malformed `${…}` is refused at assembly.

The skeleton's `next.config.ts` also sets `allowedDevOrigins` (`*.dev.local`, `dev.local`,
`127.0.0.1`, the hosts the suite serves `next dev` behind; no effect on a production build) and
`transpilePackages`: every toolkit package the app reaches — its own `link:` dependencies and,
transitively, every toolkit package those depend on (the template's own, the landing kit's
textlens) — which the assembler lists in `src/site/next.ts`.

## Response headers in `site.json`

```json
"headers": [
  {
    "source": "/(.*)",
    "headers": [
      { "key": "X-Frame-Options", "value": "SAMEORIGIN" },
      { "key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains" }
    ]
  }
]
```

Next's own `headers` shape: each rule's `source` is a Next path pattern (`/(.*)` is every route)
and its `headers` at least one `{ key, value }`. Values are literal — nothing is substituted — and
the skeleton's `next.config.ts` hands them to Next only when there is at least one rule. A key
that is not an HTTP header name is refused at assembly.

## Redirects in `site.json`

```json
"redirects": [
  { "source": "/home/settings/:rest*", "destination": "/settings/:rest*", "permanent": false }
]
```

Next's own `redirects` shape, in the order Next matches them; each rule needs all three keys.
Literal, as headers are. A site that sets none has no `redirects` in its `src/site/next.ts`, and
the skeleton's `next.config.ts` hands Next none.

## Theme fonts, build identity and stale times in `site.json`

Three switches for a site whose pages are the fleet's app rather than the frame:

- `"themeFonts": true` — `frameThemeFonts` copies the theme's self-hosted woff2 faces into the
  app's `public/fonts/` as `next.config.ts` loads, in `next dev` and `next build` alike. A site
  that inlines the theme's css itself (`AdhThemeStyle`) names those faces by absolute path, so
  they must exist on disk. The copy fails the build when it cannot be made.
- `"buildIdentity": true` — `frameBuildIdentity` adds `NEXT_PUBLIC_ADH_SITE_VERSION` (the app's
  `VERSION` file, from `site/app-root/VERSION`) and `NEXT_PUBLIC_ADH_RELEASE` (Vercel's or
  Railway's commit, else `git rev-parse HEAD`) to the client env: what the fleet footer shows.
  It reads them through `@agentic-toolkit/next-env`, bundled into `./next`.
- `"staleTimes": { "dynamic": 30 }` — Next's `experimental.staleTimes`, in whole seconds.

Each is left out of `src/site/next.ts` when the site leaves it out of `site.json`.

`NEXT_DIST_DIR`, when set, is the build directory in place of `.next` — an e2e run's dev server
building into `.next-e2e` beside a dev server already serving the checkout. The skeleton's
`tsconfig.json` leaves every `.next-*` out of the typecheck. It is also exactly the file `next dev`
would write — Next's own format, and the type globs of both `.next` and `.next-e2e` — because a
dev server that finds a glob missing rewrites the file, and an e2e run would leave the tree dirty.

## Scripts in `site.json`

`scripts` adds package.json scripts to the template's, or replaces its checks — `test`, `lint`,
`typecheck` — for a site whose tests are not the template's `node --test` (`{ "test": "vitest run",
"test:e2e": "playwright test" }`). `dev`, `build` and `start` are refused: the suite, Vercel and
`next start` run every site through them the same way.

The template's scripts include `build:next` (`next build`), which every site repo's
`deployment/build` gate runs. A site whose build needs a step first replaces it, e.g.
`{ "build:next": "npm run fetch-openapi && next build" }`.

## Next is pinned

The generated package.json asks for `next` `16.2.9` exactly, not `^16.2.9`. Every 16.3.x
release tried (16.3.3, 16.3.8) panics when Turbopack prints a source code frame for a CSS
warning and the frame's line holds a box-drawing comment rule, which this fleet writes
everywhere:

```
thread 'tokio-rt-worker' panicked at crates/next-code-frame/src/highlight.rs:1021:45:
end byte index 93 is not a char boundary; it is inside '─' (bytes 91..94 of string)
```

The panic is fatal: `next build` exits with no diagnostic, and `next dev` dies mid e2e run. A
range let any lockfile generated fresh float onto it. Reproduced 2026-10-28 by importing the
markdown package's stylesheet as it was before toolkit `d813c3347` (an `@source` warning framed
over `/* ── … */`) into a templated site: 16.3.3 and 16.3.8 panic; 16.2.9 and 16.4.3 build.
Move the pin forward only to a release that builds that repro clean — a plain `next build`
shows it in seconds.

`@next/eslint-plugin-next` is pinned to the same exact version: it ships in lockstep with `next`,
and as a range it floated to 16.3.3 in every site's lockfile while `next` stayed on 16.2.9. Move
the two together.

## ESLint entries in `site.json`

`eslint` lists the site's own flat-config entries — `files`, `ignores` and `rules`, plain JSON —
and the generated `eslint.config.mjs` puts them after the template's, so they outrank it:

```json
"eslint": [
  { "files": ["**/*.{ts,tsx}"], "rules": { "react-hooks/set-state-in-effect": "warn" } }
]
```

With no `eslint` the config is the skeleton's, byte for byte. It is a `site.json` key, not a site
config file, because the app is linted two ways — `pnpm lint`, and workspace tools that run
`eslint .` and never read the package script — and both load the one generated config. An
`eslint.config.*` under `site/app-root/` is refused: ESLint 9 loads `eslint.config.js` ahead of
`.mjs`, so it would silently stand in for the template's. A plugin or a parser is a module, which
JSON cannot hold; one every site needs belongs in the skeleton's config.

## Analytics

`"analytics": true` writes `src/site/analytics.tsx` mounting `@vercel/analytics` and
`@vercel/speed-insights` (added to the app's dependencies at the template's pinned ranges) when
`DEPLOYMENT_ENV` is `production`; the root layout renders it on every route. Absent or false, the
file renders nothing and neither package is added.

## Slots in `site.json`

`slots` maps a place in the frame to `"file.tsx#Name"`, a file under `site/components/` and its
export. The keys are:

| Key | Fills |
| --- | --- |
| `header` | the top of the page, in place of the frame's bar and drawer |
| `hero` | the hero, in place of the data hero |
| `afterHero` | between the hero and the first band |
| `footer` | the footer lines |
| `bitbag` | bitbag, in place of the frame's |
| `band:<id>` | the blocks of the band for section `<id>`; the id must name a section of `src/landing.json` |

A slot that draws a screenshot uses `SiteShot` from `@/site/shot` (generated), which already
carries the site's word for a shot not yet taken.

## Band looks in `site.json`

`bands` maps a section id to how that band steps out of the soft/dark alternation:
`{ "tone": "paper" }` for the page's one light band, `{ "seam": false }` for a band whose
neighbour above is its own tone. What a look leaves out keeps the alternation's. An id that
names no section of `src/landing.json` is refused, as a `band:<id>` slot's is.

## The token sheet

`tokens` names a sheet under `site/`. It may hold only custom-property declarations inside
`:root { }` (it is appended after the theme and the frame sheets, so it overrides them). Any other
rule, a nested rule, or a declaration that is not a `--property` is refused. The assembler writes
each of the sheet's top-level `:root` selectors as `RAISED_ROOT` (`raise_roots`, skipping
comments and strings), for the reason the font roles are: the theme's own palette rule would
otherwise beat the site's tokens.

Besides the kit's `--lp-*` tokens, the frame reads three of its own: `--st-hero-meta-transform`
(the hero meta's `text-transform`, default `uppercase`), `--st-hero-extra` (added to the hero's
window height, default `0px`; `var(--lp-seam)` grows the hero by the first band's cut, so the
first screen shows nothing of that band) and `--st-band-clear` (a band's `scroll-margin-top`, so a
drawer jump to `/#<id>` lands it below the fixed bar; default the bar's height, the 32px burger
plus `--lp-bar-pad-y` above and below it).

## The reset

`app/theme.css` opens with `@import "tailwindcss/preflight.css" layer(base);` (`RESET_IMPORT`):
tailwind's preflight alone, the document reset the landing kit's sheets were drawn against (every
site before the template imported all of tailwind; without it `body` keeps the browser's 8px
margin). Not the whole of `tailwindcss`: its theme variables and utility generation are unused
here, and it would scan the site's sources for class names. In `@layer base`, it is outranked by
every unlayered theme, kit, frame and token rule after it.

A site's own component and route CSS may not name `.lp-*` or `.st-*` classes, or `html`, `body`
(or `:root`, which is `html`), in a selector: those belong to the frame. Style your own classes.
A sheet confined with `/*! @confine .marker */` may name `html`, `body` and `:root`, since it
applies only in the documents that carry its marker; it still may not name the frame's classes.

## Assemble, check, update

```
python3 tools/assemble_site.py --site <site repo>            # write
python3 tools/assemble_site.py --site <site repo> --check    # write nothing
```

Every command below runs from the toolkit's `packages/web/packages/site-template/` directory. The template used is whichever toolkit copy runs the script.

| Exit | Meaning |
| --- | --- |
| 0 | written, or (`--check`) up to date |
| 1 | `--check` found drift; one stale path per line on stdout |
| 2 | invalid input; one problem per line on stderr, each prefixed `assemble: ` |
| 3 | the template's own schema uses a keyword the checker does not implement (the template's bug) |

To update a site to a newer template, bump the toolkit, run the assembler, and commit what it
changed. `--check` in CI proves nobody hand-edited the output.

The assembler never writes or deletes `src/content/**`, `src/landing.json`, `src/landing.tsx` or
`public/glyph.svg`: content-buildr owns them. Never hand-edit them, or any generated file.

## Build on Vercel

Every templated site runs ONE build entry, `tools/build-site.py`, from its own submodule. Its
`site/app-root/vercel.json` (Root Directory = the site's output) reads:

```
"buildCommand": "python3 ../external/agenticdevelopertoolkit/packages/web/packages/site-template/tools/build-site.py"
```

It installs and builds the toolkit packages the site's `package.json` `link:`s (each with its
workspace dependencies, and refusing a filter pnpm would match to nothing), then runs the site's
`next build`. `--toolkits-only` stops after the dists, for a dev server; `--site DIR` names the
site when it is not the working directory. A site keeps no copy of it.

## A layout bug is fixed here

If a page looks wrong because of the frame (spacing, the hero, the drawer, the bitbag dock), fix
it in this package and bump the toolkit. Never patch it in a site: a site has no frame CSS to
patch, and the assembler refuses the selectors that would try.

## Proving a change

```
python3 tools/screens.py --url http://localhost:3000 --out /tmp/after [--route /about ...]
python3 tools/text_parity.py before.html after.html [--allow allowed.txt]
```

`screens.py` writes `<route-slug>-<w>x<h>-{rest,scrolled}.png` for 1280x800 and 390x844, at rest
and scrolled one window. `/`'s slug is `index`, so a site's `/home` never overwrites it. It writes a small Node script to a temp dir and runs it with
`npx --yes -p playwright@1.58.2`; there is no Python Playwright dependency.

`text_parity.py` compares the visible text of two pages (outside `script`, `style`, `noscript`),
whitespace-normalised, one line per block element, and prints a unified diff. It exits 1 when
they differ outside the allow file, whose lines are diff lines (`-old` / `+new`; `#` comments).
The words on every page must not change; every visual difference goes in the site's commit message.

## The barrels

`src/index.ts` and `src/client-barrel.ts` are separate tsup builds so the server barrel can never
inherit `'use client'` from a shared chunk. `tools/check_template_directives.py` asserts this on
every build (`dist/index.js` has no directive, `dist/client.js` has it); its tests are
`tools/check_template_directives_test.py`, run by `pnpm lint`. `src/frame-next.ts` is a third,
built for node as `dist/next.js`: only `next.config.ts` imports it.

## Scripts

```
pnpm --filter @agenticdevelopertoolkit/site-template run build
pnpm --filter @agenticdevelopertoolkit/site-template run test
pnpm --filter @agenticdevelopertoolkit/site-template run lint
```
