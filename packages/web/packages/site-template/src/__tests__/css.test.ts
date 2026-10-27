import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'

const here = dirname(fileURLToPath(import.meta.url))
const pkg = resolve(here, '../..')
const read = (p: string): string => readFileSync(p, 'utf8')
const frame = (): string => read(join(pkg, 'src/css/frame.css'))
const bridge = (): string => read(join(pkg, 'src/css/bridge.css'))
const landingCss = resolve(pkg, '../landing/src/css')
const stripComments = (css: string): string => css.replace(/\/\*[\s\S]*?\*\//g, '')

/** The body of the first rule whose selector list contains `selector` (whitespace-collapsed). */
function ruleBody(css: string, selector: string): string {
  for (const m of stripComments(css).matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    const sels = m[1].split(',').map((s) => s.replace(/\s+/g, ' ').trim())
    if (sels.includes(selector)) return m[2].replace(/\s+/g, ' ')
  }
  throw new Error(`no rule for ${selector}`)
}

describe('frame.css', () => {
  it('sets the measure and the bar gradient on :root', () => {
    const root = ruleBody(frame(), ':root')
    expect(root).toContain('--lp-measure: 70rem')
    expect(root).toContain('--lp-bar-bg: linear-gradient(var(--lp-ground) 75%, transparent)')
  })

  it('clears the bitbag dock', () => {
    expect(ruleBody(frame(), ':root')).toMatch(/--lp-dock-clear: calc\(/)
  })

  it('lays every card grid out as one column', () => {
    for (const s of ['.lp-cards', '.lp-cards--pair', '.lp-cards--trio']) {
      expect(ruleBody(frame(), s)).toContain('grid-template-columns: minmax(0, 1fr)')
    }
  })

  it('un-caps the head and lede', () => {
    for (const s of ['.lp-head', '.lp-lede']) expect(ruleBody(frame(), s)).toContain('max-width: none')
  })

  it('makes the hero a window tall with a centred stack', () => {
    const body = ruleBody(frame(), '.lp-hero-flow')
    expect(body).toContain('min-height: 100svh')
    expect(body).toContain('display: flex')
    expect(body).toContain('flex-direction: column')
    expect(body).toContain('align-items: center')
    expect(body).toContain('justify-content: center')
  })

  it('uppercases the hero meta through an overridable variable', () => {
    expect(ruleBody(frame(), '.st-hero-meta')).toContain(
      'text-transform: var(--st-hero-meta-transform, uppercase)',
    )
  })

  it('rounds the app icon', () => {
    const body = ruleBody(frame(), '.st-mark--app-icon')
    expect(body).toContain('width: min(176px, 40vw)')
    expect(body).toContain('border-radius: 22.37%')
  })

  it('uses no !important', () => {
    expect(stripComments(frame())).not.toContain('!important')
    expect(stripComments(bridge())).not.toContain('!important')
  })
})

describe('bridge.css', () => {
  it('assigns every --lp token the landing kit reads (frame.css owns the rest)', () => {
    const used = new Set<string>()
    for (const f of readdirSync(landingCss).filter((n) => n.endsWith('.css'))) {
      for (const m of read(join(landingCss, f)).matchAll(/var\((--lp-[a-z0-9-]+)/g)) used.add(m[1])
    }
    expect(used.size).toBeGreaterThan(50)
    const assigned = new Set<string>()
    for (const css of [bridge(), frame()]) {
      for (const m of stripComments(css).matchAll(/(--lp-[a-z0-9-]+)\s*:/g)) assigned.add(m[1])
    }
    expect([...used].filter((t) => !assigned.has(t))).toEqual([])
  })

  it('assigns the palette from theme roles', () => {
    const b = bridge()
    expect(b).toContain('--lp-ground: var(--color-surface)')
    expect(b).toContain('--lp-accent: var(--color-primary)')
    expect(b).toContain('--lp-ink: var(--color-on-surface)')
  })
})

describe('themes.json', () => {
  it('points at real font files', () => {
    const themes = JSON.parse(read(join(pkg, 'themes.json'))) as Record<
      string,
      { css: string; fonts: { variable: string; files: { path: string }[] }[] }
    >
    expect(themes.fishlamp.css).toBe('@agenticdevelopertoolkit/themes/styles/fishlamp.css')
    const web = resolve(pkg, '../..')
    for (const font of themes.fishlamp.fonts) {
      for (const f of font.files) expect(existsSync(join(web, f.path)), f.path).toBe(true)
    }
  })

  it('gives each weight and style one face, and fills a theme role', () => {
    const themes = JSON.parse(read(join(pkg, 'themes.json'))) as Record<
      string,
      { fonts: { role?: string | string[]; files: { weight: string; style: string }[] }[] }
    >
    for (const font of themes.fishlamp.fonts) {
      const faces = font.files.map((f) => `${f.weight}/${f.style}`)
      expect(new Set(faces).size).toBe(faces.length)
    }
    const roles = themes.fishlamp.fonts.flatMap((font) => font.role ?? [])
    // Every property fishlamp.css names 'Iosevka' in; --font-display follows --font-serif.
    expect(roles).toEqual(expect.arrayContaining(['--font-mono', '--font-sans', '--font-serif']))
  })
})
