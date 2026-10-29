import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

/**
 * Two layout gaps the kit owns, pinned in the shipped CSS: a versus that follows prose stands
 * clear of it, and a records table sitting directly in a flow gets the same side gutter a band's
 * content column has. Comments are stripped so only live rules are read.
 */
const BLOCKS = readFileSync(join(__dirname, '..', 'css', 'blocks.css'), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '')

function rule(selector: string): string {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const match = new RegExp(`(?:^|\\n)${escaped}\\s*\\{([^}]*)\\}`).exec(BLOCKS)
  if (match === null) throw new Error(`no rule for ${selector}`)
  return match[1] ?? ''
}

describe('versus after prose', () => {
  it('stands 1.8rem clear of a lede it directly follows, the gap a lede takes after a block', () => {
    expect(rule('.lp-wrap > .lp-lede + .lp-versus')).toContain('margin-top: 1.8rem;')
    expect(rule('.lp-wrap > .lp-lede')).toContain('margin-top: 1.8rem;')
  })
})

describe('table directly in a flow', () => {
  it('takes the content column gutter, so it does not run to the viewport edge', () => {
    const body = rule('.lp-flow > .lp-table-scroll')
    expect(body).toContain('width: min(100% - 2.5rem, var(--lp-measure, 70rem));')
    expect(body).toContain('margin-inline: auto;')
  })

  it('keeps scrolling inside its own box rather than widening the page', () => {
    expect(rule('.lp-table-scroll')).toContain('overflow-x: auto;')
  })
})
