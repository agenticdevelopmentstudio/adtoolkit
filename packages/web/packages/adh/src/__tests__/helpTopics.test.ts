import { describe, it, expect } from 'vitest'
import {
  HELP_TOPICS,
  buildTopicLevels,
  canonicalSlug,
  flattenTopics,
  hasDetail,
  isLeaf,
  topicBySlug,
  topicPathForSlug,
} from '../help/topics'

/** The deepest level the builder emitted — the frontier the reader actually looks at. */
function frontier(path: string[]) {
  const { levels, activeTopic } = buildTopicLevels(path)
  return { level: levels[levels.length - 1]!, activeTopic }
}

describe('the root topics', () => {
  it('start with the Overview, a markdown page', () => {
    const first = HELP_TOPICS[0]!
    expect(first.id).toBe('overview')
    expect(first.contentKey).toBe('overview')
    expect(isLeaf(first)).toBe(true)
  })

  it('serve Hub Features from the site route, not from markdown here', () => {
    // The document is built by the help site with content-buildr, so the topic is a leaf with a
    // view: on the site `/hub` owns it, and the modal links out to it.
    const hub = topicBySlug('hub')!
    expect(hub.view).toBe('hub')
    expect(hub.contentKey).toBeUndefined()
    expect(isLeaf(hub)).toBe(true)
    expect(hasDetail(hub)).toBe(true)
  })
})

describe('buildTopicLevels landing child', () => {
  it('auto-selects the MCP section landing so /mcp reads Overview, not a select nudge', () => {
    const { level, activeTopic } = frontier(topicPathForSlug('mcp') ?? [])
    expect(level.parentId).toBe('mcp')
    expect(level.selectedId).toBe('mcp-overview')
    expect(activeTopic?.contentKey).toBe('mcp-overview')
  })

  it('stops on a leaf: Hub Features opens no child level', () => {
    const { levels, activeTopic } = buildTopicLevels(topicPathForSlug('hub') ?? [])
    expect(levels).toHaveLength(1)
    expect(levels[0]!.selectedId).toBe('hub')
    expect(activeTopic?.id).toBe('hub')
  })

  it('does not override an explicit selection deeper in the section', () => {
    const { level, activeTopic } = frontier(topicPathForSlug('mcp/connect') ?? [])
    expect(level.selectedId).toBe('mcp-connect')
    expect(activeTopic?.id).toBe('mcp-connect')
  })

  it('never leaves the root level auto-selected', () => {
    const { levels, activeTopic } = buildTopicLevels([])
    expect(levels).toHaveLength(1)
    expect(levels[0]!.selectedId).toBeNull()
    expect(activeTopic).toBeNull()
  })

  it('names a real child of its own section wherever a landing child is declared', () => {
    // A landing child that is not actually a child is silently ignored at runtime, so the tree
    // itself is the thing under test — a typo'd id fails here rather than quietly doing nothing.
    for (const topic of flattenTopics(HELP_TOPICS)) {
      if (!topic.landingChildId) continue
      expect(topic.children?.map((c) => c.id), `${topic.id}.landingChildId`).toContain(
        topic.landingChildId,
      )
    }
  })
})

describe('canonicalSlug', () => {
  it('collapses a section landing child onto the section that serves the same page', () => {
    expect(canonicalSlug('mcp/overview')).toBe('mcp')
  })

  it('leaves the section itself, an ordinary topic, and an unknown slug alone', () => {
    expect(canonicalSlug('mcp')).toBe('mcp')
    expect(canonicalSlug('mcp/connect')).toBe('mcp/connect')
    expect(canonicalSlug('overview')).toBe('overview')
    expect(canonicalSlug('hub')).toBe('hub')
    expect(canonicalSlug('nope/nowhere')).toBe('nope/nowhere')
  })
})
