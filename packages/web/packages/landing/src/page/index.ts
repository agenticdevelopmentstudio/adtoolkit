// The page content model: a landing page as data, and the functions every layout uses to
// render it. Server-safe — nothing here carries `'use client'`, so the main barrel can
// re-export it whole.
export type {
  LandingPage,
  LandingHero,
  LandingSection,
  LandingBlock,
  LandingCard,
  LandingFaqEntry,
  LandingButton,
} from './types'
export { landingFromData } from './fromData'
export type { InlineNode, LandingDataOptions } from './fromData'
export { prose, renderBlock, indexRows } from './blocks'
export { heroSlots, joinMeta } from './hero'
export type { HeroSlots } from './hero'
