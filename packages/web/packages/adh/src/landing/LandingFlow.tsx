import type { ReactElement, ReactNode } from 'react'
import {
  Band,
  DeckScript,
  Flow,
  FlowHero,
  Head,
  heroSlots,
  indexRows,
  joinMeta,
  renderBlock,
  TourStrip,
} from '@agenticdevelopertoolkit/landing'
import type { BandTone, LandingSection, NavLink } from '@agenticdevelopertoolkit/landing'
// Both client components by PACKAGE PATH and from `/client`, for the reason LandingDeck.tsx
// gives in full: a bundled client module hoists its `'use client'` over this whole module and
// turns every band of a site's landing copy into a Client Component.
import { NavChrome, Reveal } from '@agenticdevelopertoolkit/landing/client'
import { TOUR_SCREEN_ID, tourStep } from './tour'
import type { LandingContent } from './tour'

/**
 * The tones a run of bands alternates through, first band first.
 *
 * `soft` first so the band directly under the hero is a visible step off its wash — the
 * same order agenticdeveloperstenographer.com's page runs, which is the page this layout
 * was asked to match. No `paper`: the package calls the light band a punctuation mark that
 * a page carries at most once, and which section earns it is an editorial call that
 * generated content has no field to make.
 */
const TONES: readonly BandTone[] = ['soft', 'dark']

/** One band: the section's `Head` — eyebrow rule and all — then its blocks, revealed as
 *  they scroll in. The reveal sits INSIDE the band for the reason the landing package's
 *  `Band` gives: around it, the transformed wrapper breaks the seam's stacking. */
function renderBand(section: LandingSection, key: number): ReactElement {
  return (
    <Band key={key} id={section.id} tone={TONES[key % TONES.length]}>
      <Reveal>
        {/* Same `headingInBlock` rule as the deck's screens: a block that carries the
            section's heading gets no `Head`, because two eyebrows read as two sections. */}
        {section.headingInBlock === true ? null : (
          <Head eyebrow={section.eyebrow} title={section.title} />
        )}
        {section.blocks.map((block, i) => renderBlock(block, i))}
      </Reveal>
    </Band>
  )
}

/**
 * The flow page itself — the deck's content as a continuous scroll of bands.
 *
 * Same content, same index, same block renderer as `deck()`; what changes is only the frame.
 * A band is as tall as its content and nothing snaps, so a section longer than the viewport
 * is simply read, where the deck either reserved a whole screen for a three-line section or
 * snapped the reader past the middle of a long one.
 *
 * `DeckScript` is still rendered, with snapping and the open-at-top reset switched off: what
 * is left is the eased in-page jump (`html[data-smooth]` in base.css does nothing without
 * it) and the iOS zoom fix, both of which a flow page wants as much as a deck does. Restoring
 * the reader's scroll position is the right default once nothing snaps — the reset existed
 * because a restored offset landed between two snap points.
 */
function flow(
  content: LandingContent,
  lead: ReactNode,
  leadRow: NavLink | undefined,
  heroFillsWindow: boolean,
): ReactElement {
  const rows = leadRow === undefined ? indexRows(content) : [leadRow, ...indexRows(content)]
  // The landing kit's `heroSlots` sorts the hero's rows into FlowHero's slots and refuses
  // any it has no slot for. A status pill it can sort, but FlowHero has nowhere to draw one,
  // so it is refused here rather than dropped: a hero row that vanishes from the page is a
  // content loss nobody would see in a diff.
  const { actions, meta, status } = heroSlots(content.hero)
  if (status !== undefined) {
    throw new Error(
      `LandingFlow: a 'StatusPill' block has no slot in the flow hero — ` +
        `only 'Cta' and 'Trust' do. Move it into a section, or render this page as a LandingDeck.`,
    )
  }
  return (
    <>
      <DeckScript armSnapping={false} openAtTop={false} />
      <Flow>
        <NavChrome navLabel="Sections" links={rows} />
        {lead}
        <FlowHero
          /* A bare `<img>` of the site's own `public/glyph.svg`, for the reasons LandingDeck's
             `Hero` gives. */
          mark={<img src="/glyph.svg" alt="" />}
          headline={content.hero.headline}
          sub={content.hero.tagline}
          meta={meta.length === 0 ? undefined : joinMeta(meta)}
          fill={heroFillsWindow}
        >
          {actions.length === 0 ? undefined : actions}
        </FlowHero>
        {content.sections.map((section, i) => renderBand(section, i))}
      </Flow>
    </>
  )
}

export interface LandingFlowProps {
  content: LandingContent
  /**
   * The hero takes the whole window under the header and the bands start below the fold:
   * the page in two parts, the callout and then everything else (`FlowHero`'s `fill`). The
   * hub's `/` asks for it (Mike, 2026-10-25); a site that does not keeps the short hero.
   */
  heroFillsWindow?: boolean
}

/** A family site's `/` as a flow page. The same `LandingContent` `LandingDeck` mounts. */
export function LandingFlow({ content, heroFillsWindow = false }: LandingFlowProps): ReactElement {
  return flow(content, null, undefined, heroFillsWindow)
}

/**
 * `/tour` as a flow page: the tour strip ahead of the hero, as `LandingTour` puts it, and
 * for the same reason — a tour stop has to announce itself on the screen the reader lands on.
 */
export function LandingFlowTour({ content, heroFillsWindow = false }: LandingFlowProps): ReactElement {
  const { tour } = content
  if (tour === undefined) return flow(content, null, undefined, heroFillsWindow)
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
  return flow(content, lead, { href: `#${TOUR_SCREEN_ID}`, label: tour.eyebrow }, heroFillsWindow)
}
