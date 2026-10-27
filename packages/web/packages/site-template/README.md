# @agenticdevelopertoolkit/site-template

The content-site frame. Every content site renders the same page: a window-tall hero, a run of
scrolling bands, the burger drawer and bitbag docked at the foot of the window. This package owns
all of that. A site supplies its copy, its config and any custom slots, and nothing of the frame.

It is built on the landing kit (`@agenticdevelopertoolkit/landing`) and never imports adh.

## Exports

From `@agenticdevelopertoolkit/site-template` (server-safe, no `'use client'`):

| Export | What it is |
| --- | --- |
| `LandingFrame({ page, slots, mark })` | The hero and every band of a landing-kit `LandingPage`. Bands alternate `soft` / `dark`, each wrapped in `Reveal` and headed by `Head` unless the section sets `headingInBlock`. |
| `FrameFooter({ copy, slot? })` | The site footer from `copy.footer`; the first line plain, the rest in `<small>`. A `slot` replaces the lines. Renders nothing when the copy has no footer. |
| `Words({ text })` | A `CopyText`: a plain string, or `{ html }` rendered as markup. |
| `frameMetadata`, `frameViewport`, `frameRobots`, `frameSitemap` | The Next metadata routes, from `FrameCopy` + `FrameConfig`. Robots allow crawling only when `DEPLOYMENT_ENV === 'production'`. |
| `frameSiteUrl(fallbackPort)` | `SITE_URL`, else the Vercel URL, else `http://localhost:<port>`. |
| types `CopyText`, `FrameCopy`, `FrameConfig`, `SlotMap` | The shapes a site fills in. |

From `@agenticdevelopertoolkit/site-template/client` (`'use client'`):

| Export | What it is |
| --- | --- |
| `SiteChrome({ copy, page, extra })` | The burger drawer: Home, one link per section, then `extra`; the foot carries the drawer hello, the contact email and the byline. |
| `SiteBitbag()` | bitbag, client-only via `next/dynamic`, with his dock stylesheet. Mount once beside `<main>`. |

## Slots

`SlotMap` lets a site replace a piece of the frame without owning it:

- `hero` replaces the data hero; the `#top` full-height frame stays.
- `afterHero` renders between the hero and the first band.
- `bands[sectionId]` replaces that band's blocks; the band, its tone, `Reveal` and `Head` stay. A key
  that names no section throws, naming the page's sections.
- `footer` replaces the footer lines.

If the page's hero data carries a `status`, the pill is rendered first in the hero's actions row.

## The two barrels

`src/index.ts` and `src/client-barrel.ts` are separate tsup builds so the server barrel can never
inherit `'use client'` from a shared chunk. `tools/check_template_directives.py` asserts this on
every build (`dist/index.js` has no directive, `dist/client.js` has it); its tests are
`tools/check_template_directives_test.py`, run by `pnpm lint`.

## Scripts

```
pnpm --filter @agenticdevelopertoolkit/site-template run build
pnpm --filter @agenticdevelopertoolkit/site-template run test
pnpm --filter @agenticdevelopertoolkit/site-template run lint
```
