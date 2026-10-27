import type { ReactNode } from 'react'
import { Btn } from '../blocks/Btn'
import { StatusPill } from '../blocks/StatusPill'
import { Bleed } from '../flow/Bleed'
import { renderBlock } from './blocks'
import type { LandingBlock, LandingHero } from './types'

export interface HeroSlots {
  actions: ReactNode[]
  meta: ReactNode[]
  /** The hero's status pill, rendered. Absent when the hero has none. */
  status?: ReactNode
  /** The hero's screenshot, rendered and bled to the right — `FlowHero`'s `shot`. Absent when
   *  the hero has none. */
  shot?: ReactNode
}

/**
 * The hero's rows, sorted into the slots a flow hero has.
 *
 * The deck's `Hero` takes arbitrary blocks under its tagline; `FlowHero` takes a row of bare
 * `Btn`s, one meta line and nothing else. So a `Cta` gives up its buttons — NOT the `Cta`
 * itself, whose own gap would silently override the hero's (FlowHero's `children` doc) — a
 * `Trust` strip becomes the meta items, a `StatusPill` becomes the `status`, and a `Shot` becomes
 * the `shot` — rendered exactly as a section renders one (`pendingLabel` is `renderBlock`'s),
 * then bled as FlowHero's doc asks.
 *
 * Beside a status every button renders `ghost`, whatever variant it declares: the pill is
 * the hero's one accented thing, and a filled button next to it is a second.
 *
 * Any other kind is refused rather than dropped: a hero row that vanishes from the page is a
 * content loss nobody would see in a diff.
 */
export function heroSlots(hero: LandingHero, pendingLabel?: ReactNode): HeroSlots {
  const buttons: { href: string; label: ReactNode; variant?: 'primary' | 'ghost' }[] = []
  const meta: ReactNode[] = []
  let status: ReactNode | undefined
  let shot: ReactNode | undefined
  hero.blocks.forEach((block: LandingBlock) => {
    switch (block.kind) {
      case 'Cta':
        buttons.push(...block.buttons)
        return
      case 'Trust':
        meta.push(...block.items)
        return
      case 'StatusPill':
        status = <StatusPill free={block.free}>{block.children}</StatusPill>
        return
      case 'Shot':
        // FlowHero has room for one; a second would replace the first unseen.
        if (shot !== undefined) {
          throw new Error(`heroSlots: the hero has room for one 'Shot' — move the other into a section.`)
        }
        shot = <Bleed>{renderBlock(block, 0, pendingLabel)}</Bleed>
        return
      default:
        throw new Error(
          `heroSlots: a '${block.kind}' block has no slot in the hero — ` +
            `only 'Cta', 'Trust', 'StatusPill' and 'Shot' do. Move it into a section, or render this page as a deck.`,
        )
    }
  })
  // Rendered after the walk, not during it, because a status anywhere in the hero — even
  // after the buttons — turns every button ghost.
  const actions = buttons.map((button, i) => (
    <Btn key={i} href={button.href} variant={status === undefined ? button.variant : 'ghost'}>
      {button.label}
    </Btn>
  ))
  return {
    actions,
    meta,
    ...(status === undefined ? {} : { status }),
    ...(shot === undefined ? {} : { shot }),
  }
}

/** `a · b · c`, as one line of nodes. */
export function joinMeta(items: ReactNode[]): ReactNode {
  return items.map((item, i) => (
    <span key={i}>
      {i > 0 ? ' · ' : null}
      {item}
    </span>
  ))
}
