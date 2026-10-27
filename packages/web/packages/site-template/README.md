# @agenticdevelopertoolkit/site-template

The content-site frame. Every content site renders the same page: a window-tall hero, a run of
scrolling bands, the burger drawer and bitbag docked at the foot of the window. This package owns
all of that. A site supplies its copy, its config and any custom slots, and nothing of the frame.

It is built on the landing kit (`@agenticdevelopertoolkit/landing`) and never imports adh.

## Exports

From `@agenticdevelopertoolkit/site-template` (server-safe, no `'use client'`):

| Export | What it is |
| --- | --- |
| `LandingFrame({ page, slots, mark, looks?, pendingLabel? })` | The hero and every band of a landing-kit `LandingPage`. Bands alternate `soft` / `dark`, each wrapped in `Reveal` and headed by `Head` unless the section sets `headingInBlock`; `looks[sectionId]` (a `BandLook`, from `site.json`'s `bands`) gives one band its own tone or drops its seam, and a look naming no section throws. A hero `Shot` is drawn below the hero, bled right. `pendingLabel` (the copy's `screenshotPending`) words every shot not yet taken; absent, the landing kit's own word. |
| `FrameFooter({ copy, slot? })` | The site footer from `copy.footer`; the first line plain, the rest in `<small>`. A `slot` replaces the lines. Renders nothing when the copy has no footer. |
| `FrameMark({ config, alt })` | The site's mark as `site.json` configures it (`mark.src`, in `st-mark st-mark--<shape>`). The skeleton's `/` passes it to `LandingFrame`; a route of the site's own with a hero uses it too, so a change to `mark` reaches every page. |
| `Words({ text })` | A `CopyText`: a plain string, or `{ html }` rendered as markup. |
| `frameMetadata`, `frameViewport`, `frameRobots`, `frameSitemap` | The Next metadata routes, from `FrameCopy` + `FrameConfig`. Robots allow crawling only when `DEPLOYMENT_ENV === 'production'`. The twitter card is `summary` when `ogImage` is the mark's `src` (a square icon beside the text) and `summary_large_image` otherwise; `ogImageSize`, when set, gives the OG image its width and height. |
| `frameSiteUrl(fallbackPort, configured?)` | `SITE_URL`, else `configured` (`site.json`'s `siteUrl`, which the assembler passes), else the Vercel production URL, else `http://localhost:<port>`. |
| types `BandLook`, `CopyText`, `FrameCopy`, `FrameConfig`, `SlotMap` | The shapes a site fills in. |

From `@agenticdevelopertoolkit/site-template/client` (`'use client'`):

| Export | What it is |
| --- | --- |
| `SiteChrome({ copy, page, extra })` | The burger drawer: a Home row labelled `copy.nav.home`, one link per section, then `extra`, then — when the copy has `nav.contact` — a row with that label mailing `copy.contact.email`. Every label is the site's copy; the frame words nothing. The foot carries the drawer hello, the contact email and the byline. When the copy has `nav.action` (`{ label, href }`, a paragraph that is only a link), it is a ghost button at the bar's right end on a wide viewport. |
| `SiteBitbag(props?)` | bitbag, client-only via `next/dynamic`, with his dock stylesheet; his `BitbagStandalone` props pass through (`voice`, `rest`, `theme`). Mount once beside `<main>`. |

## Slots

`SlotMap` lets a site replace a piece of the frame without owning it:

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

- **One face per weight and style.** Only the base cut of each face is listed, not the `-ext` one.
  `next/font/local` cannot give a file its own `unicode-range`, so two files with the same
  weight and style would become two identical faces, and the later one would win every glyph. The
  base cut covers the glyphs the sites use.
- **`role` and `fallback`.** next/font hashes the family name, so a theme sheet that names its
  family (`--font-mono: 'Iosevka', …`) never finds the self-hosted face. A font's `role` names
  the theme custom property it fills, or a list of them. For each one the assembler writes
  `<role>: var(<variable>), <fallback>;` into an `html:root` rule in `app/theme.css`, after the
  theme and kit sheets and before the site's tokens. `html:root`, not `:root` (the assembler's
  `RAISED_ROOT`): fishlamp.css declares its font roles on `html:root`, specificity (0,1,1), which
  beats any plain `:root` (0,1,0) wherever it sits; at equal specificity, source order decides. `fallback` is the rest of the theme's own stack.
  fishlamp lists `--font-mono`, `--font-sans` and `--font-serif`, every property its sheet names
  `'Iosevka'` in. `--font-display` is left out because it follows `--font-serif`. A site's
  `fonts` in `site.json` take the same two keys.

## A site's layout

A site repo holds `site/` and the app the assembler writes from it, and nothing of the frame.

```
site/
  site.json        placement config (schema/site.schema.json): output, port, theme, tokens, mark, slots, ...
  theme.css        the token sheet (named by `tokens` in site.json)
  components/      custom slot components      -> src/components/
  routes/          extra Next routes           -> app/
  src/             code those need             -> src/
  public/          static assets               -> public/
  app-root/        files for the app root
```

`site.json` is closed: a misspelt key is an error. `schema/site.schema.json` lists every key.

## Slots in `site.json`

`slots` maps a place in the frame to `"file.tsx#Name"`, a file under `site/components/` and its
export. The keys are:

| Key | Fills |
| --- | --- |
| `hero` | the hero, in place of the data hero |
| `afterHero` | between the hero and the first band |
| `footer` | the footer lines |
| `bitbag` | bitbag, in place of the frame's |
| `band:<id>` | the blocks of the band for section `<id>`; the id must name a section of `src/landing.json` |

## Band looks in `site.json`

`bands` maps a section id to how that band steps out of the soft/dark alternation:
`{ "tone": "paper" }` for the page's one light band, `{ "seam": false }` for a band whose
neighbour above is its own tone. What a look leaves out keeps the alternation's. An id that
names no section of `src/landing.json` is refused, as a `band:<id>` slot's is.

## The token sheet

`tokens` names a sheet under `site/`. It may hold only custom-property declarations inside
`:root { }` (it is appended after the theme and the frame sheets, so it overrides them). Any other
rule, a nested rule, or a declaration that is not a `--property` is refused. The assembler writes
each of the sheet's top-level `:root` selectors as `html:root` (`raise_roots`, skipping comments
and strings), for the reason the font roles are: a theme's own `html:root` would otherwise beat
the site's tokens.

## The reset

`app/theme.css` opens with `@import "tailwindcss/preflight.css" layer(base);` (`RESET_IMPORT`):
tailwind's preflight alone, the document reset the landing kit's sheets were drawn against (every
site before the template imported all of tailwind; without it `body` keeps the browser's 8px
margin). Not the whole of `tailwindcss`: its theme variables and utility generation are unused
here, and it would scan the site's sources for class names. In `@layer base`, it is outranked by
every unlayered theme, kit, frame and token rule after it.

A site's own component and route CSS may not name `.lp-*` or `.st-*` classes, or `html`, `body`
(or `:root`, which is `html`), in a selector: those belong to the frame. Style your own classes.

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
and scrolled one window. It writes a small Node script to a temp dir and runs it with
`npx --yes -p playwright@1.58.2`; there is no Python Playwright dependency.

`text_parity.py` compares the visible text of two pages (outside `script`, `style`, `noscript`),
whitespace-normalised, one line per block element, and prints a unified diff. It exits 1 when
they differ outside the allow file, whose lines are diff lines (`-old` / `+new`; `#` comments).
The words on every page must not change; every visual difference goes in the site's commit message.

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
