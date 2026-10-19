// Per-topic leading glyph for the help topic rows, shared by ALL renderings of the ONE topic tree:
// the SSR help site rail ({@link HelpMasterDetail}), the Help modal on every site
// ({@link HelpWindow}), the REST API route's own root rail (hub-help's ApiHelpSurface) and the Hub
// Features route's (hub-help's HubSurface). It replaces the toolkit HMDV's neutral fallback ring
// (lucide `Circle` — an empty circle that says nothing about the topic) with a glyph that reads as
// the topic, so no help row is a meaningless ring. Keyed by the stable {@link HelpTopic.id}; any id
// not mapped here (a future topic) falls back to a document glyph, never the ring.
//
// No explicit color: each glyph inherits the row's `currentColor` and tints with the label on
// selection, exactly like a normal HMDV topic icon (and the REST API area glyphs) — so a selected
// row's icon goes gold with its label. `size={16}` matches the ring it replaces (the toolkit also
// force-sizes rail svgs to 16px).
//
// This module carries NO directive on purpose: with tsup `splitting:false` it inlines into each
// importing entry (the two 'use client' rails AND the server `help/surface` barrel), and
// `lucide-react` is `external` in every case, so it never drags a directive across the server/client
// boundary. Keep it directive-free.

import type { ReactNode } from 'react'
import { Braces, FileText, Info, LayoutGrid, Plug } from 'lucide-react'
import type { HelpTopicId } from './topics'

// Keyed by the exact HelpTopic.id (see topics.ts). Glyphs read as the topic: Overview an info
// mark, REST API the braces of a JSON API, MCP a connector plug, Hub Features a grid of
// capabilities.
const TOPIC_ICON: Record<string, ReactNode> = {
  overview: <Info size={16} aria-hidden />,
  'rest-api': <Braces size={16} aria-hidden />,
  mcp: <Plug size={16} aria-hidden />,
  hub: <LayoutGrid size={16} aria-hidden />,
}

/** The leading glyph for a help topic row, by topic id. Unmapped ids fall back to a document glyph,
 *  never the toolkit's empty fallback ring. */
export function topicIcon(id: HelpTopicId): ReactNode {
  return TOPIC_ICON[id] ?? <FileText size={16} aria-hidden />
}
