import type { ReactElement } from 'react';
import type { LandingContent } from './tour';
export interface LandingFlowProps {
    content: LandingContent;
    /**
     * The hero takes the whole window under the header and the bands start below the fold:
     * the page in two parts, the callout and then everything else (`FlowHero`'s `fill`). The
     * hub's `/` asks for it (Mike, 2026-10-25); a site that does not keeps the short hero.
     */
    heroFillsWindow?: boolean;
}
/** A family site's `/` as a flow page. The same `LandingContent` `LandingDeck` mounts. */
export declare function LandingFlow({ content, heroFillsWindow }: LandingFlowProps): ReactElement;
/**
 * `/tour` as a flow page: the tour strip ahead of the hero, as `LandingTour` puts it, and
 * for the same reason — a tour stop has to announce itself on the screen the reader lands on.
 */
export declare function LandingFlowTour({ content, heroFillsWindow }: LandingFlowProps): ReactElement;
//# sourceMappingURL=LandingFlow.d.ts.map