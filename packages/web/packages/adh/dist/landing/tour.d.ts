import type { ReactNode } from 'react';
import type { SiteId } from '@agentic-toolkit/adh-registry';
import type { LandingPage, TourPillar, TourStep } from '@agenticdevelopertoolkit/landing';
/**
 * A family site's landing deck, as DATA: the kit's `LandingPage` plus the tour stop.
 *
 * Every site in the family writes one of these — `src/landing.json`, generated from that
 * site's markdown by `content-buildr update` and loaded by the `src/landing.tsx` beside it through
 * `landingFromData` — and mounts it through `<LandingDeck>` and `<LandingTour>`.
 */
export interface LandingContent extends LandingPage {
    /**
     * The `{tour}` blurb. Required for every site's OWN landing deck: `<LandingTour>`
     * renders `/tour` for every site in the family, and a site with no blurb would render a
     * page identical to `/` — no step counter, no way on to the next site, the walk
     * silently ending there. The generator's own validator refuses a site whose markdown
     * has no `{tour}` section, so absence there is a fact about the content, not a default
     * to fill in here.
     *
     * Absent on a site's own second deck (`/details`), which is a page rather than a stop
     * on the family walk. `<LandingTour>` is the only reader; `<LandingDeck>` never was.
     */
    tour?: LandingTourStop;
}
export interface LandingTourStop {
    eyebrow: string;
    promise: ReactNode;
    position: {
        step: number;
        total: number;
    };
    /**
     * The three-column promise, carried by the masterbrand alone. Which site that is belongs
     * to the manifest the generator reads, not to any one site's markdown — a leaf that
     * repeated the cards would make the whole family's claim on its own page and then make
     * it again on the next site in the walk.
     */
    pillars?: TourPillar[];
    back?: LandingTourEdge;
    next?: LandingTourEdge;
}
export interface LandingTourEdge {
    /**
     * The SITE the edge points at, not a path: a tour edge crosses origins, and only the
     * registry knows a site's production host. `<LandingTour>` spells the href with
     * `siteProdUrl`, so the host table stays the one source of hosts.
     */
    site: SiteId;
    /**
     * The other site's headline, as plain text — it lands on a button, whose label is a
     * `string`, so the markdown is stripped rather than converted.
     */
    label: string;
    note?: string;
}
/**
 * The id `TourStrip` renders from a literal of its own (landing/src/blocks/TourStrip.tsx).
 * Named here because the tour's index row has to link to it, and because the generator
 * refuses a section that slugs to the same string — two `id="tour"` elements in one
 * document make `#tour` resolve to whichever comes first, and the deck's own scroll target
 * is the loser.
 */
export declare const TOUR_SCREEN_ID = "tour";
/** A tour edge as the strip's own `TourStep`.
 *
 *  The href is resolved here rather than carried in the content: a tour edge crosses
 *  origins, and only the registry knows a site's production host. Spelling it with
 *  `siteProdUrl` keeps that one table the source of hosts instead of baking a hostname into
 *  thirty-eight generated files that no longer track it. */
export declare function tourStep(edge: LandingTourEdge | undefined): TourStep | undefined;
//# sourceMappingURL=tour.d.ts.map