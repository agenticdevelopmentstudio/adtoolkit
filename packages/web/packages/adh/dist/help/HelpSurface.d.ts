import { type HelpTopicId } from './topics';
import { type HelpRouteLevel } from '@agentic-toolkit/adh/help/HelpMasterDetail';
/** Join a site `basePath` (no trailing slash; `''` or `/` = apex) with a base-relative slug. */
export declare function helpHref(basePath: string, slug: string): string;
/** The stable key of the root level — the help topics — in every stack that starts with it. */
export declare const HELP_ROOT_LEVEL_KEY = "help-root";
/**
 * Level 0 of every help stack: the help topics, with `selectedId` chosen. {@link HelpSurface}
 * builds it for the markdown routes; a site's route-driven surface (the REST API reference, the
 * Hub Features document) builds the SAME level through this so its outer rail — topics, labels,
 * hrefs, glyphs, nudge copy, where clearing goes — is identical to every other help route. The
 * three used to each spell their own copy and drifted: the REST API's cleared to the apex while
 * the others cleared to `/home`.
 */
export declare function helpRootLevel(selectedId: HelpTopicId | null, clearHref: string, basePath?: string): HelpRouteLevel;
/**
 * The server-rendered help master-detail for one route. `slug` is the active base-relative slug
 * (e.g. `overview`, `mcp/connect`); `basePath` is where the surface is mounted (`''` on the help
 * site).
 */
export declare function HelpSurface({ slug, basePath, rootClearHref, }: {
    slug: string;
    basePath?: string;
    /** Where clearing the ROOT level's selection navigates — the HMDV's own home. Defaults to the
     *  surface apex; a host whose apex is NOT the surface (the help site's `/` is a landing page,
     *  its HMDV root lives at `/home`) passes that route so unselecting everything stays on the
     *  surface instead of bouncing to the landing. */
    rootClearHref?: string;
}): import("react").JSX.Element;
//# sourceMappingURL=HelpSurface.d.ts.map