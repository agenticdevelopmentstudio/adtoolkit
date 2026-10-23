import type { ReactElement } from 'react';
import type { LandingContent } from './content';
export interface LandingFlowProps {
    content: LandingContent;
}
/** A family site's `/` as a flow page. The same `LandingContent` `LandingDeck` mounts. */
export declare function LandingFlow({ content }: LandingFlowProps): ReactElement;
/**
 * `/tour` as a flow page: the tour strip ahead of the hero, as `LandingTour` puts it, and
 * for the same reason — a tour stop has to announce itself on the screen the reader lands on.
 */
export declare function LandingFlowTour({ content }: LandingFlowProps): ReactElement;
//# sourceMappingURL=LandingFlow.d.ts.map