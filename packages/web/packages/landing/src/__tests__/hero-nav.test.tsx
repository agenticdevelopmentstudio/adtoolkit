import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'

const lens = vi.hoisted(() => ({ calls: [] as { selector: string; fromColor?: string; toColor?: string }[] }))
vi.mock('@agenticdevelopertoolkit/textlens', () => ({
  useTextLens: (_ref: unknown, options: { selector: string; fromColor?: string; toColor?: string }): void => {
    lens.calls.push(options)
  },
}))

import * as server from '../index'
import * as client from '../client'
import { HeroNav } from '../client'

const CSS_DIR = join(__dirname, '..', 'css')

afterEach(() => {
  lens.calls = []
})

describe('HeroNav', () => {
  const rows = [
    { href: '#work', label: 'Work' },
    { href: '#contact', label: 'Contact' },
  ]

  it('is a labelled nav of plain anchors, one per row, in order', () => {
    const { container } = render(<HeroNav rows={rows} label="Sections" />)
    const nav = container.querySelector('nav.lp-hero-nav')
    expect(nav?.getAttribute('aria-label')).toBe('Sections')
    const links = Array.from(container.querySelectorAll('a.lp-hero-nav__link'))
    expect(links.map((a) => [a.getAttribute('href'), a.textContent])).toEqual([
      ['#work', 'Work'],
      ['#contact', 'Contact'],
    ])
  })

  it('draws a hidden separator between rows and none at the ends', () => {
    const { container } = render(<HeroNav rows={[...rows, { href: '#faq', label: 'FAQ' }]} label="Sections" />)
    const seps = container.querySelectorAll('.lp-hero-nav__sep')
    expect(seps).toHaveLength(2)
    for (const sep of seps) expect(sep.getAttribute('aria-hidden')).toBe('true')
    const nav = container.querySelector('nav')
    expect(nav?.firstElementChild?.className).toBe('lp-hero-nav__link')
    expect(nav?.lastElementChild?.className).toBe('lp-hero-nav__link')
  })

  it('sweeps its links with the lens, from the dim ink to the bright accent', () => {
    render(<HeroNav rows={rows} label="Sections" />)
    expect(lens.calls.at(-1)).toMatchObject({
      selector: '.lp-hero-nav__link',
      fromColor: '--lp-ink-dim',
      toColor: '--lp-accent-bright',
    })
  })

  it('ships from the client barrel only', () => {
    expect(client.HeroNav).toBe(HeroNav)
    expect('HeroNav' in server).toBe(false)
  })

  it('is styled by the kit: flow.css carries its rules', () => {
    const css = readFileSync(join(CSS_DIR, 'flow.css'), 'utf8')
    for (const sel of ['.lp-hero-nav {', '.lp-hero-nav__sep {', '.lp-hero-nav__link {']) expect(css).toContain(sel)
  })

  it('drops its separators at phone width, where the row wraps', () => {
    // At phone width the row wraps, and a bar drawn between two links lands at the end of one
    // line or the start of the next — a dangling `|` with nothing on one side of it. Below
    // 640px the bars come out and a column gap spaces the links instead, as mikefullerton's
    // contact row does.
    const sheet = new CSSStyleSheet()
    sheet.replaceSync(readFileSync(join(CSS_DIR, 'flow.css'), 'utf8'))
    const phone = Array.from(sheet.cssRules).filter(
      (rule): rule is CSSMediaRule => rule instanceof CSSMediaRule && rule.media.mediaText === '(max-width: 640px)',
    )
    const rules = phone.flatMap((media) => Array.from(media.cssRules) as CSSStyleRule[])
    const rule = (selector: string) => rules.find((r) => r.selectorText === selector)?.style
    expect(rule('.lp-hero-nav__sep')?.getPropertyValue('display')).toBe('none')
    expect(rule('.lp-hero-nav')?.getPropertyValue('column-gap')).toBe('1.2rem')
  })

  it('is set in the kit mono', () => {
    const css = readFileSync(join(CSS_DIR, 'flow.css'), 'utf8')
    const rule = css.slice(css.indexOf('.lp-hero-nav {'), css.indexOf('}', css.indexOf('.lp-hero-nav {')))
    expect(rule).toContain('font-family: var(--lp-font-mono, ui-monospace, "SF Mono", monospace);')
  })
})

describe('PulseRule', () => {
  it('is an <hr> with the kit class, the caller\'s appended', () => {
    const { container, rerender } = render(<server.PulseRule />)
    expect(container.querySelector('hr')?.className).toBe('lp-pulse-rule')
    rerender(<server.PulseRule className="ad-hero-rule" />)
    expect(container.querySelector('hr')?.className).toBe('lp-pulse-rule ad-hero-rule')
  })

  it('ships from the server barrel, a server component, and the client barrel re-exports nothing of it', () => {
    expect(typeof server.PulseRule).toBe('function')
    expect('PulseRule' in client).toBe(false)
  })

  it('breathes in the accent, and rests at full strength for reduced motion', () => {
    const css = readFileSync(join(CSS_DIR, 'blocks.css'), 'utf8')
    expect(css).toContain('.lp-pulse-rule {')
    expect(css).toMatch(/@keyframes lp-pulse-rule-breathe/)
    expect(css).toMatch(/prefers-reduced-motion: reduce\)\s*\{\s*\.lp-pulse-rule\s*\{\s*animation: none;\s*opacity: 1;/)
  })
})
