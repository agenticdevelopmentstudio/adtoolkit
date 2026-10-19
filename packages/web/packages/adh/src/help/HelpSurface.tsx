// NO "use client" — a server component. It resolves the active route to a topic, server-renders the
// leaf (pre-rendered markdown HTML, or a section empty state), and hands the level structure + leaf
// to the client {@link HelpMasterDetail} for the interactive rail.
// The content is therefore in the SSR HTML (crawlable, no client fetch); only the rail hydrates.

import type { ReactNode } from 'react'
import { EmptyState } from '@agenticdevelopertoolkit/ui/components/empty-state'
import { MarkdownHtml } from '../docs/MarkdownHtml'
import { getDocHtmlByKey } from '../docs/content'
import {
  buildTopicLevels,
  findTopicPath,
  topicPathForSlug,
  type HelpTopic,
  type HelpTopicId,
} from './topics'
// Package path (not './HelpMasterDetail') so the 'use client' rail stays its OWN preserved chunk and
// its directive can't be hoisted over this server module — the same isolation trick as this
// package's themes/DbThemeApplier, which keeps server.ts a plain server module (see
// tsup.config.ts `external`).
import { HelpMasterDetail, type HelpRouteLevel } from '@agentic-toolkit/adh/help/HelpMasterDetail'

/** Join a site `basePath` (no trailing slash; `''` or `/` = apex) with a base-relative slug. */
export function helpHref(basePath: string, slug: string): string {
  const base = basePath === '/' ? '' : basePath
  return slug === '' ? base || '/' : `${base}/${slug}`
}

/** The stable key of the root level — the help topics — in every stack that starts with it. */
export const HELP_ROOT_LEVEL_KEY = 'help-root'

/**
 * Level 0 of every help stack: the help topics, with `selectedId` chosen. {@link HelpSurface}
 * builds it for the markdown routes; a site's route-driven surface (the REST API reference, the
 * Hub Features document) builds the SAME level through this so its outer rail — topics, labels,
 * hrefs, glyphs, nudge copy, where clearing goes — is identical to every other help route. The
 * three used to each spell their own copy and drifted: the REST API's cleared to the apex while
 * the others cleared to `/home`.
 */
export function helpRootLevel(
  selectedId: HelpTopicId | null,
  clearHref: string,
  basePath = '',
): HelpRouteLevel {
  const { levels } = buildTopicLevels(selectedId ? [selectedId] : [])
  const root = levels[0]!
  return {
    key: HELP_ROOT_LEVEL_KEY,
    title: root.title,
    items: root.items.map((it) => ({
      id: it.id,
      label: it.label,
      description: it.description,
      href: helpHref(basePath, it.slug),
    })),
    selectedId,
    clearHref,
  }
}

/** The detail pane for the active topic: its pre-rendered markdown, or — for a pure branch (children
 *  but no content of its own) — the SAME label/description empty state the modal's `topicView`
 *  renders, so the standalone site and the Help modal match for every node. (A topic with a `view`
 *  owns its own route on the site — `/rest-api`, `/hub` — and never reaches this renderer.) */
function renderLeaf(topic: HelpTopic | null): ReactNode {
  if (!topic) {
    return <EmptyState className="m-4" title="Help" description="Choose a topic to get started." />
  }
  // A pure branch (a section that opens children but carries no content of its own) shows the same
  // empty state the modal renders — NOT a misleading "no content" dead-end — so the two surfaces
  // stay in lockstep on a crawlable, sitemap-listed route.
  if (!topic.contentKey) {
    return (
      <EmptyState
        className="m-4"
        title={topic.label}
        description={topic.description ?? 'Choose a subtopic.'}
      />
    )
  }
  const html = getDocHtmlByKey(topic.contentKey)
  return (
    <div className="adh-help-topic adh-help-topic--markdown">
      {html == null ? (
        <p className="adh-help-topic__missing">This topic has no content yet.</p>
      ) : (
        <MarkdownHtml html={html} />
      )}
    </div>
  )
}

/**
 * The server-rendered help master-detail for one route. `slug` is the active base-relative slug
 * (e.g. `overview`, `mcp/connect`); `basePath` is where the surface is mounted (`''` on the help
 * site).
 */
export function HelpSurface({
  slug,
  basePath = '',
  rootClearHref,
}: {
  slug: string
  basePath?: string
  /** Where clearing the ROOT level's selection navigates — the HMDV's own home. Defaults to the
   *  surface apex; a host whose apex is NOT the surface (the help site's `/` is a landing page,
   *  its HMDV root lives at `/home`) passes that route so unselecting everything stays on the
   *  surface instead of bouncing to the landing. */
  rootClearHref?: string
}) {
  const path = topicPathForSlug(slug) ?? []
  const { levels, activeTopic } = buildTopicLevels(path)
  const pathTopics = activeTopic ? findTopicPath(activeTopic.id) ?? [] : []

  // Level 0 clears to the surface's home (`rootClearHref`, defaulting to the apex); a nested
  // level clears up to its parent section's route (the topic one step up the active path).
  const routeLevels: HelpRouteLevel[] = levels.map((level, depth) =>
    depth === 0
      ? helpRootLevel(level.selectedId, rootClearHref ?? helpHref(basePath, ''), basePath)
      : {
          key: `help:${level.parentId}`,
          title: level.title,
          items: level.items.map((it) => ({
            id: it.id,
            label: it.label,
            description: it.description,
            href: helpHref(basePath, it.slug),
          })),
          selectedId: level.selectedId,
          clearHref: helpHref(basePath, pathTopics[depth - 1]?.slug ?? ''),
        },
  )

  return (
    <HelpMasterDetail levels={routeLevels} rootLabel="Help">
      {renderLeaf(activeTopic)}
    </HelpMasterDetail>
  )
}
