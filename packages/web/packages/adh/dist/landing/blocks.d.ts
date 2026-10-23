import type { ReactElement, ReactNode } from 'react';
import type { NavLink, TourStep } from '@agenticdevelopertoolkit/landing';
import type { LandingBlock, LandingContent, LandingTourEdge } from './content';
/**
 * The id `TourStrip` renders from a literal of its own (landing/src/blocks/TourStrip.tsx).
 * Named here because the tour's index row has to link to it, and because the generator
 * refuses a section that slugs to the same string — two `id="tour"` elements in one
 * document make `#tour` resolve to whichever comes first, and the deck's own scroll target
 * is the loser.
 */
export declare const TOUR_SCREEN_ID = "tour";
/** A block BODY — a Card's, a Closer's, a Faq answer's — as `<p>` elements.
 *
 *  The kit styles a body through its paragraph child: `.lp-card p` sets the colour, weight,
 *  size and line-height, `.lp-closer p` the margins and its 48ch measure, `.lp-faq details p`
 *  the padding that separates an answer from the summary it opens under. A body rendered as
 *  a bare text child inherits the page's defaults instead — valid JSX, the right words, and
 *  only the pixels wrong. */
export declare function prose(paragraphs: ReactNode[]): ReactElement[];
/** One block, in the position its section puts it. */
export declare function renderBlock(block: LandingBlock, key: number): ReactElement;
/** `(href, label)` for every screen the deck's own sections render.
 *
 *  The hero is deliberately absent: it is the top of the page, which the browser's own Home
 *  key already reaches, and a first row meaning "go back to where you started" is the one
 *  row of a table of contents that carries no information. */
export declare function indexRows(content: LandingContent): NavLink[];
/** A tour edge as the strip's own `TourStep`.
 *
 *  The href is resolved here rather than carried in the content: a tour edge crosses
 *  origins, and only the registry knows a site's production host. Spelling it with
 *  `siteProdUrl` keeps that one table the source of hosts instead of baking a hostname into
 *  thirty-eight generated files that no longer track it. */
export declare function tourStep(edge: LandingTourEdge | undefined): TourStep | undefined;
//# sourceMappingURL=blocks.d.ts.map