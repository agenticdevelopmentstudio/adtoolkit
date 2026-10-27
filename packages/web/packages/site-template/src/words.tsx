import type { ReactElement } from 'react'
import type { CopyText } from './types'

/**
 * One `CopyText`, rendered: a string as text, an `{ html }` value as the markup content-buildr
 * rendered from the site's markdown. That markup is the site's own, written by its author and
 * generated at build time, so it is trusted the way the rest of the site's source is.
 */
export function Words({ text }: { text: CopyText }): ReactElement {
  return typeof text === 'string' ? <>{text}</> : <span dangerouslySetInnerHTML={{ __html: text.html }} />
}
