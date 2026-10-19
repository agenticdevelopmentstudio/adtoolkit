'use client'

import { useMemo, type ReactNode } from 'react'
import { useRouter } from 'next/navigation'
import type { TopicLevel, TopicSelectOptions } from '@agenticdevelopertoolkit/ui/blocks'
import { HierarchicalDetailView } from '@agenticdevelopertoolkit/ui/blocks'
import { topicIcon } from './topic-icons'

/** One row of a {@link HelpRouteLevel}, already mapped to its route by the server. */
export interface HelpRouteItem {
  id: string
  label: string
  description?: string
  href: string
  /** The row's glyph. Defaults to {@link topicIcon} of the id, which is right for every level whose
   *  ids are help topic ids (the roots, the markdown sections); a route-driven level whose ids are
   *  its own (an OpenAPI tag, a Hub Features entry) passes its own glyph. */
  icon?: ReactNode
  /** A rule after this row, optionally captioned — the Hub Features document's group headings
   *  ("Features", "Under the hood") sit on the row before each group. */
  dividerAfter?: boolean
  dividerLabel?: string
  /** Routes to warm when the row is hovered, besides `href` itself. */
  prefetch?: string[]
}

/** One hierarchical level, already resolved to route hrefs by the server ({@link HelpSurface}, or
 *  a site's own route-driven surface — the REST API's areas and endpoints, the Hub Features
 *  document's lists). The client only wires the hrefs to the router — it computes no routing
 *  itself. */
export interface HelpRouteLevel {
  /** Stable {@link TopicLevel} id / react key. */
  key: string
  title: string
  items: HelpRouteItem[]
  selectedId: string | null
  /** The row the rail treats as chosen when `selectedId` is null — the Hub Features document's
   *  Overview row, so a list with a page of its own opens on that page rather than on the nudge.
   *  Wide layouts only; see {@link TopicLevel.defaultSelectedId}. */
  defaultSelectedId?: string
  /** Where re-clicking the selected row / navigating "up" from this level goes. */
  clearHref: string
  leadsTo?: 'list' | 'detail'
  /** Singular noun for one row, so the nudge reads "Select an endpoint" rather than naming the
   *  list. Defaults to `topic`. */
  itemNoun?: string
  /** The nudge's bespoke body: what these rows are and why to pick one. Defaults to the help
   *  site's topic blurb. */
  overviewHelp?: ReactNode
  width?: number
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
export function HelpMasterDetail({
  levels,
  rootLabel,
  toolbar,
  detailTitle,
  ssrDetail,
  children,
}: {
  levels: HelpRouteLevel[]
  rootLabel: string
  toolbar?: ReactNode
  detailTitle?: ReactNode
  ssrDetail?: boolean
  children: ReactNode
}) {
  const router = useRouter()
  const topicLevels = useMemo<TopicLevel[]>(
    () =>
      levels.map((l) => {
        const byId = new Map(l.items.map((it) => [it.id, it]))
        // A `replace` navigation is one the stack asked for on the visitor's behalf — a
        // `defaultSelectedId` landing on the bare parent route they never asked for — so it must
        // not cost a Back press. A click pushes.
        const go = (href: string, opts?: TopicSelectOptions) => {
          if (opts?.replace) router.replace(href)
          else router.push(href)
        }
        return {
          id: l.key,
          title: l.title,
          // topicIcon(it.id) gives every row a topic glyph in place of HMDV's neutral fallback ring —
          // on the help levels the item id IS the HelpTopic id, so the same map serves the root and
          // every nested level; a route-driven level brings its own.
          items: l.items.map((it) => ({
            id: it.id,
            label: it.label,
            description: it.description,
            icon: it.icon ?? topicIcon(it.id),
            dividerAfter: it.dividerAfter,
            dividerLabel: it.dividerLabel,
          })),
          selectedId: l.selectedId,
          defaultSelectedId: l.defaultSelectedId,
          // Level default for every row — no per-item override needed (each row shares one leadsTo).
          leadsTo: l.leadsTo,
          width: l.width,
          // Every help level is a topic browser, and its unselected frontier is the platform nudge
          // like everywhere else — a card grid repeating the rows the rail is already showing is the
          // second-surface-beside-the-rail that adh/docs/ui/fleet-ui-audit.md §1.5 forbids. `itemNoun` +
          // `overviewHelp` are what make the nudge read for a docs site: without the blurb the shared
          // headline offers to "view or edit" the topic, which is not what this surface does.
          itemNoun: l.itemNoun ?? 'topic',
          overviewHelp: l.overviewHelp ?? 'Choose a topic from the list to read it here.',
          onSelect: (id: string, opts?: TopicSelectOptions) => {
            const href = byId.get(id)?.href
            if (href) go(href, opts)
          },
          onClear: (opts?: TopicSelectOptions) => go(l.clearHref, opts),
          clearHref: l.clearHref,
          onPrefetch: (id: string) => {
            const it = byId.get(id)
            if (!it) return
            router.prefetch(it.href)
            for (const extra of it.prefetch ?? []) router.prefetch(extra)
          },
        }
      }),
    [levels, router],
  )

  return (
    <HierarchicalDetailView
      levels={topicLevels}
      rootLabel={rootLabel}
      disclosureStyle="cascading"
      autoHideTopics
      exitGuard={null}
      toolbar={toolbar}
      detailTitle={detailTitle}
      ssrDetail={ssrDetail}
    >
      {children}
    </HierarchicalDetailView>
  )
}
