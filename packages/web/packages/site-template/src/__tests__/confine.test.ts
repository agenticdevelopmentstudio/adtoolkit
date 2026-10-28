import { createRequire } from 'node:module'
import postcss, { type AtRule, type Container, type PluginCreator, type Rule } from 'postcss'
import { describe, expect, it } from 'vitest'

// The plugin is CommonJS (a postcss config names it by path), so it is required, not imported.
const confine = createRequire(import.meta.url)('../../postcss/confine.cjs') as PluginCreator<void>

const P = ':where(:root:has(.fam))'
const run = (css: string): string => postcss([confine()]).process(css, { from: undefined }).css

/** Every style rule in `css`, as its selector list and the at-rules around it, outermost first. */
function rules(css: string): { at: string[]; selectors: string[] }[] {
  const out: { at: string[]; selectors: string[] }[] = []
  postcss.parse(css).walkRules((rule: Rule) => {
    const at: string[] = []
    for (let p: Container | undefined = rule.parent; p && p.type === 'atrule'; p = p.parent as Container | undefined) {
      const a = p as AtRule
      at.unshift(`@${a.name} ${a.params}`.trim())
    }
    out.push({ at, selectors: rule.selectors.map((s) => s.trim()) })
  })
  return out
}

const sels = (css: string): string[][] => rules(run(css)).map((r) => r.selectors)

describe('postcss confine', () => {
  it('leaves a sheet without the directive exactly as it was', () => {
    const css = '/* a note */\n.a { color: red }\n@media (min-width: 1px) { .b { color: blue } }\n'
    expect(run(css)).toBe(css)
  })

  it('does not take prose that mentions the directive for one', () => {
    const css = '/* add @confine .fam to confine a sheet */\n/*! see @confine .fam in the docs */\n.a { color: red }\n'
    expect(run(css)).toBe(css)
  })

  it('removes the directive and adds no @scope', () => {
    const out = run('/*! @confine .fam */\n.a { color: red }')
    expect(out).not.toContain('@confine')
    expect(out).not.toContain('@scope')
  })

  it('matches only inside a document that carries the marker, at no specificity', () => {
    // A descendant of the root, through the prefix; the root element itself, through the
    // suffix, for a selector that could match it (one compound, nothing before it).
    expect(sels('/*! @confine .fam */\n.a { color: red }')).toEqual([[`${P} .a`, `.a${P}`]])
    expect(sels('/*! @confine .fam */\nhtml, :root { color: red }')).toEqual([
      [`${P} html`, `html${P}`, `${P} :root`, `:root${P}`],
    ])
    expect(sels('/*! @confine .fam */\n* { margin: 0 }')).toEqual([[`${P} *`, `*${P}`]])
  })

  it('does not suffix a selector with a combinator, whose subject is never the root', () => {
    expect(sels('/*! @confine .fam */\n.a .b, .a>.b, .a + .b, .a~.b { color: red }')).toEqual([
      [`${P} .a .b`, `${P} .a>.b`, `${P} .a + .b`, `${P} .a~.b`],
    ])
  })

  it('puts the suffix before a pseudo-element, modern or legacy', () => {
    expect(sels('/*! @confine .fam */\n*::before, .a:hover::after, .b:before, ::selection { color: red }')).toEqual([
      [
        `${P} *::before`, `*${P}::before`,
        `${P} .a:hover::after`, `.a:hover${P}::after`,
        `${P} .b:before`, `.b${P}:before`,
        `${P} ::selection`, `${P}::selection`,
      ],
    ])
  })

  it('reads escapes, strings and parentheses as part of one compound', () => {
    const css = String.raw`/*! @confine .fam */
.sm\:block, .\31 0, .w-\[calc\(1px_\+_2px\)\], [data-x="a b"], :is(.a .b) { color: red }`
    expect(sels(css)).toEqual([
      [
        String.raw`${P} .sm\:block`, String.raw`.sm\:block${P}`,
        String.raw`${P} .\31 0`, String.raw`.\31 0${P}`,
        String.raw`${P} .w-\[calc\(1px_\+_2px\)\]`, String.raw`.w-\[calc\(1px_\+_2px\)\]${P}`,
        `${P} [data-x="a b"]`, `[data-x="a b"]${P}`,
        `${P} :is(.a .b)`, `:is(.a .b)${P}`,
      ],
    ])
  })

  it('confines inside grouping rules and keeps them where they were', () => {
    const out = rules(
      run(`/*! @confine .fam */
@layer base { .a { color: red } }
@media (min-width: 1px) { @supports (display: grid) { .b .c { color: red } } }
@container (min-width: 1px) { .d .e { color: red } }
@starting-style { .f .g { opacity: 0 } }`),
    )
    expect(out).toEqual([
      { at: ['@layer base'], selectors: [`${P} .a`, `.a${P}`] },
      { at: ['@media (min-width: 1px)', '@supports (display: grid)'], selectors: [`${P} .b .c`] },
      { at: ['@container (min-width: 1px)'], selectors: [`${P} .d .e`] },
      { at: ['@starting-style'], selectors: [`${P} .f .g`] },
    ])
  })

  it('leaves the rules that declare names global', () => {
    const css = `/*! @confine .fam */
@layer a, b;
@font-face { font-family: X; src: url(x.woff2) }
@keyframes spin { from { rotate: 0deg } to { rotate: 360deg } }
@property --x { syntax: "<length>"; inherits: false; initial-value: 0 }
.a { color: red }`
    const out = run(css)
    expect(out).toContain('@layer a, b;')
    expect(out).toContain('@font-face { font-family: X; src: url(x.woff2) }')
    expect(out).toContain('@property --x { syntax: "<length>"; inherits: false; initial-value: 0 }')
    expect(rules(out).filter((r) => r.at[0] === '@keyframes spin').map((r) => r.selectors)).toEqual([['from'], ['to']])
  })

  it('reports the marker it confined to', () => {
    const result = postcss([confine()]).process('/*! @confine .fam */\n.a { color: red }', { from: undefined })
    expect(result.css).toBeTruthy()
    expect(result.messages).toContainEqual({ type: 'confine', plugin: 'site-template-confine', marker: '.fam' })
  })

  it('refuses a second directive, a nested one, a marker that is not one class, and a sheet with @scope', () => {
    expect(() => run('/*! @confine .a */\n/*! @confine .b */\n.x { color: red }')).toThrow(/one @confine/)
    expect(() => run('@media print { /*! @confine .a */ .x { color: red } }')).toThrow(/top level/)
    expect(() => run('/*! @confine fam */\n.x { color: red }')).toThrow(/one class/)
    expect(() => run('/*! @confine .a.b */\n.x { color: red }')).toThrow(/one class/)
    expect(() => run('/*! @confine .fam */\n@scope (.card) { .x { color: red } }')).toThrow(/@scope/)
  })
})
