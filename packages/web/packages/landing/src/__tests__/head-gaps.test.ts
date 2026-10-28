import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

/**
 * The section head's two gaps are dials, at the kit's own values: the air under the eyebrow and
 * the air under the whole head. A host whose bands sit tighter sets the tokens rather than
 * restating `.lp-head` / `.lp-eyebrow` rules of its own, which a site's stylesheet may not name.
 */
const BLOCKS = readFileSync(join(__dirname, '..', 'css', 'blocks.css'), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '')

function rule(selector: string): string {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const match = new RegExp(`(?:^|\\n)${escaped}\\s*\\{([^}]*)\\}`).exec(BLOCKS)
  if (match === null) throw new Error(`no rule for ${selector}`)
  return match[1] ?? ''
}

describe('section head gaps', () => {
  it('reads the gap under the head from --lp-head-gap, at the kit value', () => {
    expect(rule('.lp-head')).toContain('margin-bottom: var(--lp-head-gap, 2.6rem);')
  })

  it('reads the gap under the eyebrow from --lp-eyebrow-gap, at the kit value', () => {
    expect(rule('.lp-eyebrow')).toContain('margin-bottom: var(--lp-eyebrow-gap, 1.2rem);')
  })
})
