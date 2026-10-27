import type { ReactElement, ReactNode } from 'react'
import {
  Deck,
  DeckScript,
  Head,
  Hero,
  indexRows,
  renderBlock,
  Screen,
  TourStrip,
  Wrap,
} from '@agenticdevelopertoolkit/landing'
// The deck's index — burger, scrim and drawer — and the ONE client component on the page.
// By PACKAGE PATH rather than a relative import, and from `/client` rather than the main
// barrel, for the same reason `marketing/index.ts` imports MarketingSiteHeader that way:
// esbuild-plugin-preserve-directives propagates a chunk's `'use client'` to every entry
// that inlines it, so a bundled NavChrome would hoist the directive over this whole module
// and turn the deck — every screen, every block, all of a site's landing copy — into a
// Client Component. The specifier is external (see the `@agenticdevelopertoolkit/landing/*` line
// in tsup.config.ts), so the boundary stays where the landing package put it.
import { NavChrome } from '@agenticdevelopertoolkit/landing/client'
import type { LandingSection, NavLink } from '@agenticdevelopertoolkit/landing'
import { TOUR_SCREEN_ID, tourStep } from './tour'
import type { LandingContent } from './tour'

/** One screen. */
function renderSection(section: LandingSection, key: number): ReactElement {
  return (
    <Screen key={key} id={section.id}>
      <Wrap>
        {/* `title` is passed through undefined-and-all: `Head` renders no `<h2>` without
            one, where an empty node would be a present-but-empty prop it cannot tell from
            content. A `headingInBlock` section gets no `<Head>` at all — its block carries
            the heading, and two eyebrows read as two sections. */}
        {section.headingInBlock === true ? null : (
          <Head eyebrow={section.eyebrow} title={section.title} />
        )}
        {section.blocks.map((block, i) => renderBlock(block, i))}
      </Wrap>
    </Screen>
  )
}

/**
 * The deck itself, assembled once for the whole family.
 *
 * `lead` is whatever screen goes AHEAD of the hero, and `leadRow` is that screen's row in
 * the index — the two orders have to agree, and a menu whose first entry is the second
 * screen sends the reader up the page. `/` passes neither.
 *
 * The index is the deck's first child, ahead of everything. Everything it draws is
 * `position: fixed`, so it adds no row to the column and no snap point to the deck wherever
 * it sits; first is for the reader of this file, where a page's chrome reads first.
 */
function deck(
  content: LandingContent,
  lead: ReactNode,
  leadRow: NavLink | undefined,
): ReactElement {
  const rows = leadRow === undefined ? indexRows(content) : [leadRow, ...indexRows(content)]
  return (
    <>
      <DeckScript />
      <Deck>
        {/* No `brand`: the wordmark in the shared `.adh-header` above is the site's, and a
            second one centred in this bar would be a duplicate. No `footer` either — the
            shared adh footer carries the contact address on every route. */}
        <NavChrome navLabel="Sections" links={rows} />
        {lead}
        <Hero
          /* A bare `<img>`, deliberately. `next/image` is out of reach on two counts: the
             landing package takes the mark as a ReactNode precisely so it never depends on
             Next, and the glyph is a static SVG, which next/image passes through
             unoptimised anyway (it refuses to rasterise SVG without `dangerouslyAllowSVG`).
             The path is the same in every site because every site's `public/glyph.svg` is
             its own — one literal here, one file there. */
          mark={<img src="/glyph.svg" alt="" />}
          headline={content.hero.headline}
          tagline={content.hero.tagline}
        >
          {content.hero.blocks.map((block, i) => renderBlock(block, i))}
        </Hero>
        {content.sections.map((section, i) => renderSection(section, i))}
      </Deck>
    </>
  )
}

export interface LandingDeckProps {
  content: LandingContent
}

/**
 * A family site's `/` — the deck and nothing else.
 *
 * Every site in the family mounts this from the same `app/page.tsx`, byte for byte, and
 * hands it the content generated from its own markdown. Which is what makes the deck's
 * shape a single file: it used to be emitted per site, so a change to the structure meant
 * regenerating and re-reviewing thirty-eight copies of it.
 */
export function LandingDeck({ content }: LandingDeckProps): ReactElement {
  return deck(content, null, undefined)
}

/**
 * A family site's `/tour` — the SAME deck, opened by the tour strip.
 *
 * The strip is the first screen, ahead of the hero. Everything that says the reader is on a
 * tour — the step counter, the promise, the way on to the next site — has to be on the
 * screen they land on, and every screen in this deck is a full viewport with
 * `scroll-snap-align: start`. Below the hero it was one whole flick down, so `/tour` opened
 * on a screen identical to `/`. A tour stop announces itself or it is not a tour stop.
 */
export function LandingTour({ content }: LandingDeckProps): ReactElement {
  const { tour } = content
  // Every site's OWN landing deck carries a `{tour}` section — the generator's validator
  // refuses one that doesn't — so this is reachable only if `/tour` were ever mounted over
  // a details deck, which has no tour and no `/tour` route of its own. Render the plain
  // deck rather than crash: a missing strip is a routing mistake to notice on the page, not
  // a `tour.eyebrow` thrown from inside it.
  if (tour === undefined) return deck(content, null, undefined)
  const lead = (
    <TourStrip
      eyebrow={tour.eyebrow}
      promise={tour.promise}
      position={tour.position}
      pillars={tour.pillars}
      back={tourStep(tour.back)}
      next={tourStep(tour.next)}
    />
  )
  // The strip is a `<Screen id="tour">` like any other and the first on the page, so it
  // takes the first row of the index. The row exists at all because a reader who has
  // scrolled into the deck needs a way back to the controls that carry them on to the next
  // site, and the menu is the only thing on the page that offers one.
  return deck(content, lead, { href: `#${TOUR_SCREEN_ID}`, label: tour.eyebrow })
}
