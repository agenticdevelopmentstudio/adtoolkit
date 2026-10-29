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
    for (const s of ['.lp-cards', '.lp-cards.lp-cards--pair', '.lp-cards.lp-cards--trio']) {
      expect(ruleBody(frame(), s)).toContain('grid-template-columns: minmax(0, 1fr)')
    }
  })

  it('keeps cards one column against every kit grid rule, at every width', () => {
    // frame.css is imported after the kit's blocks.css, so a frame rule wins when its selector
    // is at least as specific as the kit's. The kit's `--pair`/`--trio` grids are two classes
    // (`.lp-cards.lp-cards--pair`, widened inside a media query), so a one-class frame rule
    // loses to them at 48rem and wider. Every kit selector that sets the card grid's columns
    // to more than one column needs a frame one-column rule of the same selector.
    const kit = read(join(landingCss, 'blocks.css'))
    const kitSelectors = new Set<string>()
    for (const m of stripComments(kit).matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
      const cols = /grid-template-columns:\s*([^;]+)/.exec(m[2])
      if (cols === null || cols[1].trim() === 'minmax(0, 1fr)') continue
      for (const s of m[1].split(',').map((x) => x.replace(/\s+/g, ' ').trim())) {
        if (/^\.lp-cards(\.lp-cards--\w+)?$/.test(s)) kitSelectors.add(s)
      }
    }
    expect([...kitSelectors]).toContain('.lp-cards.lp-cards--pair')
    for (const s of kitSelectors) {
      expect(ruleBody(frame(), s)).toContain('grid-template-columns: minmax(0, 1fr)')
    }
  })

  it('lays the family band two across, each card a link stretched to its row', () => {
    expect(frame()).toMatch(/@media \(min-width: 48rem\) \{\s*\.lp-cards\.st-family \{/)
    expect(ruleBody(frame(), '.lp-cards.st-family')).toContain('grid-template-columns: repeat(2, minmax(0, 1fr))')
    expect(ruleBody(frame(), '.st-family__link')).toContain('text-decoration: none')
    expect(ruleBody(frame(), '.st-family__link > .lp-card')).toContain('flex: 1')
  })

  it('un-caps the head and lede', () => {
    for (const s of ['.lp-head', '.lp-lede']) expect(ruleBody(frame(), s)).toContain('max-width: none')
  })

  it('makes the hero a window tall with a centred stack', () => {
    const body = ruleBody(frame(), '.lp-hero-flow')
    expect(body).toContain('min-height: calc(100svh')
    expect(body).toContain('display: flex')
    expect(body).toContain('flex-direction: column')
    expect(body).toContain('align-items: center')
    expect(body).toContain('justify-content: center')
  })

  it('lets a site make the hero a cut taller, so the first band starts below the window', () => {
    // The first seamed band pulls itself up by `--lp-seam`; a site whose first screen shows
    // nothing of the next band sets `--st-hero-extra: var(--lp-seam)`. The default keeps the
    // hero exactly a window tall.
    const body = ruleBody(frame(), '.lp-hero-flow')
    expect(body).toContain('min-height: calc(100svh + var(--st-hero-extra, 0px))')
    expect(body).toContain('min-height: calc(100vh + var(--st-hero-extra, 0px))')
  })

  it('lands a band jumped to from the drawer below the fixed bar, through an overridable token', () => {
    // The bar is the 32px burger chip plus its `--lp-bar-pad-y` above and below; a site whose bar
    // is another height sets `--st-band-clear`. On `.lp-band`, never `.lp-screen`, whose snap
    // area a scroll margin would shrink (landing's base.css).
    expect(ruleBody(frame(), '.lp-band')).toContain(
      'scroll-margin-top: var(--st-band-clear, calc(32px + 2 * var(--lp-bar-pad-y, 1.1rem)))',
    )
    expect(stripComments(frame())).not.toMatch(/\.lp-screen[^{]*\{[^}]*scroll-margin/)
  })

  it('lets a site set the body weight, leading and tracking, defaulting to the kit body rule', () => {
    // The kit's body rule (landing base.css) sets line-height 1.7 and no weight; a site whose
    // copy is set lighter or tighter sets `--st-body-weight` / `--st-body-leading` in its
    // theme. Same `:where()` selector as the kit's, so it keeps body's (0,0,1) and wins on
    // source order alone. (Its selector list holds a comma, so ruleBody cannot find it.)
    const m = stripComments(frame()).match(
      /:where\(html:has\(\.lp-deck, \.lp-flow\)\) body\s*\{([^}]*)\}/,
    )
    expect(m, 'no :where(html:has(.lp-deck, .lp-flow)) body rule').not.toBeNull()
    const body = m![1].replace(/\s+/g, ' ')
    expect(body).toContain('font-weight: var(--st-body-weight, 400)')
    expect(body).toContain('line-height: var(--st-body-leading, 1.7)')
    // Tracking too: the kit's body rule sets none, so the default is the browser's `normal`.
    expect(body).toContain('letter-spacing: var(--st-body-tracking, normal)')
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

  it('caps a glyph mark at the flow hero size, leaving a smaller drawn size alone', () => {
    // The default mark is content-buildr's `/glyph.svg`, which carries only a viewBox: an <img>
    // of it is as wide as the hero's wrap. A cap, not a width, so a mark that draws itself
    // smaller (`width="64"`) keeps its own size.
    const body = ruleBody(frame(), '.st-mark--glyph')
    expect(body).toContain('max-width: min(112px, 26vw, 12svh)')
    expect(body).toContain('height: auto')
    expect(body).not.toMatch(/(^|[ ;])width:/)
  })

  it("fits the hero's stack to the window's height, so its last line clears the dock", () => {
    // The dock is fixed at the window's foot; a stack sized by width alone ran under it on a
    // laptop screen (the cookbook at 1280x800). The headline keeps the kit's own clamp, bounds
    // and width term, with that term capped by the window's height.
    const kit = ruleBody(read(join(landingCss, 'flow.css')), '.lp-hero-flow h1')
    const kitSize = /font-size: clamp\(([^,]+), ([^,]+), ([^)]+)\)/.exec(kit)
    expect(kitSize).not.toBeNull()
    const [, min, fluid, max] = kitSize!
    expect(ruleBody(frame(), '.lp-hero-flow h1')).toContain(`font-size: clamp(${min}, min(${fluid}, 7svh), ${max})`)
    // The mark gives up height with it, and so does the pad above the stack.
    expect(ruleBody(frame(), '.st-mark--glyph')).toMatch(/max-width: min\([^;]*\d+svh\)/)
    expect(ruleBody(bridge(), ':root')).toContain('--lp-hero-pad-top: min(6.5rem, 13svh)')
  })

  it('keeps the hero status pill its own height beside a button', () => {
    // The actions row is a stretching flex row: the pill would grow to the button's height with
    // its words pinned to the top.
    expect(ruleBody(frame(), '.lp-hero-actions .lp-status')).toContain('align-self: center')
  })

  it('centres the app icon over the headline, with room under it', () => {
    // A block <img> in the hero's text-align:center wrap sits flush left without auto margins.
    expect(ruleBody(frame(), '.st-mark--app-icon')).toContain('margin: 0 auto 1.8rem')
  })

  it('hides .st-sr-only from sight but not from a screen reader', () => {
    const body = ruleBody(frame(), '.st-sr-only')
    expect(body).toContain('position: absolute')
    expect(body).toContain('width: 1px')
    expect(body).toContain('height: 1px')
    expect(body).toContain('overflow: hidden')
    expect(body).toContain('clip-path: inset(50%)')
    expect(body).toContain('white-space: nowrap')
    expect(body).not.toContain('display: none')
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

describe('themes.json mikefullerton', () => {
  type Theme = { css: string; fonts: { variable: string; role?: string[]; files: { path: string }[] }[] }
  const themes = (): Record<string, Theme> => JSON.parse(read(join(pkg, 'themes.json'))) as Record<string, Theme>
  const stylesDir = resolve(pkg, '../themes/src/styles')
  const sheetPath = (theme: Theme): string =>
    join(stylesDir, theme.css.replace('@agenticdevelopertoolkit/themes/styles/', ''))
  const mikefullerton = (): string => sheetPath(themes().mikefullerton)
  const fishlamp = (): string => sheetPath(themes().fishlamp)

  /** The sheet with each relative `@import "./x.css";` replaced by that file, recursively: what a
   *  bundler hands the page. */
  function withImports(path: string): string {
    return read(path).replace(/@import\s+['"](\.\/[^'"]+)['"]\s*;/g, (_, rel: string) =>
      withImports(join(dirname(path), rel)),
    )
  }

  /** Every custom property declared in a rule listing exactly `html:root`, later rules winning:
   *  the sheet's dark palette as the cascade resolves it. */
  function rootTokens(css: string): Map<string, string> {
    const tokens = new Map<string, string>()
    for (const m of stripComments(css).matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
      const sels = m[1].split(',').map((s) => s.replace(/\s+/g, ' ').trim())
      if (!sels.includes('html:root')) continue
      for (const d of m[2].matchAll(/(--[a-z0-9-]+)\s*:\s*([^;]+);/g)) tokens.set(d[1], d[2].replace(/\s+/g, ' ').trim())
    }
    return tokens
  }

  // The two roles that are the site's own; every other role is fishlamp's.
  const SITE = new Map([
    ['--color-text-dim', '#6d5f52'],
    ['--color-outline-strong', 'rgba(232, 163, 61, 0.42)'],
  ])

  it("points at the landing palette sheet, not the manifest's mikefullerton.css", () => {
    const theme = themes().mikefullerton
    expect(theme.css).toBe('@agenticdevelopertoolkit/themes/styles/mikefullerton-landing.css')
    expect(existsSync(sheetPath(theme))).toBe(true)
    const web = resolve(pkg, '../..')
    for (const font of theme.fonts) {
      for (const f of font.files) expect(existsSync(join(web, f.path)), f.path).toBe(true)
    }
    expect(theme.fonts.flatMap((font) => font.role ?? [])).toEqual(
      expect.arrayContaining(['--font-mono', '--font-sans', '--font-serif']),
    )
  })

  it('declares every role the bridge and the frame read', () => {
    const declared = new Set(rootTokens(withImports(mikefullerton())).keys())
    const wanted = new Set<string>()
    for (const css of [bridge(), frame()]) {
      for (const m of stripComments(css).matchAll(/var\((--(?:color|font)-[a-z0-9-]+)/g)) wanted.add(m[1])
    }
    expect([...wanted].filter((role) => !declared.has(role))).toEqual([])
  })

  it("is token rules only, dark under every mode: no body rule to reach a site's other routes", () => {
    const sheet = stripComments(withImports(mikefullerton()))
    const selectors = [...sheet.matchAll(/([^{}]+)\{/g)].flatMap((m) => m[1].split(',').map((s) => s.trim()))
    expect(selectors.length).toBeGreaterThan(0)
    expect(selectors.filter((s) => !s.startsWith('html:root'))).toEqual([])
    expect(selectors).toContain('html:root[data-color-mode]:not(.dark)')
  })

  it("copies no fishlamp literal: it declares only the site's own roles", () => {
    // fishlamp.com's palette is the studio's; this site is signed by it. A role restated here
    // with fishlamp's value is a fork that keeps the old literal when fishlamp's is tuned.
    const theirs = rootTokens(withImports(fishlamp()))
    const own = stripComments(read(mikefullerton()))
    const duplicated = [...own.matchAll(/(--[a-z0-9-]+)\s*:\s*([^;]+);/g)]
      .map((d) => [d[1], d[2].replace(/\s+/g, ' ').trim()] as const)
      .filter(([role, value]) => theirs.get(role) === value)
      .map(([role, value]) => `${role}: ${value}`)
    expect(duplicated).toEqual([])
  })

  it("resolves every role to fishlamp's value, except the site's two", () => {
    const theirs = rootTokens(withImports(fishlamp()))
    const ours = rootTokens(withImports(mikefullerton()))
    for (const [role, value] of SITE) expect(ours.get(role), role).toBe(value)
    const differ = [...ours]
      .filter(([role]) => !SITE.has(role))
      .filter(([role, value]) => theirs.get(role) !== value)
      .map(([role, value]) => `${role}: ${value} (fishlamp: ${theirs.get(role)})`)
    expect(differ).toEqual([])
  })
})

describe('themes.json charcoal', () => {
  type Theme = { css: string; fonts: { variable: string; role?: string[]; files: { path: string }[] }[] }
  const themes = (): Record<string, Theme> => JSON.parse(read(join(pkg, 'themes.json'))) as Record<string, Theme>
  const stylesDir = resolve(pkg, '../themes/src/styles')
  const sheet = (): string =>
    read(join(stylesDir, themes().charcoal.css.replace('@agenticdevelopertoolkit/themes/styles/', '')))

  it("points at the family's own charcoal palette and real Iosevka files", () => {
    const theme = themes().charcoal
    expect(theme.css).toBe('@agenticdevelopertoolkit/themes/styles/charcoal.css')
    const web = resolve(pkg, '../..')
    for (const font of theme.fonts) {
      for (const f of font.files) expect(existsSync(join(web, f.path)), f.path).toBe(true)
    }
    // Every property charcoal.css names 'Iosevka' in; --font-display follows --font-serif.
    expect(theme.fonts.flatMap((font) => font.role ?? [])).toEqual(
      expect.arrayContaining(['--font-mono', '--font-sans', '--font-serif']),
    )
  })

  it('declares every role the bridge and the frame read, on html:root', () => {
    const declared = new Set<string>()
    for (const m of stripComments(sheet()).matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
      const sels = m[1].split(',').map((s) => s.replace(/\s+/g, ' ').trim())
      if (!sels.includes('html:root')) continue
      for (const d of m[2].matchAll(/(--[a-z0-9-]+)\s*:/g)) declared.add(d[1])
    }
    const wanted = new Set<string>()
    for (const css of [bridge(), frame()]) {
      for (const m of stripComments(css).matchAll(/var\((--(?:color|font)-[a-z0-9-]+)/g)) wanted.add(m[1])
    }
    expect(wanted.size).toBeGreaterThan(0)
    expect([...wanted].filter((role) => !declared.has(role))).toEqual([])
  })

  it("is token rules only: no body rule to reach a site's other routes", () => {
    // An at-rule's prelude (charcoal's `@media (prefers-contrast: more)`) is not a selector.
    const selectors = [...stripComments(sheet()).replace(/@media[^{]*\{/g, '').matchAll(/([^{}]+)\{/g)]
      .flatMap((m) => m[1].split(',').map((s) => s.trim()))
      .filter((s) => s !== '')
    expect(selectors.length).toBeGreaterThan(0)
    expect(selectors.filter((s) => !s.startsWith('html:root'))).toEqual([])
  })
})
