import { Fragment } from 'react'
import type { ReactElement, ReactNode } from 'react'
import {
  DeckScript,
  Flow,
  FlowHero,
  Head,
  heroSlots,
  joinMeta,
  renderBlock,
} from '@agenticdevelopertoolkit/landing'
import type { BandTone, LandingPage, LandingSection } from '@agenticdevelopertoolkit/landing'
import { FrameBand } from './frame-band'
import type { BandLook, SlotMap } from './types'

/**
 * The tones the bands alternate through, first band first. `soft` first so the band under
 * the hero is a visible step off its wash; no `paper`, which the kit calls a punctuation mark
 * a page carries at most once — an editorial call, which a site opts into per band through
 * `site.json` `bands`. The same order adh's `LandingFlow` runs.
 */
const TONES: readonly BandTone[] = ['soft', 'dark']

/**
 * A band's `Head`. A section with a title shows its eyebrow and its title, the title the
 * band's `<h2>`. A section with none shows the eyebrow alone, and the eyebrow is then the
 * band's heading too: shown once, hidden from a screen reader, and spoken once by an `<h2>`
 * hidden from sight, so the band is still a heading a reader can jump to.
 */
function bandHead(section: LandingSection): ReactElement {
  if (section.title !== undefined) return <Head eyebrow={section.eyebrow} title={section.title} />
  return (
    <Head eyebrow={<span aria-hidden="true">{section.eyebrow}</span>}>
      <h2 className="st-sr-only">{section.eyebrow}</h2>
    </Head>
  )
}

/** One band: the section's `Head`, then its blocks — or the site's slot in their place. */
function renderBand(
  section: LandingSection,
  index: number,
  Slot: SlotMap['bands'][string] | undefined,
  look: BandLook,
  pendingLabel: ReactNode,
): ReactElement {
  return (
    <FrameBand key={section.id} id={section.id} tone={look.tone ?? TONES[index % TONES.length]} seam={look.seam}>
      {/* A block that carries the section's heading gets no `Head`, because two eyebrows
          read as two sections. A slot replaces the blocks only, so it keeps the Head. */}
      {section.headingInBlock === true ? null : bandHead(section)}
      {Slot === undefined ? section.blocks.map((block, i) => renderBlock(block, i, pendingLabel)) : <Slot />}
    </FrameBand>
  )
}

/** The hero from the page's own data: `heroSlots` sorts its rows into FlowHero's slots. */
function dataHero(page: LandingPage, mark: ReactNode, pendingLabel: ReactNode): ReactElement {
  const { actions, meta, status, shot } = heroSlots(page.hero, pendingLabel)
  // FlowHero has no status slot, and a StatusPill is a `<p>`, which neither the sub nor the
  // meta line (both `<p>`s) can legally hold. The actions row is a `<div>`, and it is where
  // the pill belongs anyway: `heroSlots` turns every button ghost beside it, which only reads
  // as intended when the two sit in one row.
  const row = status === undefined ? actions : [<Fragment key="status">{status}</Fragment>, ...actions]
  return (
    <FlowHero
      id="top"
      fill
      mark={mark}
      headline={page.hero.headline}
      sub={page.hero.tagline}
      meta={meta.length === 0 ? undefined : <span className="st-hero-meta">{joinMeta(meta)}</span>}
      shot={shot}
    >
      {row.length === 0 ? undefined : row}
    </FlowHero>
  )
}

/**
 * A content site's `/`: the hero, a window tall, then one band per section.
 *
 * The page's STRUCTURE is this function and a site's only say in it is its slots: `hero`
 * replaces the hero's contents inside the same `#top` frame, `afterHero` sits between the
 * hero and the first band, and `bands[id]` replaces one band's blocks. `looks[id]` takes one
 * band out of the soft/dark alternation, and `pendingLabel` is the site's word for a
 * screenshot not yet taken, on every pending shot (the kit's own word when absent). The bar, the drawer,
 * the footer and bitbag are the frame's siblings, not its children — `<main>` is the flow
 * parent of the bands, and the kit's last-band dock clearance holds only while its last child
 * is a band — so the site's layout mounts those (`SiteChrome`, `FrameFooter`, `SiteBitbag`).
 *
 * `DeckScript` runs with snapping and the open-at-top reset off, as in adh's `LandingFlow`:
 * what is left is the eased in-page jump the drawer's rows use and the iOS zoom fix.
 */
export function LandingFrame({
  page,
  slots,
  mark,
  looks = {},
  pendingLabel,
}: {
  page: LandingPage
  slots: SlotMap
  mark: ReactNode
  looks?: Record<string, BandLook>
  pendingLabel?: ReactNode
}): ReactElement {
  // Refused, not ignored: a slot or a look whose section was renamed in the markdown would
  // otherwise vanish from the page with nothing in the build to say so.
  const ids = new Set(page.sections.map((section) => section.id))
  const named: [string, string[]][] = [
    ['slots.bands', Object.keys(slots.bands)],
    ['looks', Object.keys(looks)],
  ]
  for (const [where, keys] of named) {
    for (const key of keys) {
      if (!ids.has(key)) {
        throw new Error(
          `LandingFrame: ${where} names no section '${key}'. ` +
            `The page's sections are: ${[...ids].map((id) => `'${id}'`).join(', ') || '(none)'}.`,
        )
      }
    }
  }
  // A `{slot}` section has no blocks of its own, so without its slot it would be a band
  // holding only its eyebrow — the empty screen content-buildr refuses to write.
  for (const section of page.sections) {
    if (section.slot === true && slots.bands[section.id] === undefined) {
      throw new Error(
        `LandingFrame: section '${section.id}' is a {slot} band and slots.bands has no '${section.id}'.`,
      )
    }
  }
  const HeroSlot = slots.hero
  const AfterHero = slots.afterHero
  return (
    <>
      {/* The zoom restore is the root layout's FrameZoomGuard, which every route renders. */}
      <DeckScript armSnapping={false} openAtTop={false} restoreZoomOffIos={false} />
      <Flow>
        {HeroSlot === undefined ? (
          dataHero(page, mark, pendingLabel)
        ) : (
          // FlowHero's own frame, so a custom hero is exactly as tall, and as reachable by
          // `/#top`, as the data one. A `<div>` for FlowHero's reason: the bands are the
          // page's landmarks, and a hero that is one too is an unlabelled region.
          <div id="top" className="lp-hero-flow lp-hero-flow--fill">
            <HeroSlot />
          </div>
        )}
        {AfterHero === undefined ? null : <AfterHero />}
        {page.sections.map((section, i) =>
          renderBand(section, i, slots.bands[section.id], looks[section.id] ?? {}, pendingLabel),
        )}
      </Flow>
    </>
  )
}
