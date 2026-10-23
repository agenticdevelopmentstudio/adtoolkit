// The family's landing deck: the SHAPE of every site's `/` and `/tour`, mounted by an
// `app/page.tsx` and `app/tour/page.tsx` that are the same bytes in all thirty-eight sites.
// A site supplies only its own words, as the `LandingContent` it generates from its markdown.
//
// Its own entry rather than a member of `marketing/index`: the marketing barrel is what a
// site's layout imports on EVERY route, and the deck — twenty-odd landing blocks plus the
// index drawer — belongs to two of them.
export { LandingDeck, LandingTour } from './LandingDeck'
export type { LandingDeckProps } from './LandingDeck'
// The same content as a continuous scroll of bands instead of a snap deck — the layout
// `@agenticdevelopertoolkit/landing`'s `Flow` draws. A site picks one per route.
export { LandingFlow, LandingFlowTour } from './LandingFlow'
export type { LandingFlowProps } from './LandingFlow'
export { landingFromData } from './fromData'
export type { InlineNode, LandingDataOptions } from './fromData'
export type {
  LandingContent,
  LandingHero,
  LandingSection,
  LandingBlock,
  LandingCard,
  LandingFaqEntry,
  LandingButton,
  LandingTourStop,
  LandingTourEdge,
} from './content'
