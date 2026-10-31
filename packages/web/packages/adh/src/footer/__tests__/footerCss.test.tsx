/**
 * The footer's two worlds, read off the stylesheets that make them.
 *
 * What the floating box shows is decided by CSS this package's other footer tests cannot see:
 * vitest hands a CSS import back empty, and jsdom applies no author stylesheet. Where the
 * Popover API exists the box is one button, the copyright, which opens the family footer, and
 * its plain form is hidden; where it does not (iOS before 17, Firefox before 125) an
 * `@supports` block hides the button and every dialog and shows the plain line instead. So this file parses the real sheets (stylesheetRules.ts),
 * takes from them what each world hides, and asks the REAL rendered footer what a visitor in
 * each world can see and reach.
 *
 * The model is the sheets' own selectors, so a rule that stops matching the markup changes the
 * answer here instead of going stale in silence. That is how the no-popover block came to name
 * a Sites trigger that no longer existed, while the copyright's own trigger, which it did not
 * name, stayed on screen as a button that opened nothing.
 */
import { describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'
import { SiteFooter } from '../SiteFooter'
import {
  adhStylesheet,
  bitbagStylesheet,
  canonicalValue,
  styleRules,
} from '../../__tests__/stylesheetRules'

// bitbag stands down to nothing: what he renders is his own tests' business (footerDock.test.tsx).
vi.mock('../FooterChat', () => ({ FooterChat: () => null }))

/** The dock the footer mounts him in, the one element adh styles of his. */
const DOCK_SELECTOR = '.bb-dock.adh-footer__chat'

/** A build identity, so the version the plain copyright line carries is there to be found. */
const LIVE = { version: '1.0.155', sha: 'a73e79b7c0ffee00deadbeef1234567890abcdef' }

// adh-site.css @imports the modal's own sheet ahead of its rules, so the footer's world is that
// sheet's rules followed by its own, in that order.
const site = [...styleRules(adhStylesheet('adh-landing-footer.css')), ...styleRules(adhStylesheet('adh-site.css'))]
const components = styleRules(adhStylesheet('adh-components.css'))

/** The block that swaps the copyright's trigger for its plain form where popovers are missing. */
const NO_POPOVERS = 'not selector(:popover-open)'
const switchBlock = site.filter(
  (r) => r.at.length === 1 && canonicalValue(r.at[0]!) === NO_POPOVERS,
)
/** What the block hides: every popover and every trigger for one. */
const HIDDEN_WITHOUT_POPOVERS = switchBlock
  .filter((r) => r.get('display') === 'none')
  .flatMap((r) => r.selectors)
/** What it brings back: the plain line, which is hidden everywhere else. */
const PLAIN_FORMS = switchBlock.filter((r) => r.get('display') === 'revert').flatMap((r) => r.selectors)

type World = 'popovers' | 'no popovers'

const matchesAny = (el: Element, selectors: string[]): boolean => selectors.some((s) => el.matches(s))

/** Whether `el` gets a box in `world`, as far as the popover switch decides it. */
function shown(el: Element, world: World): boolean {
  for (let n: Element | null = el; n; n = n.parentElement) {
    if (world === 'popovers') {
      // Every panel here is closed, and the UA hides a closed popover and all it holds.
      if (n.hasAttribute('popover')) return false
      if (matchesAny(n, PLAIN_FORMS)) return false
    } else if (matchesAny(n, HIDDEN_WITHOUT_POPOVERS)) return false
  }
  return true
}

const text = (el: Element): string => (el.textContent ?? '').replace(/\s+/g, ' ').trim()

/** Every control under `root` that `world` shows: `label (button)`, or `label → href`. */
function reachable(root: Element, world: World): string[] {
  return Array.from(root.querySelectorAll('a[href], button'))
    .filter((el) => shown(el, world))
    .map((el) => (el.tagName === 'A' ? `${text(el)} → ${el.getAttribute('href')}` : `${text(el)} (button)`))
}

/** The text under `root` that `world` shows. */
function visibleText(root: Element, world: World): string {
  const walker = root.ownerDocument.createTreeWalker(root, NodeFilter.SHOW_TEXT)
  let out = ''
  for (let n = walker.nextNode(); n; n = walker.nextNode()) {
    if (shown(n.parentElement!, world)) out += n.textContent
  }
  return out.replace(/\s+/g, ' ').trim()
}

function renderFooter() {
  const { container } = render(<SiteFooter live={LIVE} />)
  return {
    container,
    copyright: container.querySelector('.adh-footer__copyright')!,
  }
}

describe('the popover switch itself', () => {
  it('hides the plain forms outside its block, with an earlier and equally specific rule it reverts', () => {
    expect(HIDDEN_WITHOUT_POPOVERS.length, `no \`@supports ${NO_POPOVERS}\` hiding rule in adh-site.css`).toBeGreaterThan(0)
    expect(PLAIN_FORMS.length, 'no `display: revert` rule in that block').toBeGreaterThan(0)
    // The same selectors, so the same specificity, and earlier in the sheet: that is what
    // lets the block's `revert` win where it applies and lose everywhere else.
    const hideEverywhere = site.findIndex(
      (r) =>
        r.at.length === 0 &&
        r.get('display') === 'none' &&
        [...r.selectors].sort().join() === [...PLAIN_FORMS].sort().join(),
    )
    expect(hideEverywhere, 'the plain forms are not hidden outside the @supports block').toBeGreaterThan(-1)
    const revert = site.findIndex((r) => switchBlock.includes(r) && r.get('display') === 'revert')
    expect(revert).toBeGreaterThan(hideEverywhere)
  })

  it('names only what the footer renders', () => {
    // A selector for markup that is gone hides nothing, and says it does. The block named a
    // `.adh-footer__sites-trigger` for as long as Sites had been in the copyright menu.
    renderFooter()
    const stale = switchBlock
      .flatMap((r) => r.selectors)
      .filter((selector) => document.querySelector(selector) === null)
    expect(stale).toEqual([])
  })
})

describe('a browser without the Popover API', () => {
  it('shows no dialog, and no trigger for one', () => {
    // A trigger there is a button that opens nothing, and a dialog is a panel dumped inline.
    renderFooter()
    const popoverParts = Array.from(document.querySelectorAll('[popover], [popovertarget]'))
    expect(popoverParts.length).toBeGreaterThan(0)
    expect(popoverParts.filter((el) => shown(el, 'no popovers')).map((el) => el.outerHTML)).toEqual([])
  })

  it('still reaches the studio and this build, as a plain link and text', () => {
    // The family footer took over the studio's link and the version, so a dead trigger left
    // both with no way onto the screen at all.
    const { copyright } = renderFooter()
    expect(reachable(copyright, 'no popovers')).toEqual([
      'Agentic Development Studio → https://agenticdevelopmentstudio.com/',
    ])
    expect(visibleText(copyright, 'no popovers')).toBe(
      '© 2026 Agentic Development Studio · v1.0.155 · a73e79b7',
    )
  })
})

describe('a browser with the Popover API', () => {
  it('shows the `i` as the one button, and none of the plain copyright', () => {
    const { copyright } = renderFooter()
    expect(reachable(copyright, 'popovers')).toEqual(['i (button)'])
    expect(visibleText(copyright, 'popovers')).toBe('i')
  })

  it('shows the brand the theme editor reads, which is the first one in the footer', () => {
    // theme-editor/areas.tsx reads the brand's current styling off the first
    // `.adh-footer__brand-link`; were that the hidden plain line's, it would read nothing real.
    const { container } = renderFooter()
    expect(shown(container.querySelector('.adh-footer__brand-link')!, 'popovers')).toBe(true)
  })
})

describe('the floating box', () => {
  it('is fixed in the lower-left corner, and takes the pointer only on its box', () => {
    const footer = site.filter((r) => r.at.length === 0 && r.selectors.includes('.adh-footer.adh-footer--floating'))
    expect(footer.map((r) => r.get('position'))).toContain('fixed')
    expect(footer.some((r) => r.get('left') !== '' && r.get('bottom') !== '')).toBe(true)
    expect(footer.some((r) => r.get('right') !== '' && r.get('right') !== 'auto')).toBe(false)
    expect(footer.map((r) => r.get('pointer-events'))).toContain('none')
    const box = site.filter((r) => r.at.length === 0 && r.selectors.includes('.adh-footer--floating .adh-footer__copyright'))
    expect(box.map((r) => r.get('pointer-events'))).toContain('auto')
  })
})

describe('the preview badge', () => {
  it('sits centred across the footer, its panel centred under it', () => {
    const rules = styleRules(adhStylesheet('adh-landing-footer.css')).filter((r) => r.at.length === 0)
    const head = rules.filter((r) => r.selectors.includes('.adh-landing-footer__head'))
    expect(head.map((r) => r.get('justify-content'))).toContain('center')
    const panel = rules.filter((r) => r.selectors.includes('.adh-preview-badge .adh-header__preview-panel'))
    expect(panel.map((r) => r.get('left'))).toContain('50%')
    expect(panel.map((r) => r.get('transform'))).toContain('translateX(-50%)')
  })
})

describe('the legal dialogs', () => {
  it("keep their lists' markers against a host reset", () => {
    const lists = styleRules(adhStylesheet('adh-landing-footer.css')).filter(
      (r) => r.at.length === 0 && r.selectors.includes('.adh-modal__body--legal .adh-legal-doc ul'),
    )
    expect(lists.map((r) => r.get('list-style'))).toContain('disc')
  })
})

describe("bitbag's resting place", () => {
  it('is his own lower-right corner: the dock pins its column right', () => {
    const bitbag = styleRules(bitbagStylesheet('bitbag-dock.css'))
    const dock = bitbag.filter((r) => r.at.length === 0 && r.selectors.length === 1 && r.selectors[0] === '.bb-dock')
    expect(dock.map((r) => r.get('align-items'))).toContain('flex-end')
  })

  it("is reached through the hooks bitbag's resting rule reads, never by restating its selectors", () => {
    const bitbag = styleRules(bitbagStylesheet('bitbag-dock.css'))
    const resting = bitbag.filter((r) =>
      r.selectors.includes('.bb-dock--resting .bb-dock__avatar'),
    )
    expect(resting, 'bitbag-dock.css has no `.bb-dock--resting .bb-dock__avatar` rule').toHaveLength(1)
    // Neutral fallbacks: a host that sets nothing gets bitbag's own resting place.
    expect(resting[0]!.get('transform')).toContain('var(--bb-dock-rest-x,0px)')
    expect(resting[0]!.get('margin-bottom')).toContain('var(--bb-dock-rest-lift,0px)')

    // The footer parks him where bitbag declares: his face as far in from the right as up
    // from the bottom, by bitbag's own shift and lift.
    const dock = site.filter(
      (r) => r.at.length === 0 && r.selectors.length === 1 && r.selectors[0] === DOCK_SELECTOR,
    )
    const set = dock.flatMap((r) => r.properties.filter((p) => p.startsWith('--bb-dock-rest-')))
    expect(set).toEqual(['--bb-dock-rest-x', '--bb-dock-rest-lift'])
    expect(dock.map((r) => r.get('--bb-dock-rest-x')).join()).toBe('var(--bb-dock-parked-shift)')
    expect(dock.map((r) => r.get('--bb-dock-rest-lift')).join()).toBe('var(--bb-dock-parked-lift)')

    // adh used to restate both of bitbag's resting selectors one class stronger, to win when
    // bitbag's sheet landed later; that held only while the two copies stayed in step, and
    // nothing checked that they did. A `:not(.bb-dock--resting)` is not a restatement: it
    // keeps a rule OFF the resting dock (adh-site.css's engaged lift, which a resting dock
    // must never get) and styles nothing bitbag's resting rules style, so negations are
    // taken out before the match.
    const restated = [...site, ...components]
      .flatMap((r) => r.selectors)
      .filter((s) => s.replace(/:not\([^()]*\)/g, '').includes('bb-dock--resting'))
    expect(restated).toEqual([])
  })
})

describe('footer menus', () => {
  it("keep each menu's anchor inside its own host", () => {
    // A page can show two footers (the theme editor's specimen beside the page's own), and an
    // anchor name that two carets declare resolves to the LAST one. Scoped to the host that
    // holds both the caret and its panel, a panel can only ever see its own caret.
    const host = components.filter((r) => r.at.length === 0 && r.selectors.includes('.adh-footer__menu-host'))
    expect(host.map((r) => r.get('anchor-scope'))).toContain('all')
  })
})
