'use client'

import { useMemo } from 'react'
import { fenceCode, prettyJson } from '../lib/pretty-json'
import { MarkdownRenderer } from './MarkdownRenderer'

/** Past this many characters a pretty-printed document is shown without syntax colours:
 *  shiki on a multi-megabyte trajectory stalls the page for seconds. */
export const JSON_HIGHLIGHT_LIMIT = 512 * 1024

export interface JsonRendererProps {
  /** The JSON or JSON Lines text, as stored. */
  content: string
  /** Wrap long lines instead of scrolling sideways. */
  wrap?: boolean
}

/**
 * JSON (or JSON Lines) pretty-printed with two-space indents, in the same code-block
 * styling as a fenced ```json block in {@link MarkdownRenderer}. Text that doesn't parse
 * is shown as written, under a one-line note saying so — never silently reformatted.
 */
export function JsonRenderer({ content, wrap = false }: JsonRendererProps): React.JSX.Element {
  const pretty = useMemo(() => prettyJson(content), [content])
  const body = pretty ?? content
  if (body.length > JSON_HIGHLIGHT_LIMIT) {
    return (
      <div className={wrap ? 'adh-mv-prose adh-mv-prose--wrap' : 'adh-mv-prose'}>
        {pretty === null && <p className="adh-mv-json-note">Not valid JSON — shown as written.</p>}
        <pre className="shiki">
          <code>{body}</code>
        </pre>
      </div>
    )
  }
  const note = pretty === null ? '*Not valid JSON — shown as written.*\n\n' : ''
  return <MarkdownRenderer content={note + fenceCode(body, pretty === null ? '' : 'json')} wrap={wrap} />
}
