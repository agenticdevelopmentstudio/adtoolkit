/**
 * The help topic tree — the single declaration of what the help surface offers and how the topics
 * nest. It is the ONE source of truth for both renderings:
 *
 *   - the SSR **help site** (`help.adh.com`), where each topic's {@link HelpTopic.slug} is a real,
 *     crawlable route and the tree renders as a server-rendered HMDV master-detail, and
 *   - the client **Help modal**, mounted on every site, which renders the identical HMDV over the
 *     same tree with in-place selection instead of routing.
 *
 * {@link buildTopicLevels} turns a selection path into the per-depth {@link HierarchicalDetailView}
 * levels + the active topic; each surface supplies its own navigation (route push vs. state) and
 * its own leaf renderer, so the structure lives here exactly once.
 *
 * Adding a topic is data-only: add a node here (and, for a markdown leaf, a `.md` file under
 * `content/` regenerated into `content.generated.ts`). No wiring changes.
 */

/** A stable topic id. Also the deep-link handle passed to `useHelp().open(id)`. */
export type HelpTopicId = string

export interface HelpTopic {
  id: HelpTopicId
  /** Row label + breadcrumb crumb. */
  label: string
  /** Base-relative route slug (NO leading slash), e.g. `overview`, `mcp/connect`. The help site
   *  generates one SSR route per slug; the slug path mirrors the id path down the tree. */
  slug: string
  /** One/two-sentence blurb. It renders as the `EmptyState` body when this topic is SELECTED and has
   *  no content of its own (`HelpSurface.tsx:47`, `HelpWindow.tsx:26`). It used to also land an
   *  UNSELECTED level as a grid of one card per sibling; that opt-in is gone
   *  (adh/docs/ui/fleet-ui-audit.md §1.5 — an unselected frontier is the select nudge and nothing else),
   *  so a blurb on a topic nobody has picked yet is now carried but not shown. */
  description?: string
  /** Child topics. Presence opens the children as the next hierarchical level when this node is
   *  selected. A node MAY carry both `children` and its own `contentKey` — then it is a *section*
   *  page: its content fills the detail pane while its children show as the next level. (No topic
   *  uses that combination today; the level builder supports it.) */
  children?: HelpTopic[]
  /** For a section (a node with `children`): the child that stands in as its landing. Selecting the
   *  section — arriving on its slug, or clicking its row in either rail — auto-selects that child,
   *  so the section shows real content instead of the children level's select nudge. Opt-in per
   *  section: a section without it keeps the nudge (adh/docs/ui/fleet-ui-audit.md §1.5). Must name a
   *  direct child; `helpTopics.test.ts` fails on an id that isn't one. */
  landingChildId?: HelpTopicId
  /** Key into `HELP_CONTENT_HTML` (content.generated.ts) — the detail pane renders that pre-rendered
   *  markdown. May coexist with `children` (section page); mutually exclusive with `view`. */
  contentKey?: string
  /** A built-in non-markdown detail view. `api` = the REST API reference (a link-out to the
   *  standalone `/rest-api` reference on the site; the interactive browser in the modal). `hub` =
   *  the Hub Features document, which the help site serves from its own content tree under `/hub`
   *  (the modal links out to it). Mutually exclusive with `contentKey`. */
  view?: 'api' | 'hub'
}

export const HELP_TOPICS: HelpTopic[] = [
  {
    id: 'overview',
    label: 'Overview',
    slug: 'overview',
    description: 'What this site holds, and where to start.',
    contentKey: 'overview',
  },
  {
    id: 'rest-api',
    label: 'REST API',
    slug: 'rest-api',
    description: 'Browse every REST endpoint and try calls against your session.',
    view: 'api',
  },
  {
    // A section, not a monolithic page: the old single mcp.md split into per-concern child topics.
    // It does NOT land on the children's select nudge: /mcp is the published address of the MCP
    // docs (the MCP host's root redirects a browser here, as does the `/docs/mcp` redirect), so
    // arriving there must read as documentation, not as a menu. The `landingChildId` auto-selects
    // Overview — the reader lands on prose with the siblings beside it.
    id: 'mcp',
    label: 'MCP',
    slug: 'mcp',
    description: 'Connect an agent to the hub over the Model Context Protocol.',
    landingChildId: 'mcp-overview',
    children: [
      { id: 'mcp-overview', label: 'Overview', slug: 'mcp/overview', description: 'What the MCP server is, and how it relates to the REST API.', contentKey: 'mcp-overview' },
      { id: 'mcp-connect', label: 'Connect a client', slug: 'mcp/connect', description: 'Point Claude Desktop, Claude Code, Cursor, or the Inspector at the server.', contentKey: 'mcp-connect' },
      { id: 'mcp-tools', label: 'Tools', slug: 'mcp/tools', description: 'Every tool the server exposes, grouped by area.', contentKey: 'mcp-tools' },
      { id: 'mcp-details', label: 'Details', slug: 'mcp/details', description: 'Transport, auth, session, and data-scope facts.', contentKey: 'mcp-details' },
    ],
  },
  {
    // The Hub Features document is not markdown in this package: the help site builds it with
    // content-buildr from `content/hub-features/` in adhubwebsite and serves it under `/hub` with
    // its own cascading lists, one per level of the document. So this is a leaf with a `view`, like
    // the REST API: on the site the `/hub` route owns it, and the modal links out to it.
    id: 'hub',
    label: 'Hub Features',
    slug: 'hub',
    description: 'Every feature of the Agentic Developer Hub, described one at a time.',
    view: 'hub',
  },
]

/** True when the node opens no child level (its detail pane is the frontier). */
export function isLeaf(topic: HelpTopic): boolean {
  return !topic.children || topic.children.length === 0
}

/** True when selecting this node fills the detail pane with its own content/view (a leaf, or a
 *  section page that also has children). */
export function hasDetail(topic: HelpTopic): boolean {
  return topic.contentKey != null || topic.view != null
}

/**
 * The path of nodes from a root topic down to `id`, or `null` if `id` isn't in the tree.
 * `useHelp().open(id)` uses this to open the modal already navigated to a nested topic.
 */
export function findTopicPath(id: HelpTopicId, topics: HelpTopic[] = HELP_TOPICS): HelpTopic[] | null {
  for (const topic of topics) {
    if (topic.id === id) return [topic]
    if (topic.children) {
      const deeper = findTopicPath(id, topic.children)
      if (deeper) return [topic, ...deeper]
    }
  }
  return null
}

/** Every topic in the tree, depth-first — the enumerable set the site prerenders and the modal lists. */
export function flattenTopics(topics: HelpTopic[] = HELP_TOPICS): HelpTopic[] {
  return topics.flatMap((t) => [t, ...(t.children ? flattenTopics(t.children) : [])])
}

/** Every base-relative slug in the tree — the SSR routes the help site generates. */
export function helpSlugs(): string[] {
  return flattenTopics().map((t) => t.slug)
}

/** The topic whose {@link HelpTopic.slug} equals `slug`, or `undefined`. */
export function topicBySlug(slug: string): HelpTopic | undefined {
  return flattenTopics().find((t) => t.slug === slug)
}

/**
 * The slug that should carry the canonical URL for `slug`. A section's {@link HelpTopic.landingChildId}
 * renders the identical page as the section itself (the section auto-selects it), so the two routes
 * are one document: the SECTION wins, because it is the published address others link to. Every
 * other slug — and an unknown one — is its own canonical.
 */
export function canonicalSlug(slug: string): string {
  const topic = topicBySlug(slug)
  if (!topic) return slug
  const section = flattenTopics().find(
    (t) => t.landingChildId === topic.id && (t.children ?? []).some((c) => c.id === topic.id),
  )
  return section ? section.slug : slug
}

/** The selection path (topic ids, root → leaf) for a base-relative slug, or `null` if unknown. */
export function topicPathForSlug(slug: string): HelpTopicId[] | null {
  const topic = topicBySlug(slug)
  if (!topic) return null
  const path = findTopicPath(topic.id)
  return path ? path.map((t) => t.id) : null
}

/** One hierarchical level's data: its rows, its title, and which row (if any) is selected. Navigation
 *  is intentionally absent — each surface (site route push, modal state) supplies its own handlers. */
export interface TopicLevelData {
  /** The parent topic id whose children this level lists, or `null` at the root. */
  parentId: HelpTopicId | null
  /** The level heading (parent label, or `Help` at the root). */
  title: string
  items: { id: HelpTopicId; label: string; description?: string; slug: string }[]
  selectedId: HelpTopicId | null
}

/**
 * Walk a selection `path` (topic ids, root → deepest) down {@link HELP_TOPICS}, emitting one
 * {@link TopicLevelData} per depth (each level's selection scopes the next) plus the deepest selected
 * topic — the one whose content/view fills the detail pane. A selected node with both content and
 * children contributes BOTH: its content is the `activeTopic`, and its children form the next level.
 *
 * Where the path runs out on a section that declares a {@link HelpTopic.landingChildId}, the walk
 * continues into that child instead of stopping on an unselected frontier — so both surfaces (the
 * SSR route and the modal) land that section on real content from the one declaration here. The
 * root level never auto-selects: it has no parent section to declare a landing.
 */
export function buildTopicLevels(path: HelpTopicId[]): { levels: TopicLevelData[]; activeTopic: HelpTopic | null } {
  const levels: TopicLevelData[] = []
  let siblings: HelpTopic[] = HELP_TOPICS
  let title = 'Help'
  let parentId: HelpTopicId | null = null
  /** The enclosing section's landing child, if it declared one — `undefined` at the root, which is
   *  why the root level never auto-selects. Carried alongside `siblings` rather than read off a
   *  `parent` topic: that reference would close a type circle back through `node` (TS7022). */
  let landing: HelpTopicId | undefined
  let activeTopic: HelpTopic | null = null

  for (let depth = 0; ; depth++) {
    const selId: HelpTopicId | null =
      path[depth] ?? (landing != null && siblings.some((t) => t.id === landing) ? landing : null)
    levels.push({
      parentId,
      title,
      items: siblings.map((t) => ({ id: t.id, label: t.label, description: t.description, slug: t.slug })),
      selectedId: selId,
    })
    if (selId == null) break
    const node = siblings.find((t) => t.id === selId) ?? null
    if (!node) break
    activeTopic = node
    if (node.children && node.children.length > 0) {
      siblings = node.children
      title = node.label
      parentId = node.id
      landing = node.landingChildId
      continue
    }
    break
  }

  return { levels, activeTopic }
}
