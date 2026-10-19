import { type ReactNode } from 'react';
/** One row of a {@link HelpRouteLevel}, already mapped to its route by the server. */
export interface HelpRouteItem {
    id: string;
    label: string;
    description?: string;
    href: string;
    /** The row's glyph. Defaults to {@link topicIcon} of the id, which is right for every level whose
     *  ids are help topic ids (the roots, the markdown sections); a route-driven level whose ids are
     *  its own (an OpenAPI tag, a Hub Features entry) passes its own glyph. */
    icon?: ReactNode;
    /** A rule after this row, optionally captioned — the Hub Features document's group headings
     *  ("Features", "Under the hood") sit on the row before each group. */
    dividerAfter?: boolean;
    dividerLabel?: string;
    /** Routes to warm when the row is hovered, besides `href` itself. */
    prefetch?: string[];
}
/** One hierarchical level, already resolved to route hrefs by the server ({@link HelpSurface}, or
 *  a site's own route-driven surface — the REST API's areas and endpoints, the Hub Features
 *  document's lists). The client only wires the hrefs to the router — it computes no routing
 *  itself. */
export interface HelpRouteLevel {
    /** Stable {@link TopicLevel} id / react key. */
    key: string;
    title: string;
    items: HelpRouteItem[];
    selectedId: string | null;
    /** The row the rail treats as chosen when `selectedId` is null — the Hub Features document's
     *  Overview row, so a list with a page of its own opens on that page rather than on the nudge.
     *  Wide layouts only; see {@link TopicLevel.defaultSelectedId}. */
    defaultSelectedId?: string;
    /** Where re-clicking the selected row / navigating "up" from this level goes. */
    clearHref: string;
    leadsTo?: 'list' | 'detail';
    /** Singular noun for one row, so the nudge reads "Select an endpoint" rather than naming the
     *  list. Defaults to `topic`. */
    itemNoun?: string;
    /** The nudge's bespoke body: what these rows are and why to pick one. Defaults to the help
     *  site's topic blurb. */
    overviewHelp?: ReactNode;
    width?: number;
}
/**
 * The client half of every route-driven help surface: renders the shared HMDV
 * ({@link HierarchicalDetailView}) over server-computed {@link HelpRouteLevel}s, translating each
 * row selection into a real route navigation and each hover into a prefetch. The detail pane
 * (`children`) is the leaf the server already rendered for the active route, so the initial paint
 * is fully server-side; this component only adds the interactive rail. It is the same HMDV the
 * Help modal uses, so the standalone site and the modal look and behave identically.
 *
 * `toolbar` is the button bar above the breadcrumb (the REST API's Download OpenAPI JSON button),
 * `detailTitle` the strip's own title for the open leaf (the Hub Features document's selected
 * entry), and `ssrDetail` asks the stack to put the leaf in the server HTML too, for a surface
 * whose detail should be crawlable.
 */
export declare function HelpMasterDetail({ levels, rootLabel, toolbar, detailTitle, ssrDetail, children, }: {
    levels: HelpRouteLevel[];
    rootLabel: string;
    toolbar?: ReactNode;
    detailTitle?: ReactNode;
    ssrDetail?: boolean;
    children: ReactNode;
}): import("react").JSX.Element;
//# sourceMappingURL=HelpMasterDetail.d.ts.map